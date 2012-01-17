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
	my $data = $couch->get_doc({id => 'first_doc'});
	is(defined $data->{_rev}, 1, 'Document retrieval OK');
	
	$data = $couch->get_doc({id => 'bogus'});
	is($data, undef, 'Non-existent document retrieval handled OK');
};

done_testing();