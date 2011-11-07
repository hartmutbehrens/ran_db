package Parse::Command::rnl;

=head1 NAME
Parse::Command::rnl;
=cut
#pragmas
use strict;
use warnings;
#modules
use Archive::Tar;
use Common::Lock;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse rnl (2G configuration snapshot - NlSCExport) from Alcatel-Lucent OMC-R into csv files";
}

sub usage_desc {
	return "%c rnl %o [ filename(s) ]";
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
	
	my $lock = '.'.$opt->{omc}.'rnl';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	for my $file (@$args) {
		
		parse_rnl($file,$opt->{omc},$opt->{outdir});
		if ($opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($file);
		}
	}
}

sub parse_rnl {
	my ($file,$omc,$outdir) = @_;
	my $tar = Archive::Tar->new();
	$tar->read($file,1);
	my @files = $tar->list_files;
	foreach my $fl (@files) {
		next unless ($fl =~ /csv$/);
		print "Parsing $fl from $omc and placing output in $outdir.\n";
		my $content = $tar->get_content($fl); 
		open(OUTFILE,">".$outdir."/".$omc.'.rnl.'.$fl) || die "Could not open $outdir $omc.$fl for writing: $!\n";
		print OUTFILE $content;
		close OUTFILE;
	}
}

1;
