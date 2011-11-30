package Common::CouchDB;

=head1 NAME
Common::CouchDB;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use Data::Dumper;
use Moo;
use Mojo::UserAgent;

has ua => ( is => 'rw', default => sub { return Mojo::UserAgent->new->detect_proxy } );
has uri => ( is => 'rw', required => 1 );


sub exists {
	my $self = shift;
	my $response = $self->_get($self->uri)->res;
	return 1 if (defined $response->code) && ($response->code == 200);
	if (defined $response) {
		confess "A connection to ",$self->uri," could not be established. (The error was: ",$response->error,")\n";
	}
	else {
		confess "A connection to ",$self->uri," could not be established. No response was received\n";	
	}
}

sub _get {
	my ($self,$uri) = @_;
	return $self->_request('get',$uri);
}

sub _put {
	my ($self,$uri) = @_;
	return $self->_request('put',$uri);
}

sub _delete {
	my ($self,$uri) = @_;
	return $self->_request('delete',$uri);
}

sub _request {
	my ($self,$method,$uri) = @_;
	return $self->{ua}->$method($uri => {'Cache-Control' => 'no-cache'} );
}

sub all_dbs {
	my $self = shift;
	my $response = $self->_get($self->uri.'_all_dbs')->res;
	return (defined $response->json) ? $response->json : undef;
}

sub has_db {
	my ($self,$name) = @_;
	return (grep { $_ eq $name } @{$self->all_dbs()}) ? 1 : 0;
}

sub new_db {
	my ($self,$name) = @_;
	$name .= '/' unless $name =~ m{/$};
	my $response = $self->_put($self->uri.$name)->res;
	return 1 if (defined $response->code) && ($response->code == 201);
	confess "Database $name could not be created. The response was \"",$response->json->{reason},"\" (HTTP code ",$response->code,")\n";	
}

sub del_db {
	my ($self,$name) = @_;
	$name .= '/' unless $name =~ m{/$};
	my $response = $self->_delete($self->uri.$name)->res;
	return 1 if (defined $response->code) && ($response->code == 200);
	confess "Database $name could not be created. The response was \"",$response->json->{reason},"\" (HTTP code ",$response->code,")\n";
}

sub db_name_ok {
	my ($self,$name) = @_;
	return 0 if $name =~ /[A-Z]/;
}

1;
