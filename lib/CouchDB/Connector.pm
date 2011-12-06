package CouchDB::Connector;

=head1 NAME
CouchDB::Connector;
=cut

#pragmas
use strict;
use warnings;

#modules
use Carp qw(confess);
use CouchDB::Request;
use Data::Dumper;
use Moo;

has uri => ( is => 'rw', isa => \&connected, required => 1 );

before 'uri' => sub {
	$_[0]->{uri} .= '/' unless $_[0]->{uri} =~ m{/$};
};

before 'create_db' => \&_name_check;
before 'del_db' => \&_name_check;

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
	confess "Database $name could not be created. Response code 201 was not received.\n";	
}

sub del_db {
	my ($self,$name) = @_;
	my $response = CouchDB::Request->new(uri => $self->uri.$name)->delete;
	return 1 if (defined $response->code) && ($response->code == 200);
	confess "Database $name could not be created. Response code 200 was not received.\n";
}

sub _name_check {
	confess "A database name is required.\n" unless defined $_[1];
	$_[1] .= '/' unless $_[1] =~ m{/$};
}

sub get_doc {
	
}

sub doc_head {
	
}

#store a doc in couchdb with _id defined
sub put_doc {
	
}

#store a doc in couchdb and let couchdb come up with a unique id
sub post_doc {
	
}

sub delete_doc {
	
}


1;
