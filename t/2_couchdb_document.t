#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Database;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my ($name,$doc_id,$bogus) = ('docs_testing','first_doc','does_not_exist');

my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => $name]);
$couch->create_db unless $couch->has_db;

my $doc_ok = $couch->new_doc($doc_id);
$doc_ok->debug(1);
my $data = $doc_ok->get;
is(defined $data, 1, 'Document retrieval OK');

my $doc_bad = $couch->new_doc($bogus);
$doc_bad->debug(1);
subtest 'Non-existent document retrieval' => sub {
	dies_ok { $doc_bad->get }, "Non-existent document retrieval handled OK";	
};

	


done_testing();