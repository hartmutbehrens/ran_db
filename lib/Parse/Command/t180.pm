package Parse::Command::t180;

=head1 NAME
Parse::Command::t180;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::ALU::Parse2G;
use Common::CSV;
use Common::Lock;
use Common::XML;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse t180 (handover) binary performance management files from Alcatel-Lucent OMC-R into csv files";
}

sub usage_desc {
	return "%c t180 %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "omc|o=s",	"OMC-R name", { required => 1 }],
	[ "delete|D",	"Delete file(s) after parsing"],
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
	
	my $lock = '.'.$opt->{omc}.'t180';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	for my $pmfile (@$args) {
		
		my $info = Common::ALU::Parse2G::alu_pm_info($pmfile);
		my ($pm,$counters) = Common::ALU::Parse2G::decode_t180($pmfile);
		warn "Warning: No data was retrieved after parsing $pmfile. This may not be a problem but should be investigated."	unless (scalar(keys %$counters) > 0);
	
		my $success = Common::CSV::to_csv($pm,$counters,$info,$opt->{omc},'t180',$opt->{outdir});
		if ($success && $opt->{delete}) {
			print "Deleting: $pmfile (-D command line option was provided)\n";
			unlink($pmfile);
		}
	}
}

1;
