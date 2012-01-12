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

subtest 'Document PUT' => sub {
	my $data = {'name' => 'lauren','surname' => 'snyman'};
	my $new_data = {'name' => 'hartmut', 'surname' => 'behrens'};
	
	$couch->delete_doc('second_doc');
	my $doc = $couch->new_doc('second_doc',$data);
	
	lives_ok { $doc->put } 'Document PUT OK';
	is(defined $doc->_rev, 1, 'Document revision defined OK');
	my $fetched = $doc->get;
	is($fetched->content->{name},$data->{name}, 'Document content OK');
	
	$doc->content($new_data);
	lives_ok { $doc->put } 'Document PUT with new content OK';
	$fetched = $doc->get;
	is($fetched->content->{name},$new_data->{name}, 'Document content update OK');
};

done_testing();