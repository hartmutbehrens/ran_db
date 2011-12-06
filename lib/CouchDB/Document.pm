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

before 'get' => \&_check_for_id;
before 'put' => \&_check_for_id;

sub get {
	my ($self,$id) = @_;
	my $headers = { 'Cache-Control' => 'no-cache', 'Content-Type' => 'application/json' };
	my $response = CouchDB::Request->new(uri => $self->uri.$id, headers => $headers)->get;
	return $response->json if defined $response->json;
	confess "A response was not received when getting doc $id.\n";
	
}

sub head {
	
}

#store a doc in couchdb with _id defined
sub put {
	my ($self,$id,$doc) = @_;
	my $headers = { 'Cache-Control' => 'no-cache', 'Content-Type' => 'application/json' };
	my $response = CouchDB::Request->new(uri => $self->uri.$id, headers => $headers)->put;
	return 1 if (defined $response->code) && ($response->code == 201);
	confess "The document $id already exists.\nCheck that the correct _rev was specified.\n" if (defined $response->code) && ($response->code == 409);
	confess "The document $id could not be PUT.\n";
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post {
	
}

sub delete {
	
}

sub _check_for_id {
	confess "A _id field is required.\n" unless defined $_[1];
}


1;
