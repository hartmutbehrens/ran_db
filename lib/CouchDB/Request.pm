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
has method => ( is => 'rw', required => 1 );
has content => ( is => 'rw' );
has debug => (is => 'rw', default => sub { return 0} );
has ua => ( is => 'rw', default => sub { return Mojo::UserAgent->new->detect_proxy->connect_timeout(5) } );
has headers => (is => 'rw', default => sub { return { 'Cache-Control' => 'no-cache' } } );
has json => ( is => 'rw', default => sub { return Mojo::JSON->new } );
has max_retry => ( is => 'rw', default => sub { return 2 } );


sub execute {
	my $self = shift;
	my ($count,$response) = (0,undef);
	my $method = $self->method;
	my $content = $self->content;
	 
	if (ref $content) {	
        $content = $self->json->encode($content);
        $self->headers({ 'Cache-Control' => 'no-cache', 'Content-Type' => 'application/json' });
    }
	say uc($self->method), " : ", $self->uri if $self->debug;
	
	while ( $response = $self->ua->$method($self->uri => $self->headers => $content )->res ) {
		$count++;
		last if (defined $response->code) || ($count > $self->max_retry);
	}
	
	say "Response : ", $response->code if $self->debug && defined $response->code;
	return $response;
}

sub complain {
	my ($self,$response) = @_;
	say "Response code was: \"",$response->code,"\ (",$response->message,")" if defined $response->code;
	say "Message was: \"",$response->message,"\"." if defined $response->message;
	say "Error was: \"",$response->error,"\"." if defined $response->error;
	confess uc($self->method)," ",$self->uri," could not be completed.";
}

1;