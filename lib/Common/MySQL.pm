package Common::MySQL;

=head1 NAME
Common::MySQL;
=cut

#pragmas
use strict;
use warnings;
#modules
use Carp qw(croak);
use DBIx::Connector;

sub get_connection {
	my ($user,$pass,$host,$port,$db,$driver) = @_;
	$driver = $driver // 'mysql';
	my $dsn = "DBI:$driver:$db;host=$host;port=$port";
	my $conn = DBIx::Connector->new($dsn, $user, $pass, {RaiseError => 1,AutoCommit => 1,});
	return $conn;
}

sub connect {
	my ($dbhref, $user,$pass,$host,$port,$db,$driver) = @_;
	my $conn = get_connection($user,$pass,$host,$port,$db,$driver);
	if (defined $conn) {
		$$dbhref = $conn->dbh;
		return 1;
	}
	else {
		die "Could not connect to $db. Please check that the connection details are correct\n";
		return 0;
	}
}

sub get_table_definition {
	my ($dbh,$table,$defRef,$idxRef) = @_;
	croak "Need a valid database handle. The one you provided is not defined!\n" unless defined $dbh;
	
	return 0 unless has_table($dbh,$table);
	
	my $sth = $dbh->prepare("describe $table");
	$sth->execute();
	while (my @def = $sth->fetchrow_array) {
		$defRef->{$def[0]} = 1;	
	}
	if (defined $idxRef) {
		my @idx = qw/table non_unique idxName sequence col/;
		my %d = ();
		my @d = ();
		$sth = $dbh->prepare("show index from $table");
		$sth->execute();
		while (my @row = $sth->fetchrow_array) {
			@d{@idx} = @row;
			my $unique = ($d{'non_unique'} == 0) ? 'yes' : 'no';
			${$idxRef->{$d{'idxName'}.';'.$unique}}[--$d{'sequence'}] = $d{'col'};		
		}
	}
	return 1;	
}

sub get_definition {
	my ($dbh,$table) = @_;
	my (%def,%index);
	get_table_definition($dbh,$table,\%def,\%index);
	return wantarray ? (\%def,\%index) : \%def;
}

sub has_table {
	my ($dbh,$table) = @_;
	croak "Need a valid database handle. The one you provided is not defined!\n" unless defined $dbh;
	my $rv = 0;
	my @tables = @{$dbh->selectcol_arrayref("show tables")};
	$rv = 1 if (grep {/^$table/i} @tables);
	return $rv;
}

1;