package Report::Command::matrix;

=head1 NAME
Report::Command::matrix;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::MySQL;
use Common::MakeIt;
use Report -command;

my %citemp;
use constant ADJ_CERTAINTY_ONLY => 0;	# 1 = enabled;

sub abstract {
	return "calculate 2G interference matrix";
}

sub usage_desc {
	return "%c matrix %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "minfo=s",	"minimum first order sample share", { hidden => 1, default => 20 }],
	[ "minso=s",	"minimum second order sample share", { hidden => 1, default => 20 }],
	[ "numdays|n=s","limit calculation numdays data only", { hidden => 1, default => 1 }],
	[ "table|t=s","table name to store results in", { hidden => 1, default => 'T31_MATRIX_D' }],
	[ "patch","patch BCCH-BCCH measurement gaps"],
	[ "debug",	"debug output"],
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
		
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my %bh;
	my @required = qw(Cell T31_CIN_CELL_D);
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	my @tables = @{$dbh->selectcol_arrayref("show tables")};
	for (@required) {
		die "Cannot calculate the interference matrix because the required table $_ does not exist! \n" unless grep {/^$_/} @tables;
	}
	print "Retrieving BCCH,BSIC configuration data\n";
	my ($bcchref,$bsicref) = get_bcchbsic_config($dbh);
	print "Retrieving Adjacency configuration data\n";
	my $adjref = get_adj_config($dbh);
	my @dates = get_dates($dbh);
	print "Found usable data for the following days : @dates\n";
	my ($Passes,$count) = (1,0); # should be 2 or 3!!!
	#my ($processed,$resolved) = (0,0);
	
	foreach my $qdate (@dates) {	
		last if ($count == $opt->{numdays});
		
		print "Querying for $qdate ..\n";
		$count++;
		# initialise data
		#@source = ();
		my %nw = ();
		#$processed = 0;
		my ($sourceref,$processed) = get_interference($dbh,$qdate,$bcchref);
		#$processed
		# start resolving for this day
		my $resolved = 0;
		for (@$sourceref) {
			my @row = split (',',$_);
			my $ci1 = get_best_bcch_bsic_candidate(@row[0..2],$qdate);
			if ($ci1 !~ /^u/i) {	# no luck - try recursion into immediate neighoburs
				print "SCI: $row[0]   NBRCI: $ci1   BCCH/BSIC: $row[1];$row[2]\n" if ($opt->{debug});
				$nw{$row[0]}{"$row[1];$row[2]"} = [ $ci1, "Adjacency" ];	# certainty 100%
				$resolved++;
			}
		}
		print "\tResolved $resolved out of $processed\n";
	
		print "Second Order C/I...\n";
		for my $pass (1..$Passes) {
			$processed = 0;
			$resolved = 0;
			print "Pass $pass...\n";
			for (@$sourceref) {
				my @row = split (',',$_);
				unless (exists $nw{$row[0]}->{"$row[1];$row[2]"}) {
					$processed++;
					for my $nbrbb (keys %{$nw{$row[0]}}) { # my neighbours - can't use each - fiddling with nw in the loop
						my $nbrci = $nw{$row[0]}->{$nbrbb}->[0];
						if (defined (my $ci2ref = $nw{$nbrci}->{"$row[1];$row[2]"})) {
							my $ci2 = $ci2ref->[0];
							next if ($ci2 eq $row[0]);	# avoid circular references
							print "NBR: $nbrci had it...\n" if ($opt->{debug});
							$nw{$row[0]}{"$row[1];$row[2]"} = [ $ci2, ($pass+1)."-Order/".(scalar keys (%{$bsicref->{"$row[1];$row[2]"}->{$qdate}})) ];	# certainty 80%
							$resolved++;
							last;
						}
					}
				}
			}
			print "\tResolved $resolved out of $processed\n";
		}
		
		# now pop everything resolved and unresolved into the ci matrix
		%citemp = ();
		my $tot_discarded = 0;
		for (@$sourceref) {
			my @row = split (',',$_);
			my $ci2 = "-1~BCCH$row[1]"."BSIC$row[2]";
			my $certainty = 0;
			if (exists $nw{$row[0]}->{"$row[1];$row[2]"}) {
				$ci2 = $nw{$row[0]}->{"$row[1];$row[2]"}->[0];
				$certainty = $nw{$row[0]}->{"$row[1];$row[2]"}->[1];
			}
			else {
				$certainty = (scalar keys (%{$bsicref->{"$row[1];$row[2]"}->{$qdate}}))." Possbl"
			}
			#$citemp{$row[0]}{$ci2}[0] += $row[3];
			# special condition : if BSIC = 0 and certainty is low - double check...
			my $discard = 0;
			if (($row[2] == 0) && ($row[1] < 30) && (($certainty =~ /Possbl/) || ($certainty =~ /[2345]\-Order/)) ){
				# if there is a similar TCH within second order, discard the measurement
				for my $foci (keys %{$adjref->{$row[0]}}) {
					for my $soci (keys %{$adjref->{$foci}}) {	# rely on back-reference to avoid checking twice
						my ($testbcch, $testca) = @{$bcchref->{$soci}->{$qdate}}[0,1];
						next if ((!defined $testca) || (!defined $testbcch));
						$testca =~ s/[\{\} ]//g;
						next if ($testca !~ /\d/);
						my %ca = map { $_ => 1 } split (',', $testca);
						delete $ca{$testbcch} if (exists $ca{$testbcch});
						if (exists $ca{$row[1]}) {
							$discard++;
							last;
						}
					}	
					last if ($discard);
				}	
			}
			
			if (!$discard) {
				$citemp{$row[0]}{$ci2}[0] = $row[3];
				$citemp{$row[0]}{$ci2}[1] = $certainty;
			}
			$tot_discarded += $discard;
		}

		print "Discarded $tot_discarded dodgy measurements\n";
		
		# plug the bcch-bcch gaps
		patch($qdate,$bcchref,$opt) if ($opt->{patch});
		#pop citemp into db
		
		my $Patch = $opt->{patch} ? 1 : 0;
		# aggregate days ... also pop into db
		for my $ci1 (keys %citemp) {
			my ($la,$c) = split('~',$ci1);
			my %e = ();
			while(my ($ci2, $vref) = each(%{$citemp{$ci1}})) {
				my ($tla,$tc) = split('~',$ci2);
				my $val = $vref->[0];
				my $cer = $vref->[1];
				
				#$days{$ci1}{$ci2}{$qdate} = 1;
					
				@e{qw/LAC CI PATCHED LAC_TGT CI_TGT IMPORTDATE CERTAINTY IFPROB/} = ($la,$c,$Patch,$tla,$tc,$qdate,$cer,$val);
				my $sql = 'replace into '.$opt->{table}.' ('.join(',',map('`'.$_.'`',keys %e)).') values ('.join(',',map('\''.$_.'\'',values %e)).')';
				$dbh->do($sql) || die ($dbh->errstr);
				#print "$sql \n";
					
				
			}
		}
	}
}

