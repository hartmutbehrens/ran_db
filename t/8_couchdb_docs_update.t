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
use Mojo::JSON;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => 'docs_testing', debug => 1]);

subtest 'Multiple Document INSERT/UPDATE' => sub {
	my $data = [{ '_id' => 'first_doc', 'name' => 'julius', 'surname' => 'ceasar'},
				{ '_id' => 'second_doc', 'name' => 'king', 'surname' => 'george'},
				{ '_id' => 'third_doc', 'name' => 'captain', 'surname' => 'kirk'}];
	
	my $response; 
	lives_ok { $response = $couch->insert($data) } 'Multiple doc insert/update OK';
	is(defined $response->[0]->{rev}, 1, 'First entry insert/update OK');
	is(defined $response->[1]->{rev}, 1, 'Second entry insert/update OK');
	is(defined $response->[2]->{rev}, 1, 'Second entry insert/update OK');
	
	$data = [{ '_id' => 'first_doc', 'name' => 'julius', 'surname' => 'malema'},
				{ '_id' => 'second_doc', 'name' => 'king', 'surname' => 'tut'},
				{ '_id' => 'third_doc', '_deleted' => Mojo::JSON->true }];
				
	lives_ok { $response = $couch->insert($data) } 'Multiple doc insert/update with delete OK';
	is(defined $response->[0]->{rev}, 1, 'First entry insert/update with delete OK');
	is(defined $response->[1]->{rev}, 1, 'Second entry insert/update with delete OK');
	is(defined $response->[2]->{rev}, 1, 'Second entry insert/update with delete OK');
};

done_testing();