#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Connector;


my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com';
my $couch = new_ok('CouchDB::Connector' => [uri => $uri]);
my $name = 'testing';

subtest 'Connection to invalid URI' => sub {
	dies_ok { CouchDB::Connector->new(uri => 'http://rub.i.sh/') }, "Connection to invalid URI handled OK" ;	
};

is($couch->has_db('_users'), 1, "has_db test OK");

if ($couch->has_db($name)) {
	is($couch->del_db($name), 1, "Database deletion OK");
}
is($couch->create_db($name), 1, "Database creation OK");
my $db = $couch->all_dbs();
ok( grep(/testing/, @{$db} ), "all_dbs works ( @{$db} )"  );
subtest 'Trying to create a database when one already exists' => sub {
	dies_ok { $couch->create_db($name) }, "Creating a database when one already exists handled OK" ;	
};

is($couch->del_db($name), 1, "Database deletion OK");
is($couch->has_db($name), 0, "has_db test with database that does not exist OK");

done_testing();