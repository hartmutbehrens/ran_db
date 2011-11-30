package Common::CouchDB;

=head1 NAME
Common::CouchDB;
=cut

#pragmas
use strict;
use warnings;

#modules
use Data::Dumper;
use Moo;
use Mojo::UserAgent;

has ua => ( is => 'rw', default => sub { return Mojo::UserAgent->new->detect_proxy } );
has uri => ( is => 'rw', required => 1 );


sub exists {
	my $self = shift;
	my $response = $self->_get($self->uri)->res;
	return (defined $response->code) && ($response->code == 200) ? 1 : 0;
}

sub _get {
	my ($self,$uri) = @_;
	return $self->{ua}->get($uri);
}

sub all_dbs {
	my $self = shift;
	my $response = $self->_get($self->uri.'_all_dbs')->res;
	return (defined $response->code) && ($response->code == 200) ? $response->json : undef;
}

1;
