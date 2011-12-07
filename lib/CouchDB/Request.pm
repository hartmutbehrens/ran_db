package CouchDB::Request;

=head1 NAME
CouchDB::Request;
=cut

#pragmas
use strict;
use warnings;
use feature qw(say);

#modules
use Carp qw(confess);
use Data::Dumper;
use Moo;
use Mojo::JSON;
use Mojo::UserAgent;

has uri => ( is => 'rw', required => 1 );
has debug => (is => 'rw', isa => sub { confess "Only 0 or 1 allowed." unless ($_[0] == 0) || ($_[0] == 1) } );
has ua => ( is => 'rw', default => sub { return Mojo::UserAgent->new->detect_proxy->connect_timeout(5) } );
has headers => (is => 'rw', default => sub { return { 'Cache-Control' => 'no-cache' } } );
has json => ( is => 'rw', default => sub { return Mojo::JSON->new } );
has max_retry => ( is => 'rw', default => sub { return 2 } );


sub _do {
	my ($self,$method,$content) = @_;
	my ($count,$response) = (0,undef);
	 
	if (ref $content) {	
        $content = $self->json->encode($content);
        $self->headers({ 'Cache-Control' => 'no-cache', 'Content-Type' => 'application/json' });
    }
	say uc($method), " : ", $self->uri,"\n" if $self->debug;
	
	while ( $response = $self->ua->$method($self->uri => $self->headers => $content )->res ) {
		$count++;
		last if (defined $response->code) || ($count > $self->max_retry);
	} 
	return $response;
}

sub get {
	my $self = shift;
	return $self->_do('get');
}

sub put {
	my ($self,$content) = @_;
	return $self->_do('put',$content);
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