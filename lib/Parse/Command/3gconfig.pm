package Parse::Command::3gconfig;

=head1 NAME
Parse::Command::3gconfig;
=cut
#pragmas
use strict;
use warnings;
#modules
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Common::CSV;
use Common::Lock;
use Common::XML;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse 3gconfig UTRAN configuration snapshot from Alcatel-Lucent WNMS into csv files (CPU intensive!)";
}

sub usage_desc {
	return "%c 3gconfig %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "wnms|w=s",	"WNMS name", { required => 1 }],
	[ "country|c=s",	"Country", { required => 1 }],
	[ "delete|D",	"Delete file(s) after parsing"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
	$self->usage_error("At least one file name is required") unless @$args;
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}
	make_path($opt->{outdir}, { verbose => 1 });
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	my $lock = '.'.$opt->{wnms}.'3gconfig';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	
	for my $file (@$args) {
		my ($config,$cols,$info) = parse_snapshot($file,$opt->{country});
		warn "Warning: No data was retrieved after parsing $file. This should be investigated\n"	unless (scalar(keys %$cols) > 0);
	
		my $success = Common::CSV::to_csv($config,$cols,$info,$opt->{wnms},'3gconfig',$opt->{outdir});
		if ($success && $opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($file);
		}
		
	}
}

