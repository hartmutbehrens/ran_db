package MakeIt::Command::tables;

=head1 NAME
MakeIt::Command::tables;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::MakeIt;
use Common::MySQL;
use Common::XML;
use MakeIt -command;

sub abstract {
	return "make database tables from xml templates.";
}

sub usage_desc {
	return "%c tables %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name in which tables will be created", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "drop|D",	"Drop any existing tables, if they exist"],
	[ "driver=s",	"database driver (default mysql)", { default => "mysql" }],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	$self->usage_error("At least one table template file name is required") unless @$args;
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $conn = Common::MySQL::get_connection(@{$opt}{qw/user pass host port db driver/});
	die "Could not get a database connection\n" unless defined $conn;
	my $dbh = $conn->dbh;
	for my $template (@$args) {
		my $mk = Common::XML::read_xml($template);
		Common::MakeIt::make_table($mk,$dbh,undef,$opt->{drop});	
	}
}



1;
