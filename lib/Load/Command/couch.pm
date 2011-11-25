package  Load::Command::couch;

=head1 NAME
Load::Command::couch;
=cut
#pragmas
use strict;
use warnings;

#modules

use Load -command;
use Module::Pluggable search_path => ['Plugin::Load::CouchDB'], require => 1;

sub abstract {
	return "load CSV files into a CouchDB";
}

sub usage_desc {
	return "%c couch %o";
}

sub opt_spec {
	return (
	[ "csvdir|c=s",	"directory to load csv files from", { default => "../csvload" }],
	[ "user|u=s",	"user"],
	[ "pass|p=s",	"password"],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 5984 }],
	[ "delete|D",	"Delete file(s), if loaded successfully"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
			
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $count = 0;
	
	opendir my $dir, $opt->{csvdir} || die "Could not open $opt->{csvdir} for reading: $!\n";
	while (my $file = readdir $dir) {
		next unless -s $opt->{csvdir}.'/'.$file;	#only consider files with non-zero size
		
		for my $plugin (plugins()) { 
			if ( $plugin->can('recognize') && $plugin->recognize($opt->{csvdir},$file) ) {
				print "$file was recognized by $plugin\n";
			}
		}
		 
		 
	}
	closedir $dir;
	if ($count == 0) {
		warn "No files could be loaded from \"$opt->{csvdir}\" !\n";
	}
}



1;
