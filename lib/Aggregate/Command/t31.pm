package Aggregate::Command::t31;

=head1 NAME
Aggregate::Command::t31;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::MySQL;
use Aggregate -command;


sub abstract {
	return "aggregate 2G radio measurement data for frequency planning and missing neighour detection";
}

sub usage_desc {
	return "%c t31 %o";
}

sub opt_spec {
	my @which = (
		["cell", "aggregate for frequency planning"],
		["ho", "aggregate for missing neighbour detection"],
	);
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "which|w=s",	"type of aggregation that should be run", { required => 1, hidden => 1, one_of => \@which}],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $count = 0;
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	if ($opt->{which} eq 'cell') {
		do_T31($dbh,undef,'T31_CIN_CELL_D');
	}
	if ($opt->{which} eq 'ho') {
		do_T31($dbh,2,'T31_CIN_HO_D');	#upper dB limit of 2dB, useful for detecting missing neighbours
	}
}



sub do_T31 {
	my ($dbh,$upper_bound_dB,$table) = @_;
	my @gcol = qw/CI LAC SDATE BCCH BSIC TPR_CIN MR_CIN BSC_NAME OMC_ID/;
	my @acol = qw/SDATE LAC CI BCCH BSIC BSC_NAME OMC_ID/;
	my @pcol = qw/SDATE LAC CI BCCH BSIC BSC_NAME OMC_ID TOTAL/;
	my %aggregate = ();
	my $canGive = $dbh->prepare('select '.join(',',@gcol).' from T31_CIN_D');
	my $getPar = $dbh->prepare('select TAB_PAR_MEAS_C_I from T31_CELL_D where CI = ? and LAC = ? and SDATE = ?');
	
	
	$canGive->execute;
	print "Collecting T31 data for aggregation..\n";
	while (my @row = $canGive->fetchrow_array) {
		if (@row) {
			my %d = ();
			@d{@gcol} = @row;
			
			$getPar->execute(@d{qw/CI LAC SDATE/});
			my ($par) = $getPar->fetchrow_array;
			next if not defined($par);	#don't have a C/I bins parameter for this cell
			my @vals = map(sprintf("%.2f",($_*$d{'MR_CIN'})/254),split(',',$d{'TPR_CIN'}));
			my ($first_bound,$last_bound) = (-63,63);
			my @bounds = map(($_-63),split(',',$par));
			my $max_width = 0;
			for (0..$#bounds-1) {
				my $diff =  $bounds[$_ + 1] - $bounds[$_];
				
				$max_width = $max_width < $diff ? $diff : $max_width;
			}
			@bounds = ($bounds[0]-$max_width,@bounds,$bounds[$#bounds]+$max_width);
			
			my @weights = map(((($bounds[$_]-$bounds[($_+1)])/2) + $bounds[($_+1)]),0..9);
			# inversion of the array
			@weights = map(63-$_,@weights);
			# offset to eliminate negative numbers and zero
			@weights = map(($weights[$_]-$weights[9]+1),0..9);
			
			my $to = 9;
			if (defined $upper_bound_dB) {
				for my $i (0..$#bounds) {
					$to = $i if $upper_bound_dB > $bounds[$i];
				}
			}
			
			my $totval = 0;
			for my $i (0..$to) {
				$totval += $vals[$i]*$weights[$i];
			}
			$aggregate{join(',',@d{@acol})} += $totval;
		}
	}
	print "Populating database table $table ..\n";
	foreach my $id (keys %aggregate) {
		my %e = ();
		my @val = split(',',$id);
		@e{@acol} = @val;
		$e{'TOTAL'} = $aggregate{$id};
		
		my $sql = 'replace into '.$table.' ('.join(',',@pcol).') values ('.join(',',map('\''.$_.'\'',@e{@pcol})).')';
		$dbh->do($sql) || die $dbh->errstr;
	}
}




1;