package  Load::Command::couch;

=head1 NAME
Load::Command::couch;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::CouchDB qw(couch_exists);
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
	[ "uri|u=s",	"CouchDB URI", { required => 1} ],
	[ "delete|D",	"Delete file(s), if loaded successfully"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	my $couch = Common::CouchDB->new;
	unless ($couch->exists($opt->{uri})) {
		die "A connection to $opt->{uri} could not be established. Check that the provided URI is correct.\nAlso check network connection / proxy settings.\n";
	}	
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $count = 0;
	
#	opendir my $dir, $opt->{csvdir} || die "Could not open $opt->{csvdir} for reading: $!\n";
#	while (my $file = readdir $dir) {
#		next unless -s $opt->{csvdir}.'/'.$file;	#only consider files with non-zero size
#		
#		for my $plugin (plugins()) { 
#			if ( $plugin->can('recognize') && $plugin->recognize($opt->{csvdir},$file) ) {
#				print "$file was recognized by $plugin\n";
#			}
#		}
#		 
#		 
#	}
#	closedir $dir;
#	if ($count == 0) {
#		warn "No files could be loaded from \"$opt->{csvdir}\" !\n";
#	}
}



1;
