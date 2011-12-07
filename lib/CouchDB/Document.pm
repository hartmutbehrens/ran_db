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
has debug => (is => 'rw', default => sub { return 0} );
has db => ( is => 'rw', isa => sub { confess "CouchDB::Database required" unless ref $_[0] eq 'CouchDB::Database' }, required => 1 );

before 'put' => \&_check_put;

sub get {
	my $self = shift;
	my $uri = $self->db->db_uri.$self->id;
	my $response = CouchDB::Request->new(uri => $uri, debug => $self->debug)->get;
	
	return $response->json if defined $response->json && $response->code == 200;
	_complain($uri,$response,'get');
}

sub head {
	
}

#store a doc in couchdb with _id defined
sub put {
	my ($self,$doc) = @_;
	my $uri = $self->db->db_uri.$self->id;
	my $response = CouchDB::Request->new(uri => $uri, debug => $self->debug)->put($doc);
	return 1 if (defined $response->code) && ($response->code == 201);
	_complain($uri,$response,'put');
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post {
	
}

sub delete {
	
}

sub _check_put {
	confess "Doc parameter has not been provided for PUT.\n" unless defined $_[1];
}

sub _complain {
	my ($uri,$response,$method) = @_;
	if (defined $response->code) {
		confess uc($method)," $uri could not be completed. Response code was: \"",$response->code,"\".\n";
	}
	confess uc($method)," $uri could not be completed. Message was: \"",$response->message,"\".\n";
}

1;
