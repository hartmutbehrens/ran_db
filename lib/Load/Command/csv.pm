package  Load::Command::csv;

=head1 NAME
Load::Command::csv;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::MySQL;
use Common::CSV;
use Load -command;

sub abstract {
	return "load CSV files into a DB";
}

sub usage_desc {
	return "%c csv %o";
}

sub opt_spec {
	return (
	[ "csvdir|c=s",	"directory to load csv files from", { default => "../csvload" }],
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "nms|n=s",	"load files from this OMC-R or WNMS name (will be used to match against csv file name)", { required => 1 }],
	[ "type|t=s",	"file type to be loaded (will be used to match against csv file name) - e.g. t110,RNCCN..", { required => 1 }],
	[ "config|C=s",	"file describing csv record separator, etc", { hidden => 1, default => '../etc/csvload.xml' }],
	[ "delete|D",	"Delete file(s) after parsing"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	unless (-e $opt->{config}) {
		die "The file \"$opt->{config}\", which describes how to load csv files of type \"$opt->{type}\" is not present!\n";
	}	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $count = 0;
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	opendir my $dir, $opt->{csvdir} || die "Could not open $opt->{csvdir} for reading: $!\n";
	while (my $file = readdir $dir) {
		next unless ($file =~ /$opt->{nms}/) && ($file =~ /$opt->{type}/);
		print "About to load: $file\n";
		 my $success = Common::CSV::load_csv($dbh,$opt->{csvdir},$file,$opt->{config});
		 $count++ if $success;
		 if ($success && $opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($opt->{csvdir}.'/'.$file);
		}
	}
	if ($count == 0) {
		warn "No files of type \"$opt->{type}\" from \"$opt->{nms}\" could be found in \"$opt->{csvdir}\" !\n";
	}
}

1;
