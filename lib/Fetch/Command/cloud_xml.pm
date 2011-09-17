package Fetch::Command::cloud_xml;

=head1 NAME
Fetch::Command::alucloud
=cut

#pragmas
use strict;
use warnings;
#modules
use Common::Lock;
use Common::Date;
use Fetch -command;
use File::Path qw(make_path);

sub abstract {
	return 'fetch xml office and date files from ALU cloud log server';
}

sub usage_desc {
	return "%c cloud_xml %o";
}

sub opt_spec {
	return (
	[ "url|f=s",	"Cloud URL", { required => 1}],
    [ "country|c=s", 	"Specify country", { required => 1}],
    [ "customer|u=s", 	"Specify customer", { required => 1}],
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
	my $lock = '.'.$opt->{country}.$opt->customer;
	Common::Lock::get_lock($lock);
	
	my $office = join('_',$opt->{country},$opt->{customer},$today).'.xml';
	unless (-e "$opt->{log}/$office") {
		
	}
	
}

1;