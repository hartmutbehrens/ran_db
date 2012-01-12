package CouchDB::Database;

=head1 NAME
CouchDB::Database;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use CouchDB::Request;
use CouchDB::Document;
use Moo;
use Try::Tiny;

extends 'CouchDB::Connector';

has 'name' => (is => 'rw', required => 1);
has debug => (is => 'rw', default => sub { return 0} );

sub all_dbs {
	my $self = shift;
	my $request = CouchDB::Request->new(uri => $self->uri.'_all_dbs', debug => $self->debug, method => 'get');
	my $response = $request->execute;
	return $response->json if defined $response->json;
	$request->complain($response);
}

sub has_db {
	my $self = shift;
	return (grep { $_ eq $self->name } @{$self->all_dbs()}) ? 1 : 0;
}

sub create_db {
	my $self = shift;
	my $request = CouchDB::Request->new(uri => $self->db_uri, debug => $self->debug, method => 'put');
	my $response = $request->execute;
	return $self if $response->code == 201;
	$request->complain($response);	
}

sub del_db {
	my $self = shift;
	my $request = CouchDB::Request->new(uri => $self->db_uri, debug => $self->debug, method => 'delete');
	my $response = $request->execute;
	return $self if $response->code == 200;
	$request->complain($response);
}

sub db_uri {
	my $self = shift;
	return $self->uri.$self->name.'/'; 
}

sub new_doc {
	my ($self,$id,$content) = @_;
	#confess "id required.\n" unless defined $id;
	return $self->get_doc($id)  || CouchDB::Document->new(_id => $id, db => $self, content => $content, debug => $self->debug); 
}

sub exists_doc {
	my ($self,$id) = @_;
	return 1 if $self->get_doc($id);
	return 0;
}

sub get_doc {
	my ($self,$id) = @_;
	my $doc = CouchDB::Document->new(_id => $id, db => $self, debug => $self->debug);
	my $rv = undef;
	try {
		$rv = $doc->get;
	};
	return $rv;
}

sub delete_doc {
	my ($self,$id) = @_;
	my $doc = $self->get_doc($id);
	$doc->delete if $doc;
}

1;
