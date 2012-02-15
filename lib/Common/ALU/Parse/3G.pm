package Common::ALU::Parse::3G;

=head1 NAME
Common::ALU::Parse::3G;
=cut

#pragmas
use strict;
use warnings;
#modules
use Common::Date;
use Common::File;
use File::Path qw(make_path);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use XML::Bare;

sub make_counter_mapping {
	my $table_xml = shift;
	my $bare = new XML::Bare( file => $table_xml );
  	my $xml = $bare->parse();
  	my %table_map;
  	my %counter_map;
  	
  	foreach my $table (@{$xml->{tables}->{table}}) {
  		next unless exists $table->{loadedfromcsv} && $table->{loadedfromcsv}->{value} eq 'yes';
  		my ($name,$gran,$index) = map($_->{value} , map($table->{$_} , qw/name granularity idx/) );
   
  		my @cols = map($_->{value} , map($_->{name},@{$table->{field}}) );
  		@{$counter_map{$gran}{$index}}{@cols} = @cols;
  		@{$table_map{$gran}{$index}}{@cols} = map($name,@cols);
		
		#get the alias, if it exists
		foreach my $field (@{$table->{field}}) {
			next unless exists $field->{'table-alias'};
			my $original = $field->{name}->{value};
			my $alias = $field->{'table-alias'}->{value};
			$counter_map{$gran}{$index}{$original} = $alias;
		}  		
  	}
  	
  	return (\%table_map,\%counter_map); 	
}

sub iterate {
	my $wref = shift;
	return $wref if ref $wref eq 'HASH';
	return @{$wref} if ref $wref eq 'ARRAY';
}

