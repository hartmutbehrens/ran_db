#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Database;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => 'docs_testing', debug => 1]);

subtest 'Document EXISTS' => sub {
	is($couch->exists_doc('does_not_exist'), 0, 'No document check OK');
	is($couch->exists_doc('first_doc'), 1, 'Document check OK');
};

done_testing();