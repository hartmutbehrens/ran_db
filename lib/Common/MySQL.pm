package Common::MySQL;

=head1 NAME
Common::MySQL;
=cut

#pragmas
use strict;
use warnings;
#modules
use Carp qw(croak);
use DBI;


sub connect {
	my ($dbhref, $user,$pass,$host,$port,$db) = @_;
	my ($dbh, $dsn, $drh);
	
	$dsn = 'DBI:mysql:;host='.$host.';port='.$port;
	$dbh = DBI->connect($dsn, $user, $pass);
	$drh = DBI->install_driver('mysql');
	# grab general database information
	my @databases = @{$dbh->selectcol_arrayref("show databases")};	# this is only interesting for debugging purposes
	# does the correct DB exist?
	my $found = 0 ; for (@databases) {$found = 1 if (uc($_) eq uc($db))};
	return 0 if (!$found);
	$dbh->disconnect;
	# now connect properly
	$dsn = 'DBI:mysql:'.$db.';host='.$host.';port='.$port;
	$$dbhref = DBI->connect($dsn, $user, $pass);
	$drh = DBI->install_driver('mysql');
	return 1;
}

sub get_table_definition {
	my ($dbh,$table,$defRef,$idxRef) = @_;
	croak "Need a valid database handle. The one you provided is not defined!\n" unless defined $dbh;
	my $hasTable = 0;
	my $sth = $dbh->prepare("show tables");
	$sth->execute();
	while (my @def = $sth->fetchrow_array) {
		$hasTable = 1 if (lc($def[0]) eq lc($table));
	}
	return $hasTable if not $hasTable;
	$sth = $dbh->prepare("describe $table");
	$sth->execute();
	while (my @def = $sth->fetchrow_array) {
		$defRef->{$def[0]} = 1;	
	}
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
	return $hasTable;	
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