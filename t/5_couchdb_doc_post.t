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
	my $data = {'name' => 'laurenhartmut','surname' => 'snymanbehrens'};
	
	my $doc = $couch->new_doc();
	$doc->content($data);
	lives_ok { $doc->post } 'Document POST OK';
	is(defined $doc->{_id}, 1, 'Document POST assigned id OK');
};

done_testing();