sub get_interference {
	my ($dbh,$date,$bcchref) = @_;
	my $processed = 0;
	my @source;
	my $sth = $dbh->prepare("select concat(LAC,'~',CI), BCCH, BSIC, sum(TOTAL), DATE(SDATE) from T31_CIN_CELL_D where DATE(SDATE) = ? group by LAC,CI,BCCH,BSIC;");
	$sth->execute($date);
	while ( my @row = $sth->fetchrow_array ) {
		# loevenstein problem mod : ignore own bcch scanned by badly placed dummy neighbour
		# $bcch{$row[0]}{$row[3]} = [ $row[1], $row[4] ];
		if ((exists ($bcchref->{$row[0]}{$row[4]})) && ($bcchref->{$row[0]}{$row[4]}->[0] eq $row[1])) {
			#print "~" if (DEBUG);
		}
		else {
			$row[3] = int($row[3]);
			push (@source, join (',', @row[0..3]));
		}
		$processed++;
	}
	return \@source;
}

sub get_dates {
	my $dbh = shift;
	my $sth = $dbh->prepare("select distinct DATE(SDATE) from T31_CIN_CELL_D");
	my %days;	
	$sth->execute;
	while (my @row = $sth->fetchrow_array ) {
		$days{$row[0]} = 1;
	}
	my @dates = reverse sort keys %days;
	return @dates;
}

