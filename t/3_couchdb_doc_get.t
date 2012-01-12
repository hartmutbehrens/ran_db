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

subtest 'Document GET' => sub {
	dies_ok { $couch->new_doc() } 'Document creation without specifying id handled OK';
	
	my $doc1 = $couch->new_doc('first_doc');
	my $data = $doc1->get;
	is(defined $data->{_rev}, 1, 'Document retrieval OK');
	
	my $doc3 = $couch->new_doc('bogus');
	dies_ok { $doc3->get } 'Non-existent document retrieval handled OK';
};

done_testing();