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
my ($name,$doc_id) = ('docs_testing','first_doc');
my $couch = new_ok('CouchDB::Database' => [uri => $uri, name => $name]);

$couch->create_db unless $couch->has_db;
my $doc = $couch->new_doc($doc_id);
$doc->debug(1);
my $data = $doc->get;
print Dumper($data);

done_testing();