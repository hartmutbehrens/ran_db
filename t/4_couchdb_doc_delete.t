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

subtest 'Document DELETE' => sub {
	SKIP: {
		skip 'first_doc not available for deletion', 1 unless $couch->exists_doc({id => 'first_doc'});
		my $data = $couch->delete_doc({id => 'first_doc'});
		is(defined $data->{ok} && $data->{ok} == 1, 1, 'Document deletion OK');
		say Dumper($data);
	}
};

done_testing();