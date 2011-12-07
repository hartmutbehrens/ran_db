#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Database;


my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com';	#left out ending / on pupose for testing
my $name = 'testing';
my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => $name]);
$couch->debug(1);
is($couch->uri, $uri.'/','Absence of / handled OK');


subtest 'Connection to invalid URI' => sub {
	dies_ok { CouchDB::Database->new(uri => 'http://rub.i.sh/', name => $name) }, "Connection to invalid URI handled OK" ;	
};


is($couch->del_db, 1, "Database deletion OK") if $couch->has_db;

my $db = $couch->all_dbs;
ok( grep(/testing/, @{$db} ), "all_dbs works ( @{$db} )"  );
subtest 'Trying to create a database when one already exists' => sub {
	is($couch->create_db, 1, "Database creation OK");
	dies_ok { $couch->create_db }, "Creating a database when one already exists handled OK" ;	
};

is($couch->del_db, 1, "Database deletion OK");
is($couch->has_db, 0, "has_db test with database that does not exist OK");

done_testing();