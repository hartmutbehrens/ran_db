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

has _id => ( is => 'rw' );
has _rev => ( is => 'rw' );
has debug => (is => 'rw', default => sub { return 0} );
has db => ( is => 'rw', isa => sub { confess "CouchDB::Database required" unless ref $_[0] eq 'CouchDB::Database' }, required => 1 );

before 'put' => \&_check_put;
before 'get' => \&_get_id_rev;
before 'doc_uri' => \&_get_id_rev;

sub get {
	my $self = shift;
	 
	my $request = CouchDB::Request->new(uri => $self->doc_uri, debug => $self->debug, method => 'get');
	my $response = $request->execute;
	if (defined $response->json && $response->code == 200) {
		$self->_rev($response->json->{_rev});
		return $response->json;
	}
	$request->complain($response);
}


sub rev {
	my ($self,$id) = @_;
	return $self->_rev if defined $self->_rev;
	$self->_id($id) if defined $id;
	$self->get; 
	return $self->_rev;
}

sub doc_uri {
	my $self = shift;
	my $uri = $self->db->db_uri.$self->_id;
	$uri .= '?rev='.$self->_rev if defined $self->_rev;
	return $uri; 
}



#store a doc in couchdb with _id defined
sub put {
	my ($self,$doc,$id) = @_;
	$self->_id($id) if defined $id;
	confess "_id required for PUT.\n" unless defined $self->_id; 
	my $request = CouchDB::Request->new(uri => $self->doc_uri, debug => $self->debug, method => 'put');
	my $response = $request->execute;
	return 1 if (defined $response->code) && ($response->code == 201);
	$request->complain($response);
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post {
	
}

sub delete {
	
}

sub _check_put {
	confess "Doc parameter has not been provided for PUT.\n" unless defined $_[1];
}

sub _get_id_rev {
	$_[0]->_id($_[1]) if defined $_[1];
	$_[0]->_rev($_[2]) if defined $_[2];
	confess "_id required.\n" unless defined $_[0]->_id;
}

1;
