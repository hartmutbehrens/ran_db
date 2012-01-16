package CouchDB::Database;

=head1 NAME
CouchDB::Database;
=cut

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Carp qw(confess);
use CouchDB::Request;
use CouchDB::Document;
use Data::Dumper;
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

sub _fetch {
	my ($self,$ids,$path) = @_; 
	confess "An arrray reference is expected" unless ref $ids eq 'ARRAY';
	
	my $request = CouchDB::Request->new(uri => $self->db_uri.$path, content => {'keys' => $ids}, debug => $self->debug, method => 'post');
	my $response = $request->execute;
	return $response->json if $response->code == 200;
	$request->complain($response);
}

sub get_multiple {
	my ($self,$ids,$params) = @_;
	return $self->_fetch($ids,'_all_docs'.$self->par_to_string($params));
}

sub get_multiple_with_doc {
	my ($self,$ids,$params) = @_;
	return $self->_fetch($ids,'_all_docs?include_docs=true'.$self->par_to_string($params));
}

sub update {
	my ($self,$docs) = @_;
	$self->insert($docs);
}

sub insert {
	my ($self,$docs) = @_;
	confess "An arrray reference is expected" unless ref $docs eq 'ARRAY';
	$self->_get_rev($docs);
	my $request = CouchDB::Request->new(uri => $self->db_uri.'_bulk_docs', content => {'docs' => $docs}, debug => $self->debug, method => 'post');
	my $response = $request->execute;
	return $response->json if $response->code == 201;
	$request->complain($response);
}

sub par_to_string {
	my ($self,$params) = @_;
	my $string = defined $params ? '&'.join( '&' ,map($_.'="'.$params->{$_}."'" ,keys %$params)) : '';
	return $string;
}

#get revision, if one is available
sub _get_rev {
	my ($self,$docs) = @_;
	my %index;
	for my $i (0..$#$docs) {
		$index{$docs->[$i]->{_id}} = $i if defined $docs->[$i]->{_id};	#some docs may not have _id defined (POST request to Couch will assign _id)
	}
	my $ids = $self->get_multiple( [keys %index] );
	for my $id (@{$ids->{rows}}) {
		next unless defined $id->{value};
		$docs->[$index{$id->{id}}]->{_rev} = $id->{value}->{rev};	
	}
}

sub new_doc {
	my ($self,$id,$content) = @_;
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
