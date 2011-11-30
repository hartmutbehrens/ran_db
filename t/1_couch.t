#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Common::CouchDB;

my $uri = 'http://hartmut.iriscouch.com/';
my $couch = new_ok('Common::CouchDB' => [uri => $uri]);
is($couch->exists(), 1, "Connection to $uri is OK" );
ok( grep(/_users/, @{$couch->all_dbs()} ), "all_dbs works"  );

done_testing();