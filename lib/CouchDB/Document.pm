package CouchDB::Document;

=head1 NAME
CouchDB::Document;
=cut

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Carp qw(confess);
use CouchDB::Request;
use Data::Dumper;
use Moo;

has _id => ( is => 'rw' );
has _rev => ( is => 'rw' );
has content => ( is => 'rw' );
has debug => (is => 'rw', default => sub { return 0} );
has db => ( is => 'rw', isa => sub { confess "CouchDB::Database required" unless ref $_[0] eq 'CouchDB::Database' }, required => 1 );

before 'put' => \&_check_id;
before 'get' => \&_check_id;
before 'delete' => \&_check_id;
before 'doc_uri' => \&_check_id;

sub get {
	my $self = shift;
	my $request = CouchDB::Request->new(uri => $self->doc_uri, debug => $self->debug, method => 'get');
	my $response = $request->execute;
	return $self->_update($response) if _response_ok($response,200);
	$request->complain($response);
}


sub doc_uri {
	my $self = shift;
	my $uri = $self->db->db_uri.$self->_id;
	$uri .= '?rev='.$self->_rev if defined $self->_rev;
	return $uri; 
}

#store a doc in couchdb with _id defined
sub put {
	my $self = shift; 
	my $request = CouchDB::Request->new(uri => $self->doc_uri, debug => $self->debug, method => 'put', content => $self->content);
	my $response = $request->execute;
	return $self->_update($response) if _response_ok($response,201);
	$request->complain($response);
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post {
	my $self = shift;
	my $request = CouchDB::Request->new(uri => $self->db->db_uri, debug => $self->debug, method => 'post', content => $self->content);
	my $response = $request->execute;
	return $self->_update($response) if _response_ok($response,201);
	$request->complain($response);
}

sub delete {
	my $self = shift;
	
	my $request = CouchDB::Request->new(uri => $self->doc_uri, debug => $self->debug, method => 'delete');
	my $response = $request->execute;
	return $self->_update($response) if _response_ok($response,200);
	$request->complain($response);
}

sub _update {
	my ($self,$response) = @_;
	if (defined $response->json) {
		$self->content($response->json);
		$self->_set_id;
		$self->_set_rev;
	}
	return $self;
}

sub _response_ok {
	my ($response,$expected) = @_;
	return 1 if (defined $response->code && $response->code == $expected);
	return 0; 
}

sub _set_id {
	my $self = shift;
	$self->_id($self->content->{id}) if defined $self->content->{id};
	$self->_id($self->content->{_id}) if defined $self->content->{_id};
}

sub _set_rev {
	my $self = shift;
	$self->_rev($self->content->{rev}) if defined $self->content->{rev};
	$self->_rev($self->content->{_rev}) if defined $self->content->{_rev};
}

sub _check_id {
	$_[0]->_id($_[1]) if defined $_[1];
	confess "_id required.\n" unless defined $_[0]->_id;
}

1;
