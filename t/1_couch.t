#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Common::CouchDB;


my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my $couch = new_ok('Common::CouchDB' => [uri => $uri]);
#print Dumper($couch->{ua}->transactor);
#exit;
is($couch->exists(), 1, "Connection to $uri is OK" );

subtest 'Connection to invalid URI' => sub {
	my $dodgy = Common::CouchDB->new(uri => 'http://rub.i.sh/');
	dies_ok { $dodgy->exists() }, "Connection to invalid URI handled OK" ;	
};

is($couch->has_db('_users'), 1, "has_db test OK");

if ($couch->has_db('testing')) {
	is($couch->del_db('testing'), 1, "Database deletion OK");
}
is($couch->new_db('testing'), 1, "Database creation OK");
my $db = $couch->all_dbs();
ok( grep(/testing/, @{$db} ), "all_dbs works ( @{$db} )"  );
subtest 'Trying to create a database when one already exists' => sub {
	dies_ok { $couch->new_db('testing') }, "Creating a database when one already exists handled OK" ;	
};
is($couch->del_db('testing'), 1, "Database deletion OK");
is($couch->has_db('testing'), 0, "has_db test with database that does not exist OK");

done_testing();