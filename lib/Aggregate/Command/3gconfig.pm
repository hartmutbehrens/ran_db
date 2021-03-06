package  Aggregate::Command::3gconfig;

=head1 NAME
Aggregate::Command::3gconfig;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::Lock;
use Common::MySQL;
use Common::Distance;
use Aggregate -command;

sub abstract {
	return "add distance related data to 3G snapshot tables (mainly used for mapping)";
}

sub usage_desc {
	return "%c rnl %o";
}

sub opt_spec {
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "update|U",	"update distances with data from 2G (also required 2G database credentials to be provided)", { hidden => 1}],
	[ "user2g|u2g=s",	"optional 2G database user", { hidden => 1 }],
	[ "pass2g|x2g=s",	"optional 2G database password", { hidden => 1 }],
	[ "host2g|h2g=s",	"optional 2G database host IP address", { hidden => 1 }],
	[ "db2g|d2g=s",	"optional 2G database name", { hidden => 1 }],
	[ "port2g|P2g=s",	"optional 2G database port", { hidden => 1, default => 3306 }],
	[ "driver=s",	"database driver (default mysql)", { default => "mysql" }],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $count = 0;
	my $conn = Common::MySQL::get_connection(@{$opt}{qw/user pass host port db driver/});
	die "Could not get a database connection\n" unless defined $conn;
	my $dbh = $conn->dbh;

	my $lock = '.'.$opt->{db}.'3gconfig';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	
	aggregate_3gconfig($dbh);
	if ($opt->{update}) {
		my $conn2g = Common::MySQL::get_connection(@{$opt}{qw/user2g pass2g host2g port2g db2g driver/});
		die "Could not get a 2G database connection\n" unless defined $conn2g;
		
		if ($conn2g) {
			my $dbh2g = $conn2g->dbh;
			update_with_2g($dbh,$dbh2g);
		}
	}
}

sub aggregate_3gconfig {
	my $dbh = shift;
	print "Updating UMTSNeighbourCells columns..\n";
	my @cols1 = qw/cellId locationAreaCode tgtCI tgtLAC IMPORTDATE NodeBName/;
	my @cols2 = qw/radians(LAT) radians(LON)/;
	my @cols3 = qw/NodeBName/;
	my $sth1 = $dbh->prepare('select '.join(',',@cols1).' from UMTSNeighbourCells where Distance is null');
	my $sth2 = $dbh->prepare('select '.join(',',@cols2).' from CELLPOSITIONS_3G where NODEB_NAME=? limit 1');
	my $sth3 = $dbh->prepare('select '.join(',',@cols3).' from Cell where cellId=? and locationAreaCode=? limit 1');
	my $sth4 = $dbh->prepare('update UMTSNeighbourCells set Distance=? where cellId=? and locationAreaCode=? and tgtCI=? and tgtLAC=? and IMPORTDATE=?');
	$sth1->execute;
	while (my @row = $sth1->fetchrow_array) {
		my %d;
		@d{@cols1} = @row;
		$sth3->execute(@d{qw/tgtCI tgtLAC/});
		my ($nbNode) = $sth3->fetchrow_array;
		$sth2->execute($d{'NodeBName'});
		my ($lat,$lon) = $sth2->fetchrow_array;
		$sth2->execute($nbNode);
		my ($tlat,$tlon) = $sth2->fetchrow_array;
		my ($distance) = Common::Distance::haversine($lat,$lon,$tlat,$tlon);
		$sth4->execute($distance,@d{qw/cellId locationAreaCode tgtCI tgtLAC IMPORTDATE/});
	}
		
}

sub update_wth_2g {
	my ($dbh,$dbh2g) = @_;
	print "Updating GSMNeighbourCells columns ..\n";
#	my $gdbh = undef;
#	#besides access to the 3G database, this also needs access to the 2G database

	my @cols1 = qw/cellId locationAreaCode tgtCI tgtLAC IMPORTDATE NodeBName/;
	my @cols2 = qw/radians(LAT) radians(LON)/;
	my $sth1 = $dbh->prepare('select '.join(',',@cols1).' from GSMNeighbourCells where Distance is null');
	my $sth2 = $dbh2g->prepare('select '.join(',',@cols2).' from CELLPOSITIONS_GSM where CI=? and LAC=? limit 1');
	my $sth3 = $dbh->prepare('select '.join(',',@cols2).' from CELLPOSITIONS_3G where NODEB_NAME=? limit 1');
	my $sth4 = $dbh->prepare('update GSMNeighbourCells set Distance=? where cellId=? and locationAreaCode=? and tgtCI=? and tgtLAC=? and IMPORTDATE=?');
	$sth1->execute;
	while (my @row = $sth1->fetchrow_array) {
		my %d;
		@d{@cols1} = @row;
		$sth2->execute(@d{qw/tgtCI tgtLAC/});
		$sth3->execute(@d{qw/NodeBName/});
		my @row2 = $sth2->fetchrow_array;
		my @row3 = $sth3->fetchrow_array;
		my ($distance) = Common::Distance::haversine(@row2,@row3);
		$sth4->execute($distance,@d{qw/cellId locationAreaCode tgtCI tgtLAC IMPORTDATE/});
	}
}


1;
