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

extends 'CouchDB::Connector';

has 'name' => (is => 'rw', required => 1);
has debug => (is => 'rw', isa => sub { confess "Only 0 or 1 allowed." unless ($_[0] == 0) || ($_[0] == 1) } );

sub all_dbs {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->uri.'_all_dbs', debug => $self->debug)->get;
	return $response->json if defined $response->json;
	confess "A response was not received from _all_dbs.\n";
}

sub has_db {
	my $self = shift;
	return (grep { $_ eq $self->name } @{$self->all_dbs()}) ? 1 : 0;
}

sub create_db {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->db_uri(), debug => $self->debug)->put;
	
	if (defined $response->code) {
		return 1 if $response->code == 201;
		confess "Database could not be created. Response code was: \"",$response->code,"\".\n";
	}
	confess "Database could not be created. Message was: \"",$response->message,"\".\n";	
}

sub del_db {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->db_uri(), debug => $self->debug)->delete;
	if (defined $response->code) {
		return 1 if $response->code == 200;
		confess "Database could not be deleted. Response code was: \"",$response->code,"\".\n";
	}
	confess "Database could not be deleted. Message was: \"",$response->message,"\".\n";
}

sub db_uri {
	my $self = shift;
	return $self->uri.$self->name.'/'; 
}

sub new_doc {
	my ($self,$id) = @_;
	return CouchDB::Document->new(id => $id, db => $self);
}


1;
