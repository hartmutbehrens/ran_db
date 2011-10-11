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
use Module::Pluggable;
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
	[ "type|t=s",	"PM file type being parsed", { default => 'unknown', hidden => 1 }],
	[ "delete|D",	"Delete file(s) after parsing"],
	[ "classifiers|c=s@",	"section classifiers [table,unique_col1,unique_col2,..]. Repeat switch and argument to add more classifiers.", 
			{ default => [] } ],
	[ "remap|m=s@",	"change column names [table,old_col_name,new_col_name]. Repeat switch and argument to add more column name changes.", 
			{ default => [] } ],
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
	for my $infile (@$args) {
		my $sections = get_sections($opt->{ssep},$infile);
		my $header = parse_header($sections->[0],$opt->{rsep}); #assume first section is header, naughty naughty
		
		for my $plugin (plugins()) {
			activate_plugin($plugin,$opt,$header) if ($plugin->can('recognize') && $plugin->recognize($header));
		}
		
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

sub activate_plugin {
	my ($plugin,$opt,$header) = @_;
	$plugin->process_header($header) if $plugin->can('process_header');
	$plugin->add_classifiers($opt,$header) if $plugin->can('add_classifiers');
	$plugin->add_remaps($opt,$header) if $plugin->can('add_remaps');
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

#single Obsynt files are not expected to be very big, so go for the "risky" approach of reading the whole file into memory and then splitting into fragments
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