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

subtest 'Document POST' => sub {
	my $content = {'name' => 'laurenhartmut','surname' => 'snymanbehrens'};
	
	my $data = $couch->post_doc({id => 'first_doc', content => $content});
	is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document POST OK');
	is(defined $data->{id}, 1, 'Document POST assigned id OK');
};

done_testing();