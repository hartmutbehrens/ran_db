#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Document;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/docs_testing';
my $doc = new_ok('CouchDB::Document' => [uri => $uri]);

my $id = 'first_doc';
my $data = {'name' => 'hartmut', 'surname' => 'behrens'};
print "Data:",Dumper($data),"\n";
is($doc->put($id,$data), 1, "Document PUT OK");

done_testing();