sub parse_snapshot {
	my ($f,$country) = @_;
	print "Parsing: $f (this takes some time)\n";
	my $zip = Archive::Zip->new();
	unless ( $zip->read($f) == AZ_OK ) {
		print "There was an error trying to read zip file $f! Is the file perhaps not a zip file?\n";
		return;
   }
	my ($fn) = $zip->memberNames();
	
	my $contents = $zip->contents($fn);
	my ($year,$mon,$day) = ($f =~/.*?(\d{4})(\d{2})(\d{2})/);
	my $date = join('-',$year,$mon,$day);
	
	my (%info,%config,%col,%cfg);
	
	$info{'IMPORTDATE'} = $date;
	$info{'NETWORK'} = $country;		#vodacom wants this...
	
	my $parser = XML::LibXML->new();
  my $doc = $parser->parse_string($contents);
	
	
	my @rnc = Common::XML::get_items_text($doc,'/snapshot/RNC/@id');
	my @btsEquip = Common::XML::get_items_text($doc,'/snapshot/BTSEquipment/@id');
	my @site = Common::XML::get_items_text($doc,'/snapshot/Site/@id');
	foreach my $beq (@btsEquip) {
		next unless defined($beq);
		print "beq : $beq\n";
		my $bData = umts_attributes($doc,'/snapshot/BTSEquipment[@id=\''.$beq.'\']');
		
		my @btscell = Common::XML::get_items_text($doc,'/snapshot/BTSEquipment[@id=\''.$beq.'\']/BTSCell/@id');
		my @antenna = Common::XML::get_items_text($doc,'/snapshot/BTSEquipment[@id=\''.$beq.'\']/AntennaAccess/@id');
		foreach my $bcell (@btscell) {
			my $bcData = umts_attributes($doc,'/snapshot/BTSEquipment[@id=\''.$beq.'\']/BTSCell[@id=\''.$bcell.'\']');
			@{$config{'BTS'}{'BTSEquipment,BTSCell='.join(',',$beq,$bcell)}}{keys %{$bData},keys %{$bcData}} = (values %{$bData},values %{$bcData});
			@{$col{'BTS'}}{keys %{$bData},keys %{$bcData}} = ();
		}
		foreach my $ant (@antenna) {
			my $antData = umts_attributes($doc,'/snapshot/BTSEquipment[@id=\''.$beq.'\']/AntennaAccess[@id=\''.$ant.'\']');
			@{$config{'Antenna'}{'BTSEquipment,AntennaAccess='.join(',',$beq,$ant)}}{keys %{$antData}} = (values %{$antData});
			@{$col{'Antenna'}}{keys %{$antData}} = ();
		}
	}
	foreach my $st (@site) {
		next unless defined($st);
		my $sData = umts_attributes($doc,'/snapshot/Site[@id=\''.$st.'\']');
		my @sectors = Common::XML::get_items_text($doc,'/snapshot/Site[@id=\''.$st.'\']/Sector/@id');
		foreach my $sct (@sectors) {
			next unless defined($sct);
			my $sctData = umts_attributes($doc,'/snapshot/Site[@id=\''.$st.'\']/Sector[@id=\''.$sct.'\']');
			my @ant = Common::XML::get_items_text($doc,'/snapshot/Site[@id=\''.$st.'\']/Sector[@id=\''.$sct.'\']/AntennaSystem/@id');
			foreach my $ant (@ant) {
				next unless defined($ant);
				my $antData = umts_attributes($doc,'/snapshot/Site[@id=\''.$st.'\']/Sector[@id=\''.$sct.'\']/AntennaSystem[@id=\''.$ant.'\']');
				@{$config{'Site'}{'Site,Sector,AntennaSystem='.join(',',$st,$sct,$ant)}}{keys %{$sData},keys %{$sctData},keys %{$antData}} = (values %{$sData},values %{$sctData},values %{$antData});
				@{$col{'Site'}}{keys %{$sData},keys %{$sctData},keys %{$antData}} = ();
			}
		}
		
	}
	
	foreach my $r (@rnc) {
		next unless defined($r);
		print "r $r\n";
		my $rData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']');
		@{$config{'RNC'}{'RncName='.$r}}{keys %{$rData}} = (values %{$rData});
		@{$col{'RNC'}}{keys %{$rData}} = ();
		my @umtsNb = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/UmtsNeighbouring/@id');
		my @nodeB = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB/@id');
		my @nbRNC = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NeighbouringRNC/@id');
		my @equip = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment/@id');
		my @gsmN = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/GSMNeighbour/@id');
		
		
		foreach my $gn (@gsmN) {
			next unless defined($gn);
			my @gsmC = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/GSMNeighbour[@id=\''.$gn.'\']/GSMCell/@id');
			foreach my $gc (@gsmC) {
				next unless defined($gc);
				my $gcData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/GSMNeighbour[@id=\''.$gn.'\']/GSMCell[@id=\''.$gc.'\']');
				#@{$gcData}{qw/CI LAC MCC MNC/} = split('\.',$gc);
				@{$gcData}{qw/CI LAC MCC MNC/} = @{$gcData}{qw/ci locationAreaCode mobileCountryCode mobileNetworkCode/};
				delete @{$gcData}{qw/cellPlanningId userSpecificInfo/};
				@{$config{'GSMCell'}{'RncName,GSMNeighbour,GSMCell='.join(',',$r,$gn,$gc)}}{keys %{$gcData}} = (values %{$gcData});
				@{$cfg{'GSMCell'}{$gc}}{keys %{$gcData}} = (values %{$gcData});
				@{$col{'GSMCell'}}{keys %{$gcData}} = ();
			}
		}
		
		foreach my $n (@nodeB) {
			next unless defined($n);
			my $nData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']');
			
			@{$config{'NodeB'}{'RncName,NodeBName='.join(',',$r,$n)}}{keys %{$nData}} = (values %{$nData});
			@{$col{'NodeB'}}{keys %{$nData}} = ();
			my @cell = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell/@id');
			foreach my $c (@cell) {
				next unless defined($c);
				next unless ($c =~ /\w+/);
				my $cData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']');
				my $rcData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']/Class3CellReconfParams[@id=\'0\']');
				my $csData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']/CellSelectionInfo[@id=\'0\']');
				@{$config{'Cell'}{'RncName,NodeBName,CellName='.join(',',$r,$n,$c)}}{keys %{$cData}, keys %{$rcData}, keys %{$csData}} = (values %{$cData}, values %{$rcData}, values %{$csData});
				@{$cfg{'Cell'}{$c}}{keys %{$cData},keys %{$rcData}, keys %{$csData}} = (values %{$cData},values %{$rcData}, values %{$csData});
				@{$col{'Cell'}}{keys %{$cData},keys %{$rcData}, keys %{$csData}} = ();
			} # need to preload all data for UA5/UA6 checks
		}
		#load remotecell data as well - for situations where cells are residing on two different WNMS's
		foreach my $umn (@umtsNb) {
			my @rcell = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/UmtsNeighbouring[@id=\''.$umn.'\']/RemoteFDDCell/@id');
			foreach my $rc (@rcell) {
				next unless defined $rc;
				next unless ($rc =~ /\w+/);
				my $rcData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/UmtsNeighbouring[@id=\''.$umn.'\']/RemoteFDDCell[@id=\''.$rc.'\']');
				@{$cfg{'Cell'}{$rc}}{keys %{$rcData}} = (values %{$rcData});
				$cfg{'Cell'}{$rc}{'cellId'} = $rcData->{'localCellId'};
			}
		}
		
		
		
		foreach my $nr (@nbRNC) {
			next unless defined($nr);
			my $nrData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NeighbouringRNC[@id=\''.$nr.'\']');
			@{$config{'NeighbouringRNC'}{'RncName,NeighbouringRNC='.join(',',$r,$nr)}}{keys %{$nrData}} = (values %{$nrData});
			@{$col{'NeighbouringRNC'}}{keys %{$nrData}} = ();
		}
		
		foreach my $eq (@equip) {
			next unless defined($eq);
			my @inode = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode/@id');
			foreach my $in (@inode) {
				next unless defined($in);
				my @em = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM/@id');
				foreach my $em (@em) {
					next unless defined($em);
					my @atm = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf/@id');
					my @lp = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/Lp/@id');
					foreach my $lp (@lp) {
						next unless defined $lp;
						my $lpData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/Lp[@id=\''.$lp.'\']');
						@{$config{'LProcessor'}{'RncName,RNCEquipment,INode,EM,Lp='.join(',',$r,$eq,$in,$em,$lp)}}{keys %{$lpData}} = (values %{$lpData});
						@{$col{'LProcessor'}}{keys %{$lpData}} = ();
					}
					foreach my $atm (@atm) {
						next unless defined($atm);
						my @vpt = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf[@id=\''.$atm.'\']/Vpt/@id');
						
						my $atmData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf[@id=\''.$atm.'\']','Atm');
						my $caData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf[@id=\''.$atm.'\']/CA','CA');
						@{$config{'AtmIf'}{'RncName,RNCEquipment,INode,EM,AtmIf='.join(',',$r,$eq,$in,$em,$atm)}}{keys %{$atmData},keys %{$caData}} = (values %{$atmData},values %{$caData});
						@{$col{'AtmIf'}}{keys %{$atmData},keys %{$caData}} = ();
						#print Dumper($caData);
						for (qw/Cbr NrtVbr RtVbr Ubr/) {
							my $data = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf[@id=\''.$atm.'\']/CA/Cbr[@id=\'0\']',$_);
							@{$config{'AtmIf'}{'RncName,RNCEquipment,INode,EM,AtmIf='.join(',',$r,$eq,$in,$em,$atm)}}{keys %{$data}} = (values %{$data});
							@{$col{'AtmIf'}}{keys %{$data}} = ();
						}
						#@{$config{'AtmIf'}{'RncName,RNCEquipment,INode,EM,AtmIf='.join(',',$r,$eq,$in,$em,$atm)}}{keys %{$gnData}} = (values %{$gnData});
						foreach my $vp (@vpt) {
							next unless defined($vp);
							#print "$eq : $in : $em : $atm : $vp (@vpt)\n";
							my $vData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf[@id=\''.$atm.'\']/Vpt[@id=\''.$vp.'\']/Vpd');
							my $tmData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/RNCEquipment[@id=\''.$eq.'\']/INode[@id=\''.$in.'\']/EM[@id=\''.$em.'\']/AtmIf[@id=\''.$atm.'\']/Vpt[@id=\''.$vp.'\']/Vpd/Tm');
							@{$config{'AtmIf_Vpt'}{'RncName,RNCEquipment,INode,EM,AtmIf,Vpt='.join(',',$r,$eq,$in,$em,$atm,$vp)}}{keys %{$vData},keys %{$tmData}} = (values %{$vData}, values %{$tmData});
							@{$col{'AtmIf_Vpt'}}{keys %{$vData},keys %{$tmData}} = ();
							
						}
						
					}
				}
			}
		}
	}
	
	foreach my $r (@rnc) {
		my @nodeB = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB/@id');
		foreach my $n (@nodeB) {
			my @cell = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell/@id');	
			foreach my $c (@cell) {
				next unless defined($c);
				next unless ($c =~ /\w+/);
				my $cData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']');
				my @umtsN = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']/UMTSFddNeighbouringCell/@id');
				
				foreach my $un (@umtsN) {
					next unless defined($un);
					next unless ($un =~ /\w+/);
					my $unData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']/UMTSFddNeighbouringCell[@id=\''.$un.'\']');
					my $ncell;
					if (exists $cfg{'Cell'}{$un}) {
						#print "$un exists in cell \n";
						my ($lac,$ci) = @{$cfg{'Cell'}{$c}}{qw/locationAreaCode cellId/};
						my ($tlac,$tci) = @{$cfg{'Cell'}{$un}}{qw/locationAreaCode cellId/};
						$ncell = join('.',$tlac,$tci);
						#UA6 data
						@{$unData}{qw/NeighbourCellName tgtCI tgtLAC cellId locationAreaCode primaryScramblingCode ulFrequencyNumber dlFrequencyNumber routingAreaCode/} = ($un,$tci,$tlac,$ci,$lac,@{$cfg{'Cell'}{$un}}{qw/primaryScramblingCode ulFrequencyNumber dlFrequencyNumber routingAreaCode/});
					}
					else {
						print "$un does not exist in cell \n";
						$ncell = $un;
						@{$unData}{qw/NeighbourCellName tgtCI tgtLAC cellId locationAreaCode/} = (@{$unData}{qw/relatedFDDCell localCellId locationAreaCode/},@{$cData}{qw/cellId locationAreaCode/});
					}
					delete @{$unData}{qw/relatedFDDCell localCellId/};
					@{$config{'UMTSNeighbourCells'}{'RncName,NodeBName,CellName,NeighbourCell='.join(',',$r,$n,$c,$ncell)}}{keys %{$unData}} = (values %{$unData});
					@{$col{'UMTSNeighbourCells'}}{keys %{$unData}} = ();
				}
				
				my @gsmN = Common::XML::get_items_text($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']/GsmNeighbouringCell/@id');
				foreach my $gn (@gsmN) {
					next unless defined($gn);
					next unless ($gn =~ /\w+/);
					my $gnData = umts_attributes($doc,'/snapshot/RNC[@id=\''.$r.'\']/NodeB[@id=\''.$n.'\']/FDDCell[@id=\''.$c.'\']/GsmNeighbouringCell[@id=\''.$gn.'\']');
					my $gid = 'RncName,NodeBName,CellName,NeighbourCell='.join(',',$r,$n,$c,$gn);
					my $ncell;
					if ($gn =~ /\d+?\d+?\d+?\d+/) {
						#UA5 data
						$ncell = $gn;
						@{$gnData}{qw/tgtCI tgtLAC tgtMCC tgtMNC cellId locationAreaCode/} = (split('\.',$gn),@{$cData}{qw/cellId locationAreaCode/});
					}
					else {
						#UA6 data
						my ($lac,$ci) = @{$cfg{'Cell'}{$c}}{qw/locationAreaCode cellId/};
						my ($tlac,$tci,$tmcc,$tmnc) = @{$cfg{'GSMCell'}{$gn}}{qw/locationAreaCode ci mobileCountryCode mobileNetworkCode/};
						@{$gnData}{qw/tgtCI tgtLAC tgtMCC tgtMNC cellId locationAreaCode/} = ($tci,$tlac,$tmcc,$tmnc,$ci,$lac);
						$ncell = join('.',$tci,$tlac,$tmcc,$tmnc);
					}
					@{$config{'GSMNeighbourCells'}{'RncName,NodeBName,CellName,NeighbourCell='.join(',',$r,$n,$c,$ncell)}}{keys %{$gnData}} = (values %{$gnData});
					@{$col{'GSMNeighbourCells'}}{keys %{$gnData}} = ();
				}
			}
		}
		
		
	}
	
	return(\%config,\%col,\%info);
}

sub umts_attributes {
	my ($in,$xpath,$pre) = @_;
	$pre = defined($pre) ? $pre.'_' : '';
	(my $key = $xpath) =~ s/\[.*?\]//g;
	
	my %d;
	#my @tags = exists($tags{$key}) ? @{$tags{$key}} : get_node_text($in,$xpath.'/attributes/*');
	my @tags = Common::XML::get_node_text($in,$xpath.'/attributes/*');
	foreach my $t (@tags) {
		next unless defined($t);
		my $val = Common::XML::get_value($in,$xpath.'/attributes/'.$t);
		if (ref($val)) {
			foreach my $k (keys %{$val}) {
				if ($val->{$k} > 1) {
					my @val = Common::XML::get_items_text($in,$xpath.'/attributes/'.$t.'/'.$k);
					%d = (%d, map { $pre.$t.'_'.$_ => $val[$_] } (0..$#val) );
				}
				else {
					$d{$pre.$t} = get_value($in,$xpath.'/attributes/'.$t.'/'.$k);
				}
			}
		}
		else {
			
			$d{$pre.$t} = $val if defined($val);
			
		}
	}
	#$tags{$key} = [@tags]; #cache
	
	return(\%d);
}

1;
