package CouchDB::Connector;

=head1 NAME
CouchDB::Connector;
=cut

#pragmas
use strict;
use warnings;

#modules
#modules
use Carp qw(confess);
use CouchDB::Request;
use Moo;

has uri => ( is => 'rw', isa => \&connected, required => 1 );

before 'uri' => sub { $_[0]->{uri} .= '/' unless $_[0]->{uri} =~ m{/$}; };

sub connected {
	my $request = CouchDB::Request->new(uri => $_[0], method => 'get');
	my $response = $request->execute;
	return 1 if (defined $response->code) && ($response->code == 200);
	$request->complain($response);
}



1;