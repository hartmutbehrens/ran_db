package Parse::Command::obsynt;

=head1 NAME
Parse::Command::obsynt;
=cut
#pragmas
use strict;
use warnings;
#modules
use Parse -command;

sub abstract {
	return 'parse Obsynt output from Alcatel-Lucent OMC-R into csv files';
}

sub usage_desc {
	return "%c obsynt %o [ filename(s) ]";
}

sub opt_spec {
	return (
	[ "ssep|s=s",	"input section separator", { default => "\n\n\n" }],
	[ "rsep|r=s",	"input record separator", { default => "\n" }],
	[ "fsep|f=s",	"input field separator", { default => "\t" }],
	[ "ofsep|of=s",	"output field separator", { default => ";" }],
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "" }],
	[ "omc|o=s",	"OMC-R name", { required => 1 }],
	[ "type|t=s",	"PM file type being parsed", { required => 1 }],
	[ "classifiers|c=s@",	"section classifiers [table,unique_col1,unique_col2,..]. Repeat switch and argument to add more classifiers.", 
			{ default => [ 'T110_TRX_H,TRXID','T110_SECTOR_H,MC01,MC02','T110_LINK_H,LINK_ID','T110_BSC_H,MC19,MC35'] } ],
	[ "remap|m=s@",	"remap column names [table,old_col,new_col]. Repeat switch and argument to add more column remappings.", 
			{ default => [ 'T110_TRX_H,BTS_INDEX,BTS_ID','T110_TRX_H,BTS_SECTOR,SECTOR','T110_TRX_H,CELL_CI,CI','T110_TRX_H,CELL_LAC,LAC','T110_TRX_H,TRXID,TRX',
							'T110_SECTOR_H,BTS_INDEX,BTS_ID','T110_SECTOR_H,BTS_SECTOR,SECTOR','T110_SECTOR_H,CELL_CI,CI','T110_SECTOR_H,CELL_LAC,LAC'] } ],
  );
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
	for (@$args) {
		my $sections = get_sections($opt->{ssep},$_);
		my ($bsc,$release,$sdt,$edt,$bsc_id) = parse_header($sections->[0],$opt->{rsep}); #assume first section is header, naughty naughty
		
		for (1..$#$sections) {
			my ($table,$cols,$data) = parse_section($sections->[$_],$opt->{rsep},$opt->{fsep},$opt->{classifiers});
			if ($table) {
				remap_cols($opt->{remap},$table,$cols);	#make remapping of column names possiblem, to conform to possibly already existing naming conventions
				counter_ll_lc($cols); #trailing letters of counters need to be lowercase
				to_csv($opt->{outdir},$opt->{ofsep},$opt->{omc},$opt->{type},$bsc,$sdt,$edt,$bsc_id,$table,$cols,$data);	
			}	
		}
	}		
}

sub to_csv {
	my ($outdir,$sep,$omc,$type,$bsc,$sdt,$edt,$bsc_id,$table,$cols,$data) = @_;
	my ($sdate,$stime) = split(' ',$sdt);
	my ($edate,$etime) = split(' ',$edt);
	my $file = join('.',$omc,$type,$table,$bsc,$sdt,$edt,'csv');
	$file =~ s/\:/_/g;	#windows does not like : in file name
	open my $out,'>',$outdir.$file || die "Could not open $outdir.$file for writing due to error: $!\n";
	print $out join($sep,qw(OMC_ID BSC_NAME BSC_ID STARTDATE STARTTIME ENDDATE ENDTIME SDATE),@$cols ),"\n";
	for my $vals (@$data) {
		print $out join($sep,$omc,$bsc,$bsc_id,$sdate,$stime,$edate,$etime,$sdt,@$vals ),"\n";	
	}
	close $out;
}

sub parse_header {
	my ($header,$rsep) = @_;
	my ($bsc,$release,$sdt,$edt,$file,$bsc_id,$name);
	for my $line ( split($rsep,$header)  ) {
		my ($name,$val) = ($line =~ /(.*?)\:\s+(.*)/);
		$release = $val if ($name =~ /bss release/i);
		$bsc = $val if ($line =~ /name of bsc/i);
		$sdt = $val if ($line =~ /begin date/i);
		$edt = $val if ($line =~ /end date/i);
		$file = $val if ($line =~ /input file/i);
	}
	($bsc_id,$name) = ($file =~ /.*?PMRES.*?\..*?\.(\d+)\.(.*?)\./);
	return($bsc,$release,$sdt,$edt,$bsc_id);
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