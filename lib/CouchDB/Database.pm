package CouchDB::Database;

=head1 NAME
CouchDB::Database;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use CouchDB::Request;
use Moo;

has uri => ( is => 'rw', isa => \&connected, required => 1 );

before 'uri' => sub { _add_slash($_[0]->{uri}) };
before 'create_db' => \&_check_name;
before 'del_db' => \&_check_name;

sub connected {
	my $response = CouchDB::Request->new(uri => $_[0])->get;
	return 1 if (defined $response->code) && ($response->code == 200);
	confess "A connection to $_[0] could not be established.\n";
}

sub all_dbs {
	my $self = shift;
	my $response = CouchDB::Request->new(uri => $self->uri.'_all_dbs')->get;
	return $response->json if defined $response->json;
	confess "A response was not received from _all_dbs.\n";
}

sub has_db {
	my ($self,$name) = @_;
	confess "A database name is required.\n" unless defined $name;
	return (grep { $_ eq $name } @{$self->all_dbs()}) ? 1 : 0;
}

sub create_db {
	my ($self,$name) = @_;
	my $response = CouchDB::Request->new(uri => $self->uri.$name)->put;
	return 1 if (defined $response->code) && ($response->code == 201);
	confess "Database $name could not be created. Expected response code 201 was not received.\n";	
}

sub del_db {
	my ($self,$name) = @_;
	my $response = CouchDB::Request->new(uri => $self->uri.$name)->delete;
	return 1 if (defined $response->code) && ($response->code == 200);
	confess "Database $name could not be created. Expected response code 200 was not received.\n";
}

sub _check_name {
	confess "A database name is required.\n" unless defined $_[1];
	_add_slash($_[1]);
}

sub _add_slash {
	$_[0] .= '/' unless $_[0] =~ m{/$};
}

1;
