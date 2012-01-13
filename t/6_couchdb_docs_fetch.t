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
	lives_ok { $data = $couch->get_multiple(\@want) } 'Multiple doc id and rev fetch OK';
	my @ids = map( $_->{id} , @{$data->{rows}} );
	is_deeply(\@ids,\@want,'Retrieved ids from fetch are OK');
	lives_ok { $data = $couch->get_multiple_with_doc(['first_doc','second_doc']) } 'Multiple doc fetch OK';
	@ids = map( $_->{id} , @{$data->{rows}} );
	is_deeply(\@ids,\@want,'Retrieved ids from fetch_with_doc are OK');
	
	lives_ok { $data = $couch->get_multiple(['third_doc']) } 'Doc fetch with bogus id handled OK';
	is( defined $data->{rows}->[0]->{error}, 1, 'Unknown doc id generates error OK' );
	
	push @want, 'third_doc';
	lives_ok { $data = $couch->get_multiple(\@want) } 'Multiple doc fetch with bogus id handled OK';
	is( defined $data->{rows}->[2]->{error}, 1, 'Unknown doc id generates error OK' );
	
	lives_ok { $data = $couch->get_multiple_with_doc(\@want) } 'Multiple doc fetch with bogus id handled OK';
	is( defined $data->{rows}->[2]->{error}, 1, 'Unknown doc id generates error OK' );
	
};

done_testing();