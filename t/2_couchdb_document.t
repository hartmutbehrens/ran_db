#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CouchDB::Document;

my $uri = 'http://hartmut:vodacom@hartmut.iriscouch.com/';
my $doc = new_ok('CouchDB::Document' => [uri => $uri]);
my $name = 'docs_testing';

done_testing();