package CouchDB::Document;

=head1 NAME
CouchDB::Document;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use CouchDB::Request;
use Moo;
use Mojo::JSON;

extends 'CouchDB::Database';

has json => ( is => 'rw', default => sub { return Mojo::JSON->new } );

#before 'put' => \&_check_put;

sub get {
	
}

sub head {
	
}

#store a doc in couchdb with _id defined
sub put {
	my ($self,$doc) = @_;
	my $headers = { 'Cache-Control' => 'no-cache', 'Content-Type' => 'application/json' };
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post {
	
}

sub delete {
	
}

sub _check_put {
	confess "A _id field is required to PUT documents.\n" unless defined $_[1]->{_id};
}


1;
