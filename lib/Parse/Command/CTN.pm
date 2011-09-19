package Parse::Command::CTN;

=head1 NAME
Parse::Command::CTN;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::ALU::Parse3G;
use Common::CSV;
use Common::Lock;
use Common::XML;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse CTN (neighbour call trace) files from Alcatel-Lucent WNMS into csv files";
}

sub usage_desc {
	return "%c CTN %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "table|t=s", "table name", {hidden => 1, default => 'TRACE_CTN'}],
	[ "wnms|o=s",	"WNMS name", { required => 1 }],
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
	my $lock = '.'.$opt->{omc}.'CTN';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	
	for my $file (@$args) {
		
		my ($trace,$cols,$info) = Common::ALU::Parse3G::parse_3GCT($file,$opt->{table});
		warn "Warning: No data was retrieved after parsing $file. This should be investigated."	unless (scalar(keys %$cols) > 0);
	
		my $success = Common::CSV::to_csv($trace,$cols,$info,$opt->{omc},'CTN',$opt->{outdir});
		if ($success && $opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($file);
		}
	}
}

1;
