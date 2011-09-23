package Fetch::Command::http;

=head1 NAME
Fetch::Command::http
=cut

#pragmas
use strict;
use warnings;
#modules
use Common::Lock;
use Common::Date;
use Data::Dumper;
use Digest::SHA1 qw(sha1);
use Fetch -command;
use File::Path qw(make_path);
use HTTP::Status qw(:constants :is status_message);
use LWP::Simple;

sub abstract {
	return 'fetch documents via http';
}

sub usage_desc {
	return "%c http %o";
}

sub opt_spec {
	return (
	[ "url|u=s",	"Specify URL", { required => 1}],
    [ "parameter|p=s@", "Specify URL parameter (repeat as required)"],
    [ "filename|f=s@", "Specify file name to store retrieved document in"],
    [ "log|l=s", 	"log directory", { default => '../httplog'}],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	$self->usage_error("No arguments allowed") if @$args;
	make_path($opt->{log}, { verbose => 1 });
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	my $today = Common::Date::today();
	
	my $param = join('&',@{$opt->{parameter}});
	my $lock = $param;
	$lock =~ s/\W+//g;
	Common::Lock::get_lock('.'.$lock) || Common::Lock::bail('.'.$lock);
	
	my $response = getstore($opt->{url},"$opt->{log}/$opt->{filename}");
	if ($response != HTTP_OK) {
		warn "Could not retrieve $opt->{url}. Error: ",status_message($response),"\n"
	}
	
}

1;