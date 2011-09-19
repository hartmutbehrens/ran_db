package Report::Command::bh;

=head1 NAME
Report::Command::bh;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::MySQL;
use Common::MakeIt;
use Report -command;

sub abstract {
	return "calculate 2G busy hour and store result in table";
}

sub usage_desc {
	return "%c bh %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "cstable|c=s","input table for 2G CS busy hour calculation", { required => 1 }],
	[ "pstable|p=s","input table for 2G CS busy hour calculation", { required => 1 }],
	[ "csformula|cf=s",	"CS counter/formula for busy hour calculation", { required => 1 }],
	[ "psformula|pf=s",	"PS counter/formula for busy hour calculation", { required => 1 }],
	[ "date=s",	"date column used in calculation", { required => 1 }],
	[ "time=s",	"time column used in calculation", { required => 1 }],
	[ "numdays|n=s",	"number of recent days to calculate busy hour for", { default => 2 }],
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
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	my @tables = @{$dbh->selectcol_arrayref("show tables")};
	for ($opt->{cstable},$opt->{pstable},'Cell_BH') {
		die "Cannot calculate busy hour because table $_ does not exist! \n" unless grep {/^$_/} @tables;
	}	
	
	my @dates = ();
	print "Checking latest dates available in $opt->{cstable} ..";
	my $sth = $dbh->prepare('select distinct '.$opt->{date}.' from '.$opt->{cstable}.' order by '.$opt->{date}.' desc limit '.$opt->{numdays});
	$sth->execute();
	while (my @row = $sth->fetchrow_array) {
		print "$row[0]..";
		push(@dates,$row[0]);
	}
	for my $date (@dates[1..$#dates]) {
		get_data($dbh,\%bh,$date,$opt->{cstable},$opt->{date},$opt->{time},$opt->{csformula});
		get_data($dbh,\%bh,$date,$opt->{pstable},$opt->{date},$opt->{time},$opt->{psformula});
		populate_table($dbh,\%bh);
		%bh = ();
	}
}

sub get_data {
	my ($dbh,$bh_ref,$date,$table,$date_col,$time_col,$counter) = @_;
	my %d = ();
	print "\nCalculating busy hour on $table for $date using $counter ..\n";
	my @cols = (qw(LAC CI),$time_col,$counter);
	my $sql = 'select '.join(',',@cols).' from '.$table.' where '.$date_col.' = ?';
	my $sth = $dbh->prepare($sql);
	$sth->execute($date);
	while (my @row = $sth->fetchrow_array) {
		@d{@cols} = @row;
		next unless defined $d{'LAC'} && defined $d{'CI'};
		my $id = join(',',@d{qw/CI LAC/},$date);
		$bh_ref->{$id}->{$d{$time_col}} = defined $bh_ref->{$id}->{$d{$time_col}} ? $bh_ref->{$id}->{$d{$time_col}} + $d{$counter} : $d{$counter};
	}
}

sub populate_table {
	my ($dbh,$bh_ref) = @_;
	my %d = ();
	my @cols = qw/CI LAC IMPORTDATE BH/;
	foreach my $id (keys %{$bh_ref}) {
		my ($bh_time) = sort {$bh_ref->{$id}->{$b} <=>  $bh_ref->{$id}->{$a}} keys %{$bh_ref->{$id}};
		my @values = (split(',',$id),$bh_time);
		my $sql = 'replace into Cell_BH ('.join(',',@cols).') values ('.join(',',map('\''.$_.'\'',@values)).')';
			
		$dbh->do($sql) || die $dbh->errstr,"\n";
	}
}


1;