sub patch {
	my ($date,$bcchref,$opt) = @_;
	print "Patching BCCH-BCCH measurement gaps\n";
	my $patched = 0;
	my $unpatched = 0;
	
	my %patchrms = ();

	# plug all gaps
	for my $ci1 (keys %citemp) {
		my $socells = 0;
		my $focells = 0;
		my %soci = ();
		next if (!exists $bcchref->{$ci1}->{$date});
		my $bcch = $bcchref->{$ci1}->{$date}->[0];
		next unless defined $bcch;
		#discover max number
		my $maxfoval = 0;
		if (!(ADJ_CERTAINTY_ONLY)) {
			for my $foci (keys %{$citemp{$ci1}}) {
				my $ci1focival = $citemp{$ci1}->{$foci}->[0];
				$maxfoval = $ci1focival if ($ci1focival > $maxfoval);
			}
		}
		my $minfoval = ($opt->{minfo}*$maxfoval)/100;
		
		# construct a second-order list, only using ADJ certainty...
		for my $foci (keys %{$citemp{$ci1}}) {
			my $ci1focival = $citemp{$ci1}->{$foci}->[0];
			if (ADJ_CERTAINTY_ONLY) {
				next if ($citemp{$ci1}->{$foci}->[1] !~ /adj/i);	# only evaluate 100% certainty
			}
			else {
				next if $ci1focival < $minfoval;
			}
			
			$focells++;

			my $maxsoval = 0;
			if (!(ADJ_CERTAINTY_ONLY)) {
				#discover max number
				for my $soci (keys %{$citemp{$foci}}) {
					my $ci1socival = $citemp{$foci}->{$soci}->[0];
					$maxsoval = $ci1socival if ($ci1socival > $maxsoval);
				}
			}
			my $minsoval = ($opt->{minso}*$maxsoval)/100;

			for my $soci (keys %{$citemp{$foci}}) {
				next if (!$soci);	#unexplained issue... needs more research!
				if ( (!defined $citemp{$foci}->{$soci}->[1]) || (!defined $citemp{$foci}->{$soci}->[0])) {
					die "Funny at: CI: $ci1   FOCI: $foci   SOCI: $soci  Pen: ".$citemp{$foci}->{$soci}->[0]."\n";
				}
				
				my $ci1socival = $citemp{$foci}->{$soci}->[0];
			
				if (ADJ_CERTAINTY_ONLY) {
					next if ($citemp{$foci}->{$soci}->[1] !~ /adj/i);	# only evaluate 100% certainty
				}
				else {
					next if $ci1socival < $minsoval;
				}
				
				next if ($soci eq $ci1);	# no circular references
				#next if (exists $citemp{$ci1}->{$soci});	# only look at true second order neighoburs
				$soci{$soci} += ($ci1focival + $ci1socival);
				$socells++;
			}
		}
		# now find same BCCH soci cells and find matches...
		# sort the list of second order ci in ascending penalty order
		my @soci = ();
		for (sort {$soci{$a} <=> $soci{$b}} keys %soci) {
			my $sobcch = $bcchref->{$_}->{$date}->[0];
			
			if ((defined $sobcch) && ( (exists $citemp{$ci1}->{$_}) || ($bcch == $sobcch) )) {
				push (@soci, $_);
			}
		}
		
		my %potentials = ();
		for my $i (0..$#soci) {
			my $sobcch = $bcchref->{$soci[$i]}->{$date}->[0];
			if ((defined $sobcch) && ($bcch == $sobcch)) {
				$potentials{$soci[$i]} = $i;
			}
		}
		
		if ($opt->{debug}) {
			print "Source CI: $ci1 BCCH: $bcch\nSorted List of Interferers: ";
			for (sort {$citemp{$ci1}->{$a}->[0] <=> $citemp{$ci1}->{$b}->[0]} keys %{$citemp{$ci1}} ) {
				print "$_,";
			}
			print "\nPotential Inclusions (FO: $focells, SO: $socells): ".join(',',keys %potentials)."\n";
		}
		# look at each potential candidate and try to fit it in...
		for my $potci (keys %potentials) {
			my $prevci = 0;
			my $nextci = 0;
			my $val = 0;
			
			$prevci = $soci[$potentials{$potci} - 1] if ($potentials{$potci} > 0);
			$nextci = $soci[$potentials{$potci} + 1] if ($potentials{$potci} < $#soci);
			
			# case 1: both exist in the so list
			if ($prevci && $nextci) {
				if ( (exists $citemp{$ci1}->{$prevci}) && (exists $citemp{$ci1}->{$nextci})) {
					$val = int(($citemp{$ci1}->{$prevci}->[0] + $citemp{$ci1}->{$nextci}->[0]) / 2);
				}
				elsif (exists $citemp{$ci1}->{$prevci}) {
					$val = int($citemp{$ci1}->{$prevci}->[0] + 1);
				}
				elsif (exists $citemp{$ci1}->{$nextci}) {
					$val = int($citemp{$ci1}->{$nextci}->[0] - 1);
				}
			}
			elsif ($prevci && exists ($citemp{$ci1}->{$prevci})) {
				my $lastci = (reverse sort( {$citemp{$ci1}->{$a}->[0] <=> $citemp{$ci1}->{$b}->[0]} keys %{$citemp{$ci1}} ))[0];
				$val = int(($citemp{$ci1}->{$prevci}->[0] + $citemp{$ci1}->{$lastci}->[0]) / 2) if ($lastci);
			}
			elsif ($nextci && exists ($citemp{$ci1}->{$nextci})) {
				my $firstci = (sort( {$citemp{$ci1}->{$a}->[0] <=> $citemp{$ci1}->{$b}->[0]} keys %{$citemp{$ci1}} ))[0];
				$val = int(($citemp{$ci1}->{$nextci}->[0] + $citemp{$ci1}->{$firstci}->[0]) / 2) if ($firstci);
			}

			if ($val) {			
				$patchrms{$ci1}{$potci} = [$val, 'Patched'];
				print "Patched $potci with placed between $prevci and $nextci into matrix with weight of $val\n" if ($opt->{debug});
				$patched++;
			}
			else {
				$unpatched++;
			}
		}
				
		#$processed++;
		#last if ((DEBUG) && ($processed == 25));
		
	}

	for my $ci1 (keys %patchrms) {
		for my $ci2 (keys %{$patchrms{$ci1}}) {
			$citemp{$ci1}{$ci2} = [$patchrms{$ci1}->{$ci2}->[0],  $patchrms{$ci1}->{$ci2}->[1] ];
		}
	}
}

sub get_adj_config {
	my $dbh = shift;
	my %adj;
	my $sth = $dbh->prepare("select concat(LAC,'~',CI), concat(LAC_TGT,'~',CI_TGT) from Adjacency;");
	$sth->execute;
	while (my @row = $sth->fetchrow_array ) {
		$adj{$row[0]}{$row[1]} = 1;
		$adj{$row[1]}{$row[0]} = 1;
	}
	return \%adj;
}

sub get_bcchbsic_config {
	my $dbh = shift;
	# get all BCCH/BSIC information for the network for last week...
	my %bcch;
	my %bsic;
	my @cell = qw/LAC CI BCCHFrequency BsIdentityCode IMPORTDATE CellAllocation CellAllocationDCS/;
	my $sth = $dbh->prepare('select '.join(',',@cell).' from Cell');
	
	my %d = ();
	$sth->execute;
	while ( my @row = $sth->fetchrow_array ) {
		@d{@cell} = @row;
		my $id = join('~',@d{qw/LAC CI/});
		my $ca = $d{'CellAllocation'} eq '{}' ? $d{'CellAllocationDCS'} : $d{'CellAllocation'};
		my ($ncc,$bcc) = ($d{'BsIdentityCode'} =~ /ncc\s(\d+)\,\sbcc\s(\d+)/);
		$bsic{$d{'BCCHFrequency'}.';'.(8*$ncc + $bcc)}{$d{'IMPORTDATE'}}{$id} = 1;
		$bcch{$id}{$d{'IMPORTDATE'}} = [ $d{'BCCHFrequency'}, $ca ];
	}
	return (\%bcch,\%bsic);
}

sub get_best_bcch_bsic_candidate {
	my ($ci, $bcch, $bsic, $date,$bsicref,$adjref) = @_;

	if (exists $bsicref->{"$bcch;$bsic"}->{$date} ) {
		# is it amongst first-order neighbours?
		foreach (keys %{$adjref->{$ci}}) {
			if (exists ($bsicref->{"$bcch;$bsic"}->{$date}->{$_})) {
				return $_;
			}
		}	
	}
	return "unknown";
}
1;
