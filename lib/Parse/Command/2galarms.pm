package Parse::Command::2galarms;

=head1 NAME
Parse::Command::2galarms;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::Date;
use Common::File;
use Common::Lock;
use Data::Dumper;
use File::Path qw(make_path);
use Parse -command;

sub abstract {
	return "parse OMC-R Alarms archive (HAL.tgz) into csv files";
}

sub usage_desc {
	return "%c 2galarms %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "table|t=s", "table name", {hidden => 1, default => 'Alarms_2G'}],
	[ "type|t=s",	"PM file type being parsed", { default => '2galarms', hidden => 1 }],
	[ "ofsep|of=s",	"output field separator", { default => ";", hidden => 1 }],
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
	my $lock = '.'.$opt->{omc}.'2galarms';
	Common::Lock::get_lock($lock) or Common::Lock::bail($lock);
	for my $file (@$args) {
		my $tar = Archive::Tar->new();
		$tar->read($file,1);
		my @arch_files = $tar->list_files();
		for my $af (@arch_files) {
			print "About to parse archive file $af\n";
			my @content = split("\n",$tar->get_content($af)); #in memory processing of csv file should be more efficient than extracting to disk and reading file
		 	my ($cols,$data) = parse_contents(\@content);
		 	
		 	to_csv($af,$opt,$cols,$data)
		}
		 
		if ($opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($file);
		}
	}
}

sub parse_contents {
	my ($contents) = @_;
	
	my @cols = split(';',@$contents[1]);
	my @data;
	my @csv_cols = qw/AlarmDate AlarmTime CONTROLLER EXTRA FRDNAME EVTTYPE PBCAUSE SPECPB SEV CLRSTS CLRTIME AVLSTS ADMSTS OPSTS ALMSTS/;
	my ($first,$last) = (2,$#$contents);
	
	my %d;
    for (@$contents[$first..$last]) {
    	@d{@cols} = split ';';
    	$d{EVTTYPE} =~ s/Alarm//;
    	my ($control,@extra) = split ' ', $d{FRDNAME};	#BSC or MFS name and some optional extras e.g. BTS / Abis / RA / etc
    	@d{qw/CONTROLLER EXTRA/} = ($control, join(' ',@extra));
    	
    	@d{qw/AlarmDate AlarmTime/} = Common::Date::make_date_time($d{EVTTIME},0);
    	$d{CLRSTS} = $1 if ($d{CLRSTS} =~ /(\w+)/);
    	$d{SEV} = $1 if ($d{SEV} =~ /(\w+)/);
    	if ($d{CLRTIME} =~ /\d+/) {
	    	my ($cldate,$cltime) = Common::Date::make_date_time($d{CLRTIME},0);
	    	$d{CLRTIME} = $cldate.' '.$cltime;
    	}
    	$d{MONITOR} =~ s/\s//g;
    	@d{qw/AVLSTS ADMSTS OPSTS ALMSTS/} = ($d{MONITOR} =~ /AvailabilityStatus\,(.*?)\).*?AdministrativeState\,(.*?)\).*?OperationalState\,(.*?)\).*?AlarmStatus\,(.*?)\)/);
    	
    	$d{$_} = defined $d{$_} ? $d{$_} : '' for @csv_cols;
    	
    	my @vals = @d{@csv_cols};
    	push @data, \@vals;
    }
    return (\@csv_cols,\@data);
}

sub to_csv {
	my ($file,$opt,$cols,$data) = @_;
	
	my ($outdir,$sep,$omc,$type) = @{$opt}{qw/outdir ofsep omc type/};
	
	my @file = Common::File::split_path($file);
	my $outfile = join('.',$omc,$type,$opt->{table},$file[$#file],'csv');
	$file =~ s/\:/_/g;	#windows does not like : in file name
	print "Writing output to $outdir/$outfile\n";
	open my $out,'>',"$outdir/$outfile" || die "Could not open $outdir/$outfile for writing due to error: $!\n";
	print $out join($sep,qw(OMC_ID),@$cols ),"\n";
	for my $vals (@$data) {	
		print $out join($sep,$omc,@$vals ),"\n";
	}
	close $out;
}

1;
