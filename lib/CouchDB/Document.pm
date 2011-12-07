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
use Data::Dumper;
use Moo;

has id => ( is => 'rw');
has rev => (is => 'rw');
has debug => (is => 'rw', isa => sub { confess "Only 0 or 1 allowed." unless ($_[0] == 0) || ($_[0] == 1) } );
has db => ( is => 'rw', isa => sub { confess "CouchDB::Database required" unless ref $_[0] eq 'CouchDB::Database' }, required => 1 );


before 'put' => \&_check_put;

sub get {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->db->db_uri().$self->id, debug => $self->debug)->get;
	print "code : ",$response->code,"\n";
	return $response->json if defined $response->json;
	confess "A response was not received when getting doc \"$self->id\".\n";
}

sub head {
	
}

#store a doc in couchdb with _id defined
sub put {
	my ($self,$doc) = @_;
	my $response = CouchDB::Request->new(uri => $self->uri.$self->id, debug => $self->debug)->put($doc);
	return 1 if (defined $response->code) && ($response->code == 201);
	confess "The document \"",$self->id,"\" already exists.\nCheck that the correct _rev was specified.\n" if (defined $response->code) && ($response->code == 409);
	confess "The document \"",$self->id,"\" could not be PUT. The response was: \"",$response->message,"\"\n";
	
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post {
	
}

sub delete {
	
}

sub _check_put {
	confess "Doc parameter has not been provided for PUT.\n" unless defined $_[1];
}

1;
