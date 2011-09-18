package Parse::Command::3galarms;

=head1 NAME
Parse::Command::3galarms;
=cut
#pragmas
use strict;
use warnings;
#modules
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse UMTS Alarms file(s) (HFB file) from Alcatel-Lucent WNMS into csv files";
}

sub usage_desc {
	return "%c 3galarms %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "table|t=s", "table name", {hidden => 1, default => '3GAlarms'}],
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
	
	for my $file (@$args) {
		
		my $success = parse_3galarms($file,$opt->{wnms},$opt->{table});
		if ($success && $opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($file);
		}
	}
}

sub parse_3galarms {
	my ($file,$source,$outdir,$table) = @_;
	my $rv = 0;
	return $rv unless (-s $file > 300);
	my ($stamp) = ($file =~ /.*?hfb_(.*?)\.dat/);
	my $outfile = $outdir.join('.',$source,'3galarms',$table,$stamp,'csv');
	
	print "Parsing $file and placing output in $outfile.\n";
	open my $in , "<" ,$file || die "Could not open $file for parsing: $!\n";
	open my $out ,'>', $outfile || die "Could not open output file $outfile : $!\n";
	my @cols = ();
	while (my $line = <$in>) {
		chomp $line;
		next unless ($. > 3);
		if ($. == 4) {
			@cols = split(';',$line);
			print $out $line."\n";
		}
		else {
			my %d = ();
			$line =~ s/(\d+)\-(\d+)\-(\d+)/$3\-$1\-$2/g;
			my @data = split(';',$line);
			@d{@cols} = @data;
			if ($d{'ADDITIONALTEXT'} =~ /Associated BTS\:(\w+)\,/) {
				$d{'NODEB'} = $1;
			}
			print $out join(';',map(exists($d{$_}) ? $d{$_} eq '' ? 'NULL' : $d{$_} : 'NULL',(@cols,qw/NODEB/)))."\n";
			$rv = 1;
		}
	}
	close $in;
	close $out;
	return $rv;
}

1;
