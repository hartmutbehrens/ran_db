package Common::CSV;

=head1 NAME
Common::CSV;
=cut

#pragmas
use strict;
use warnings;
#modules
use Common::MySQL;
use Common::XML;

#converts hash ref from decode sub into CSV
sub to_csv {
	my ($pm,$counters,$info,$source,$type,$outdir,$warn_on) = @_;
	$warn_on = 0 unless defined $warn_on;
	my $rv = 0;
	return $rv unless (scalar(keys %$counters) > 0);
	$info->{'OMC_ID'} = $source;
	my @icols = keys %{$info};
	
	foreach my $table (keys %{$pm}) {
		next if ($table eq 'none');
		my $dt = join('.',@{$info}{@icols});
		$dt =~ s/\:/_/g;		#windows does not like ':' in the filename
		$dt =~ s/\"//g;
		$dt =~ s/\//\-/g;
		my $out_file = $outdir."/".$source.'.'.$type.'.'.$table.'.'.$dt.'.csv';
		print "Writing CSV to: $out_file\n";
		my @counters = sort keys %{$counters->{$table}};
		my $has_header = 0;
		open my $out,">".$out_file || die "Could not open $out_file for writing: $!\n";
		my %line = ();
		foreach my $ix (keys %{$pm->{$table}}) {
			my ($ixCols,$ixVals) = ($ix =~ /^(.*?)\=(.*)/);
			my @ixCols = split(',',$ixCols);
			my @ixVals = split(',',$ixVals);
			unless ($has_header) {
				print $out join(';',@icols,@ixCols,@counters)."\n";
				$has_header=1;
				$rv = 1;
			}
			print $out join(';',@{$info}{@icols},@ixVals,map(exists($pm->{$table}->{$ix}->{$_})? $pm->{$table}->{$ix}->{$_}:'NULL',@counters))."\n";
			foreach my $c (@counters) {
				warn "$table, $ix, $c value is NULL \n" if ( ($warn_on) && (not exists $pm->{$table}->{$ix}->{$c}) ); 
			}
		}
		close $out;	
	}
	return $rv;
}

sub load_csv {
	my ($dbh,$indir,$file,$config_file) = @_;
	
	my $rv = 0;
	my ($source,$type,$table) = split('\.',$file);
	unless (defined($source) && defined($type) && defined($table)) {
		warn "$file does not conform to the naming convetions and will be skipped ..\n";
		return $rv;
	}
	
	my $config = Common::XML::read_xml($config_file)->{setting}; 
	unless (defined($config->{$type})) {
		warn "Could not find an entry in \"$config_file\" describing how to load csv from file type \"$type\". Perhaps an entry needs to be added?\n ";
		return $rv;	
	}
	
	
	#check if table exists
	my @all = @{$dbh->selectcol_arrayref("show tables")};
	unless (grep {/^$table/i} @all) {
		warn "Could not load file because the table \"$table\" was not found in the database!\n";
		return $rv;
	}
	 
	
	#get table definition
	my %def = ();
	Common::MySQL::get_table_definition($dbh,$table,\%def);
	$dbh->do("lock tables $table write") || die($dbh->errstr) ;
	print "Loading: ($file) $table from $source ($type)..\n";
	my $sep = $config->{$type}->{'fieldseparator'};
	my $i = 0;
	
	my (%d,%only,@cols);
	open my $in ,"<","$indir/$file" || die "Could not open $indir/$file for reading:$!\n";
	while(<$in>) {
		chomp;
		if (defined($config->{$type}->{'line'}->{$.})) {
			if (defined($config->{$type}->{'line'}->{$.}->{'whitespace'})) {
				$_ =~ s/\s//g if ($config->{$type}->{'line'}->{$.}->{'whitespace'} eq 'remove');
			}
			my @row = split($sep,$_);
			@cols = ($config->{$type}->{'line'}->{$.}->{'columns'} eq 'retrieve_from_line') ? @row : split($sep,$config->{$type}->{'line'}->{$.}->{'columns'});
			@d{@cols} = @row;
			
			#only load columns that exist in $table
			foreach my $c (@cols) {
				if (exists $def{$c}) {
					$only{$c} = 1;	
				}
				else {
					#warn "Data for $c will not be loaded because no suitable column exists in $table.\n"; 
				}
			}
		}
		else {
			@d{@cols} = split($sep,$_);
			my %e = ();
			@e{keys %only} = @d{keys %only};
			#remove clutter
			foreach my $k (keys %e) {
				delete $e{$k} if (defined($e{$k}) && (uc($e{$k}) eq 'NULL'));
				delete $e{$k} if (defined($e{$k}) && (uc($e{$k}) eq '?'));	#obsynt
				delete $e{$k} if (defined($e{$k}) && (length($e{$k}) == 0) );
			}
			#fixed in to_csv for most file types, but not for rnl (because it is extracted as-is out of the archive coming from the OMC-R)
			if (exists $def{'OMC_ID'}) {
				$e{'OMC_ID'} = exists $e{'OMC_ID'} ? $e{'OMC_ID'} : $source;	
			}
			
			my @vals = values %e;
			#my $sql = 'replace into '.$table.' ('.join(',',map('`'.$_.'`',keys %e)).') values ('.join(',',map('\''.$_.'\'',@vals)).')';
			my $sql = 'replace into '.$table.' ('.join(',',map('`'.$_.'`',keys %e)).') values ('.join(',',map('?',@vals)).')';
			my $sth = $dbh->prepare($sql);
			$sth->execute(@vals);
			#$dbh->do($sql) || logFatal("SQL error;$_;$sql;".$dbh->errstr);
			#print "$sql\n";
			$i++;
		}
	}
	close $in;
	$dbh->do("unlock tables") || die($dbh->errstr) ;
	$rv = 1;
	print "Loaded $i records.\n";
	return $rv;
}

sub load_csv_file {
	my ($dbh,$indir,$file,$config_file) = @_;
	my %loaded;
	my $rv = 0;
	my ($source,$type,$table) = split('\.',$file);
	unless (defined($source) && defined($type) && defined($table)) {
		warn "$file does not conform to the naming convetions and will be skipped ..\n";
		return $rv;
	}
	
	my $config = Common::XML::read_xml($config_file)->{setting}; 
	unless (defined($config->{$type})) {
		warn "Could not find an entry in \"$config_file\" describing how to load csv from file type \"$type\". Perhaps an entry needs to be added?\n ";
		return $rv;	
	}
	my $sep = $config->{$type}->{'fieldseparator'};
	#check if table exists
	my @tables = @{$dbh->selectcol_arrayref("show tables")};
	return unless (grep {/^$table/i} @tables);
	
	print "LOAD: ($file) $table from $source ($type)..\n";
	#retrieve column names
	my @cols = ();
	open my $in ,'<', $indir.'/'.$file || die "Could not open $indir/$file:$!\n";
	while(<$in>) {
		chomp;
		if ($. == 1) {
			@cols = split($sep,$_);
			last;
		}
	}
	close $in;
	$dbh->do("lock tables $table write") || die($dbh->errstr) ;
	my $sql = "LOAD DATA LOCAL INFILE '".$indir.'/'.$file."' INTO TABLE `".$table."` FIELDS TERMINATED BY '".$sep."' LINES TERMINATED BY '\\n' IGNORE 1 LINES (".join(',',map('`'.$_.'`',@cols)).")";
	$dbh->do($sql) || die($dbh->errstr);
	$dbh->do("unlock tables") || die($dbh->errstr) ;
	print "Loaded file $file\n";
	$rv = 1;
	return $rv;
}

1;
