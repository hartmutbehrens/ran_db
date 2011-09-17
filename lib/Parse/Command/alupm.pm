package Parse::Command::alupm;

=head1 NAME
Parse::Command::alupm;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::ALU::Parse;
use Common::CSV;
use Common::XML;
use Data::Dumper;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse t18,t19,t31,t110 binary performance management files from Alcatel-Lucent OMC-R into csv files";
}

sub usage_desc {
	return "%c alupm %o [ filename(s) ]";
}

sub opt_spec {
	my @one_of = (
		["t18", "Parse pmtype PMRES-18 (A-Channel)"],
		["t19", "Parse pmtype PMRES-19 (SMS)"],
		["t31", "Parse pmtype PMRES-31 (Radio Measurements)"],
		["t110", "Parse pmtype PMRES110 (Overview Measurements)"],
	);
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "templatedir|t=s",	"directory containing xml templates for decoding pm file", { default => "../templates" }],
	[ "pmtype|p=s",	"type of binary pm file being parsed", { required => 1, hidden => 1, one_of => \@one_of}],
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
	
	for my $pmfile (@$args) {
		
		my $info = Common::ALU::Parse::alu_pm_info($pmfile);
		my $layout_file = $opt->{templatedir}.'/layout.'.lc($opt->{pmtype}).'.'.lc($info->{'VERSION'}).'.xml';
		unless ((-f $layout_file) && (-s $layout_file)) {
			print "The file $pmfile with version $info->{VERSION} cannot be decoded because no layout file could be found (looking for $layout_file) !\n";
			next;
		}
		my $layout = Common::XML::read_xml($layout_file);
		my ($pm,$counters) = Common::ALU::Parse::decode_binary($pmfile,$layout);
		warn "Warning: No data was retrieved after parsing $pmfile. Did you select the correct pmtype? (current choice = $opt->{pmtype})\n"	unless (scalar(keys %$counters) > 0);
	
		my $success = Common::CSV::to_csv($pm,$counters,$info,$opt->{omc},$opt->{pmtype},$opt->{outdir});
		if ($success && $opt->{delete}) {
			print "Deleting: $pmfile (-D command line option was provided)\n";
			unlink($pmfile);
		}
	}
}

1;
