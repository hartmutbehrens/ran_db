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

subtest 'Multiple Document FETCH' => sub {
	my $data;
	my @want = qw(first_doc second_doc);
	lives_ok { $data = $couch->fetch(\@want) } 'Multiple doc id and rev fetch OK';
	my @ids = map( $_->{id} , @{$data->{rows}} );
	is_deeply(\@ids,\@want,'Retrieved ids from fetch are OK');
	lives_ok { $data = $couch->fetch_with_doc(['first_doc','second_doc']) } 'Multiple doc fetch OK';
	@ids = map( $_->{id} , @{$data->{rows}} );
	is_deeply(\@ids,\@want,'Retrieved ids from fetch_with_doc are OK');
};

done_testing();