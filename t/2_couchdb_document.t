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
my ($name,$bogus) = ('docs_testing','does_not_exist');

my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => $name]);
$couch->create_db unless $couch->has_db;

subtest 'Document retrieval' => sub {
	my $doc1 = $couch->new_doc('first_doc');
	my $doc2 = $couch->new_doc();
	my $doc3 = $couch->new_doc('bogus');
	$doc1->debug(1);$doc2->debug(1);$doc3->debug(1);
	my $data = $doc1->get;
	is(defined $data->{_rev}, 1, 'Document retrieval OK');
	dies_ok { $doc2->get } 'Document retrieval without specifying _id handled OK';
	$data = $doc2->get('first_doc');
	is(defined $data->{_rev}, 1, 'Document retrieval with parameter OK');
	dies_ok { $doc3->get } 'Non-existent document retrieval handled OK';	
};



	


done_testing();