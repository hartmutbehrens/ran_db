package Parse::Command::obsynt;

=head1 NAME
Parse::Command::obsynt;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::File;
use Data::Dumper;
use Parse -command;

sub abstract {
	return 'parse Obsynt output from Alcatel-Lucent OMC-R into csv files';
}

sub usage_desc {
	return "%c obsynt %o [ filename(s) ]";
}

sub opt_spec {
	my ($ssep,$rsep,$fsep) = ("\n\n\n","\n","\t");

	return (
	[ "ssep|s=s",	'input section separator (default \n\n\n)', { default => $ssep }],
	[ "rsep|r=s",	'input record separator (default \n)', { default => $rsep }],
	[ "fsep|f=s",	'input field separator (default \t)', { default => $fsep }],
	[ "ofsep|of=s",	"output field separator", { default => ";" }],
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "omc|o=s",	"OMC-R name", { required => 1 }],
	[ "type|t=s",	"PM file type being parsed", { required => 1 }],
	[ "delete|D",	"Delete file(s) after parsing"],
	[ "classifiers|c=s@",	"section classifiers [table,unique_col1,unique_col2,..]. Repeat switch and argument to add more classifiers.", 
			{ default => classifiers() } ],
	[ "remap|m=s@",	"remap column names [table,old_col,new_col]. Repeat switch and argument to add more column remappings.", 
			{ default => remaps() } ],
  );
}

sub classifiers {
	my @classifiers;
	push @classifiers,$_ for t110_classifier(),gpm_classifier();	#add more classifiers here - (more elegant solution required)
	return \@classifiers
}

sub remaps {
	my @remap;
	push @remap,$_ for t110_remap(); #add more remaps here - (more elegant solution required)
	return \@remap;
}

sub t110_classifier {
	return ('T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35','T110_MSC_H,MSC_NAME,MSC_SBL,MC1101');
}

sub gpm_classifier {
	return ('GPM_BEARERCHANNEL_H,BEARER,P33','GPM_PVC_H,PVC,P23','GPM_LAPD_H,GSL,P2A','GPM_CELL_H,CI,LAC,P38B','GPM_BTS_H,BTS_NB_EXTRA_ABIS_TS,P472');
}

sub t110_remap {
	return ('T110_TRX_H,BTS_INDEX,BTS_ID','T110_TRX_H,BTS_SECTOR,SECTOR','T110_TRX_H,CELL_CI,CI','T110_TRX_H,CELL_LAC,LAC','T110_TRX_H,TRXID,TRX',
				'T110_SECTOR_H,BTS_INDEX,BTS_ID','T110_SECTOR_H,BTS_SECTOR,SECTOR','T110_SECTOR_H,CELL_CI,CI','T110_SECTOR_H,CELL_LAC,LAC');
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	
	$self->usage_error("At least one file name is required") unless @$args;
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}
}

sub execute {
	my ($self, $opt, $args) = @_;
	for my $infile (@$args) {

		my $sections = get_sections($opt->{ssep},$infile);
		my $header = parse_header($sections->[0],$opt->{rsep}); #assume first section is header, naughty naughty
		
		for (1..$#$sections) {
			my ($table,$cols,$data) = parse_section($sections->[$_],$opt->{rsep},$opt->{fsep},$opt->{classifiers});
			if ($table) {
				remap_cols($opt->{remap},$table,$cols);	#make remapping of column names possible, to conform to possibly already existing naming conventions
				counter_ll_lc($cols); #trailing letters of counters need to be lowercase
				if (scalar @$data > 0) {
					to_csv($infile,$opt,$header,$table,$cols,$data);
				}
				else {
					warn "No data was found in $infile for the section belonging to table $table\n";
				}	
			}	
		}
		if ($opt->{delete}) {
			print "Deleting: $infile (-D command line option was provided)\n";
			unlink($infile);
		}
	}		
}

sub to_csv {
	my ($file,$opt,$header,$table,$cols,$data) = @_;
	
	my ($outdir,$sep,$omc,$type) = @{$opt}{qw/outdir ofsep omc type/};
	my @hcols = sort keys %$header;
	my @hvals = @$header{@hcols};
	
	my @file = Common::File::split_path($file);
	my $outfile = join('.',$omc,$type,$table,$file[$#file],'csv');	#if input filename is unique, then output filename should also be unique
	$file =~ s/\:/_/g;	#windows does not like : in file name
	print "Writing output to $outdir/$outfile\n";
	open my $out,'>',"$outdir/$outfile" || die "Could not open $outdir/$outfile for writing due to error: $!\n";
	print $out join($sep,qw(OMC_ID),@hcols,@$cols ),"\n";
	for my $vals (@$data) {	
		print $out join($sep,$omc,@hvals,@$vals ),"\n";
	}
	close $out;
}

sub parse_header {
	my ($header,$rsep) = @_;
	my %header;

	for my $line ( split($rsep,$header)  ) {
		my ($name,$val) = ($line =~ /(.*?)\s+\:\s+(.*)/);
		$name =~ s/\s/_/g;
		$header{$name} = $val;
	}
	return \%header;
}

sub parse_section {
	my ($section,$rsep,$fsep,$classifiers) = @_;
	my (@cols,@data);
	my $table = undef;
	for my $line ( split($rsep,$section)  ) {
		next unless $line =~ /\w+/;
		my @fields = split($fsep,$line);
		my $id = classify(\@fields,$classifiers);
		
		if ($id) {
			$table = $id;
			@cols = @fields;	#found the header line
		}
		else {
			push @data ,\@fields;
		}
	}
	unless ($table) {
		warn "The following section could not be classified:\n";
		warn $section,"\n";
	}
	return ($table,\@cols,\@data);
}

sub remap_cols {
	my ($map,$table,$cols) = @_;
	my %map;
	for (@$map) {
		my ($table,$old,$new) = split('\W+',$_);
		$map{$table.','.$old} = $new;
	}

	for (0..$#$cols) {
		my $index = $table.','.$cols->[$_];
		$cols->[$_] = $map{$index} if exists $map{$index};
	}
}

sub counter_ll_lc {
	my $cols = shift;
	for (0..$#$cols) {
		if ($cols->[$_] =~ /^MC/) {
			my @chars = split('',$cols->[$_]);
			$chars[$#chars] = lc($chars[$#chars]);
			$cols->[$_] = join('',@chars);
		}
	}
}


sub classify {
	my ($fields,$classifiers) = @_;
	for (@$classifiers) {
		my ($table,@cols) = split('\W+',$_);
		return $table if has_all_cols($fields,\@cols);
	}
	return undef;
}

sub has_all_cols {
	my ($fields,$unique_cols) = @_;
	my %fields = map {$_ => 1} @$fields;
	my $rv = 1;
	for (@$unique_cols) {
		my $has = exists $fields{$_} ? 1 : 0;
		$rv *= $has; 
	}
	return $rv;
}

#single Obsynt T110 files are not expected to be very big, so go for the risky approach of reading the whole file into memory and then splitting into fragments
sub get_sections {
	my ($sep,$file) = @_;
	open my $in ,'<', $file || die "Could not open input file $file due to error: $! \n";
	local $/;
	my $content = <$in>;
	close $in;
	my @sections = split($sep,$content);
	return \@sections;
}

1;