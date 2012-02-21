package Parse::Command::gpm;

=head1 NAME
Parse::Command::gpm;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::ALU::Parse::2G;
use Common::CSV;
use Common::Lock;
use Common::XML;
use File::Path qw(make_path);
use Parallel::ForkManager; 
use Parse -command;

sub abstract {
	return "parse gpm (E/GPRS) performance management files from Alcatel-Lucent OMC-R into csv files";
}

sub usage_desc {
	return "%c gpm %o [ filename(s) ]";
}

sub opt_spec {
	
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "templatedir|t=s",	"directory containing xml templates for decoding pm file", { default => "../templates" }],
	[ "omc|o=s",	"OMC-R name", { required => 1 }],
	[ "delete|D",	"Delete file(s) after parsing"],
	[ "parallel|P=s", 	"number of files to process in parallel (default = $np) ", { default => 4}],	
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;	
	$self->usage_error("At least one file name is required") unless @$args;
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}
	make_path($opt->{outdir}, { verbose => 1 });
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	my $lock = '.'.$opt->{omc}.'gpm';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	
	my $pfm = Parallel::ForkManager->new($opt->{parallel});
	for my $pmfile (@$args) {
		$pfm->start and next; # do the fork
		
		my ($pm,$counters,$info) = Common::ALU::Parse::2G::parse_gpm($pmfile,$opt->{templatedir});
		warn "Warning: No data was retrieved after parsing $pmfile. This may not be a problem but should be investigated."	unless (scalar(keys %$counters) > 0);
	
		my $success = Common::CSV::to_csv($pm,$counters,$info,$opt->{omc},'gpm',$opt->{outdir});
		if ($opt->{delete}) {
			print "Deleting: $pmfile (-D command line option was provided)\n";
			unlink($pmfile);
		}
		$pfm->finish; # do the exit in the child process
		
	}
	$pfm->wait_all_children;
}

1;
