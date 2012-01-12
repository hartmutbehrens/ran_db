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
my ($name,$bogus) = ('docs_testing','does_not_exist');

my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => 'docs_testing', debug => 1]);
$couch->create_db unless $couch->has_db;

#subtest 'Document EXISTS' => sub {
#	is($couch->exists_doc('does_not_exist'), 0, 'No document check OK');
#	is($couch->exists_doc('first_doc'), 1, 'Document check OK');
#};
#
#subtest 'Document GET' => sub {
#	my $doc1 = $couch->new_doc('first_doc');
#	my $doc2 = $couch->new_doc();
#	my $doc3 = $couch->new_doc('bogus');
#	
#	my $data = $doc1->get;
#	
#	is(defined $data->{_rev}, 1, 'Document retrieval OK');
#	dies_ok { $doc2->get } 'Document retrieval without specifying _id handled OK';
#	$data = $doc2->get('first_doc');
#	is(defined $data->{_rev}, 1, 'Document retrieval with parameter OK');
#	dies_ok { $doc3->get } 'Non-existent document retrieval handled OK';	
#};

subtest 'Document PUT' => sub {
	my $data = {'name' => 'lauren','surname' => 'snyman'};
	$couch->delete_doc('second_doc');
	my $doc = $couch->new_doc('second_doc',$data);
	lives_ok { $doc->put } 'Document PUT OK';
	is(defined $doc->_rev, 1, 'Document revision defined OK');
};

done_testing();