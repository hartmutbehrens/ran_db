package CouchDB::Request;

=head1 NAME
CouchDB::Request;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use Data::Dumper;
use Moo;
use Mojo::UserAgent;

has ua => ( is => 'rw', default => sub { return Mojo::UserAgent->new->detect_proxy->connect_timeout(5) } );
has uri => ( is => 'rw', required => 1 );
has max_retry => ( is => 'rw', default => sub { return 2 } );


sub _do {
	my ($self,$method) = @_;
	my $count = 0;
	my $response = $self->ua->$method($self->uri => {'Cache-Control' => 'no-cache'} )->res;
	
	while ( ! defined $response->code ) {
		$count++;
		last if $count > $self->max_retry;
		$response = $self->ua->$method($self->uri => {'Cache-Control' => 'no-cache'} )->res;
	} 
	return $response;
}

sub get {
	my $self = shift;
	return $self->_do('get');
}

sub put {
	my $self = shift;
	return $self->_do('put');
}

sub post {
	my $self = shift;
	return $self->_do('post');
}

sub delete {
	my $self = shift;
	return $self->_do('delete');
}

1;