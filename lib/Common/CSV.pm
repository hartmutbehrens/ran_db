package Common::CSV;

=head1 NAME
Common::CSV;
=cut

#pragmas
use strict;
use warnings;

#converts hash ref from decode sub into CSV
sub to_csv {
	my ($pm,$counters,$info,$source,$type,$outdir,$warn_on) = @_;
	$warn_on = 0 unless defined $warn_on;
	my $rv = 0;
	return $rv unless (scalar(keys %$counters) > 0);
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

1;
