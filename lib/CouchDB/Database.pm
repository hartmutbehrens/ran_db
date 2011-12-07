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
has debug => (is => 'rw', default => sub { return 0} );

sub all_dbs {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->uri.'_all_dbs', debug => $self->debug)->get;
	return $response->json if defined $response->json;
	_complain($self->uri.'_all_dbs',$response,'get');
}

sub has_db {
	my $self = shift;
	return (grep { $_ eq $self->name } @{$self->all_dbs()}) ? 1 : 0;
}

sub create_db {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->db_uri, debug => $self->debug)->put;
	
	return 1 if $response->code == 201;
	_complain($self->db_uri,$response,'put');	
}

sub del_db {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->db_uri, debug => $self->debug)->delete;
	
	return 1 if $response->code == 200;
	_complain($self->db_uri,$response,'delete');
}

sub db_uri {
	my $self = shift;
	return $self->uri.$self->name.'/'; 
}

sub new_doc {
	my ($self,$id) = @_;
	return CouchDB::Document->new(id => $id, db => $self);
}

sub _complain {
	my ($uri,$response,$method) = @_;
	if (defined $response->code) {
		confess uc($method)," $uri could not be completed. Response code was: \"",$response->code,"\".\n";
	}
	confess uc($method)," $uri could not be completed. Message was: \"",$response->message,"\".\n";
}


1;
