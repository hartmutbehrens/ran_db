package Parse::Command::alu3gpm;

=head1 NAME
Parse::Command::alu3gpm;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::ALU::Parse3G;
use Common::CSV;
use Common::Lock;
use Common::XML;
use Data::Dumper;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse RNCCN,nodeB,iNode xml observation files from Alcatel-Lucent WNMS into csv files";
}

sub usage_desc {
	return "%c alu3gpm %o [ filename(s) ]";
}

sub opt_spec {
	my @one_of = (
		["RNCCN", "Parse pmtype RNCCN"],
		["nodeB", "Parse pmtype nodeB"],
		["iNode", "Parse pmtype iNode"],
	);
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "templatedir|t=s",	"directory containing xml templates for decoding pm file", { default => "../templates" }],
	[ "pmtype|p=s",	"type of binary pm file being parsed", { required => 1, hidden => 1, one_of => \@one_of}],
	[ "wnms|w=s",	"WNMS name", { required => 1 }],
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
	#GetOpt seems to lowercase all provided command line options
	$opt->{pmtype} = 'RNCCN' if $opt->{pmtype} eq 'rnccn';
	$opt->{pmtype} = 'nodeB' if $opt->{pmtype} eq 'nodeb';
	$opt->{pmtype} = 'iNode' if $opt->{pmtype} eq 'inode';
	
	my $lock = '.'.$opt->{wnms}.$opt->{pmtype};
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	
	for my $pmfile (@$args) {
		
		my ($pm,$counters,$info) = Common::ALU::Parse3G::parse_3GPM($pmfile,$opt->{templatedir},$opt->{pmtype});
		warn "Warning: No data was retrieved after parsing $pmfile. Did you select the correct pmtype? (current choice = $opt->{pmtype})\n"	unless (scalar(keys %$counters) > 0);
	
		my $success = Common::CSV::to_csv($pm,$counters,$info,$opt->{wnms},$opt->{pmtype},$opt->{outdir});
		if ($success && $opt->{delete}) {
			print "Deleting: $pmfile (-D command line option was provided)\n";
			unlink($pmfile);
		}
	}
}

1;
