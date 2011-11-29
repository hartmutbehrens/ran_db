package Common::CouchDB;

=head1 NAME
Common::CouchDB;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use Mojo::UserAgent;

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub exists {
	my ($self,$uri) = @_;
	my $ua = Mojo::UserAgent->new;
	$ua->detect_proxy;
	my $response = $ua->get($uri)->res;
	return (defined $response->code) && ($response->code == 200) ? 1 : 0;
}

1;