sub parse_3GPM {
	my ($f,$templatedir,$pmtype) = @_;
	print "Parsing: $f\n";
	my %info = ();
	my %pm = ();
	my %counters = ();
	#my $splitter = $^O =~ /win/i ? quotemeta('\\') : '/'; 
	my $tmp_dir = '../tmp/';
	make_path($tmp_dir, { verbose => 1 }) unless -e $tmp_dir;
	
	my @file = Common::File::split_path($f);
	my $outfile = $file[$#file].'.xml';
	
	gunzip $f => $tmp_dir.$outfile unless -e $outfile;
	die "Parsing cannot continue because the temporary file $tmp_dir.$outfile could not be created. Please complain!\n" unless -e $tmp_dir.$outfile;
	my $bare = new XML::Bare( file => $tmp_dir.$outfile );
	my $xml = $bare->parse();
	
	my $version = $xml->{mdc}->{md}->{neid}->{nesw}->{value};
	my $rnc = $xml->{mdc}->{md}->{neid}->{neun}->{value};
	$info{NAME} = $rnc;
	
	print "3G PM version: ",$version,"\n";
	#create the mapping of counter name to mysql column name - necessary because MySQL has a limit on the length of the column name and some VS counter names break the limit
  	my $table_file = $templatedir.'/table.'.$pmtype.'.'.$version.'.xml';
  	unless ((-f $table_file) && (-s $table_file)) {
		print "The file $f with version $version cannot be decoded because no table file could be found (looking for $table_file) !\n";
		return 0;
	}
  	my ($table_map,$counter_map) = make_counter_mapping($table_file);
	
	foreach my $mi( iterate($xml->{mdc}->{md}->{mi}) )  {
		my @keys = keys %{$mi};
		my $gran = $mi->{gp}->{value};
		next if $gran == 900;
		my ($sdate,$stime,$edate,$etime) = Common::Date::make_date_time($mi->{mts}->{value},$gran);
		@info{qw/STARTDATE STARTTIME ENDDATE ENDTIME NETWORK SDATETIME GRANULARITY/} = ($sdate,$stime,$edate,$etime,'ZA',$sdate.' '.$stime,$gran);
		my @counters = map($_->{value},@{$mi->{mt}});
		
		foreach my $mv ( iterate($mi->{mv}) ) {
			my $moid = $mv->{moid}->{value};
			my (@idx) = split(/=|,/,$moid);
			my ($idx,$val) = (join(',',map($idx[$_],grep {!($_%2)} (0..$#idx))),join(',',map($idx[$_],grep {($_%2)} (0..$#idx))));
			my @values = map($_->{value},@{$mv->{r}});
			
			foreach my $counter (@counters) {
				my $value = shift @values;
				if (exists $counter_map->{$gran}->{$idx}->{$counter}) {
					
					my $table = $table_map->{$gran}->{$idx}->{$counter};
					my $mapped_name = $counter_map->{$gran}->{$idx}->{$counter};
					 
					$pm{$table}{$idx.'='.$val}{$mapped_name} = $value;
					$counters{$table}{$mapped_name} = 1;
				}
				else {
					#counter does not exist in mapping file. mapping file needs to be updated.
				}
			}
		}
	}
	unlink $tmp_dir.$outfile;	
	return(\%pm,\%counters,\%info);
}

#parse call traces - can be used to parse CTN,CTG
sub parse_3GCT {
	my ($f,$table) = @_;
	print "Parsing: $f\n";
	my $parser = XML::LibXML->new();
	my $doc = undef;
	my %info = ();
	my %trace = ();
	my %col = ();
	if ($f =~ /gz$/) {
		my @gz = ();
		my $gz = gzopen($f, "rb") or die "Cannot open $f: $!\n";
		while ($gz->gzreadline($_) > 0) {
			chomp;
			push(@gz,$_);
		}
		$gz->gzclose();
		my $contents = join('',@gz);
		$doc = $parser->parse_string($contents);
	}
	else {
		$doc = $parser->parse_file($f);
	}
	
	my $sender;
	
	for my $traceCollection ($doc->childNodes) {
		my %attribs = map {$_->nodeName => $_->to_literal } $traceCollection->attributes();
		next unless exists $attribs{'collectionBeginTime'};
		my ($syear,$smon,$sday,$shr,$smin,$ssec,undef) = unpack('a4a2a2a2a2a2a*',$attribs{'collectionBeginTime'});
		my $collectTime = join('-',$syear,$smon,$sday).' '.join(':',$shr,$smin,$ssec);
		$syear -= 1900;	#get year into format required by localtime
		$smon--;				#got month into format required by localtime
		for my $traceRec ($traceCollection->childNodes) {
			($sender) = ($traceRec->to_literal =~ /ManagedElement=(.*)$/) if $traceRec->nodeName eq 'sender';
			@info{qw/SENDER COLLECTIONBEGINTIME/} = ($sender,$collectTime);
			next unless $traceRec->nodeName eq 'traceRecSession';
			my %tattribs = map {$_->nodeName => $_->to_literal } $traceRec->attributes();
			my ($year,$mon,$day,$hr,$min,$sec,undef) = unpack('a4a2a2a2a2a2a*',$tattribs{'stime'});	
			my $callTime = join('-',$year,$mon,$day).' '.join(':',$hr,$min,$sec);
		
			for my $evt ($traceRec->childNodes) {
				next unless $evt->nodeName eq 'evt';
				my %ie;
				my %eattribs = map {$_->nodeName => $_->to_literal } $evt->attributes();
				my ($csec,$cmin,$chour,$cday,$cmon,$cyear) =  map(sprintf("%02d",$_),localtime(timelocal_nocheck($ssec,$smin,$shr,$sday,$smon,$syear) + $eattribs{'changeTime'}));
				$cyear += 1900;
				$cmon++;
				my $evtTime = join('-',$cyear,$cmon,$cday).' '.join(':',$chour,$cmin,$csec);
				IEwalk($evt,\%ie);
				$ie{'callStartTime'} = $callTime;
				if (exists $ie{'detectedcell_psc'}) {		#UA05 to UA06 work-around
					$ie{'detectedcell'} = $ie{'detectedcell_psc'};
					delete $ie{'detectedcell_psc'};
				}
				@{$trace{$table}{'Name,callIdentifier,event,eventTime,traceIdentifier='.join(',',$sender,$tattribs{'traceRecSessionRef'},$eattribs{'name'},$evtTime,$tattribs{'traceSessionRef'})}}{keys %ie} = (values %ie);
				@{$col{$table}}{keys %ie} = (values %ie);
			}	
		}
	}
	return(\%trace,\%col,\%info);
}

#recursive sub to walk through and gather IE and IEGroup elements of a CTN trace
sub IEwalk {
	my ($eNode,$dref,$prefix) =@_;
	$prefix = '' if not defined $prefix;
	return undef if not defined $eNode;
	
	for my $iNode ($eNode->childNodes) {
		if ($iNode->nodeName eq 'IE') {
			my $iname = $iNode->attributes()->getNamedItem('name')->to_literal;
			my $iename = $prefix ne '' ? join('_',$prefix,$iname) : $iname;
			$dref->{lc($iename)} = decode($iename,$iNode->to_literal);
		}
		if ($iNode->nodeName eq 'IEGroup') {
			my $iegname = $iNode->attributes()->getNamedItem('name')->to_literal;
			IEwalk($iNode,$dref,$prefix ne '' ? join('_',$prefix,$iegname) : $iegname);
		}
		if ($iNode->nodeName eq 'object') {
			my $objname = $iNode->attributes()->getNamedItem('type')->to_literal;
			my $id = $iNode->attributes()->getNamedItem('id')->to_literal;
			my $newprefix = $prefix ne '' ? join('_',$prefix,$objname) : $objname;
			$dref->{lc($newprefix.'id')} = $id;
			IEwalk($iNode,$dref,$newprefix);
		}
	}
}

#decode scrambling code, etc into something that can be looked up in the UTRAN snapshot
sub decode {
	my ($name,$val) = @_;
	my @change = qw/primaryCell initialAccess_initAccessCell newPrimaryCell prePrimaryCell targetCell/;
	my @bsic = qw/targetcell_gsmcellinfo_cellid/;
	if (grep{/^$name$/i} @change) {
		$val = $val % 65536	
	}
	if (grep{/^$name$/i} @bsic) {
		my $bcc = $val & 15;
		my $ncc = ($val-$bcc)>>16;
		$val = $ncc*8 + $bcc;
	}
	return $val;
}


1;
