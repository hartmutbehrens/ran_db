package Fetch::Command::cloud_xml;

=head1 NAME
Fetch::Command::cloud_xml
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
	return 'fetch xml office and date files from ALU cloud log server';
}

sub usage_desc {
	return "%c cloud_xml %o";
}

sub opt_spec {
	return (
	[ "url|f=s",	"Specify URL", { required => 1}],
    [ "parameter|p=s@", "Specify URL parameter (repeat as required)"],
    [ "log|l=s", 	"log directory", { default => '../xmllog'}],
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
	my $office = $today.'.'.$lock.'.xml';
	unless (-e "$opt->{log}/$office") {
		my $response = getstore($opt->{url},"$opt->{log}/$office");
		if ($response != HTTP_OK) {
			warn "Could not retrieve $opt->{url}. Error: ",status_message($response),"\n"
		}
	}
}

1;