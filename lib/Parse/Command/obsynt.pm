package Parse::Command::obsynt;

=head1 NAME
Parse::Command::obsynt;
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::File;
use File::Path qw(make_path);
use Module::Pluggable search_path => ['Parse::Plugin'];
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
	[ "ssep|s=s",	'input section separator (default \n\n\n)', { default => $ssep, hidden => 1 }],
	[ "rsep|r=s",	'input record separator (default \n)', { default => $rsep, hidden => 1 }],
	[ "fsep|f=s",	'input field separator (default \t)', { default => $fsep, hidden => 1 }],
	[ "ofsep|of=s",	"output field separator", { default => ";", hidden => 1 }],
	[ "outdir|d=s",	"directory to store parsed csv file(s) in", { default => "../csvload" }],
	[ "omc|o=s",	"OMC-R name", { required => 1 }],
	[ "type|t=s",	"PM file type being parsed", { default => 'unknown', hidden => 1 }],
	[ "identifier|i=s",	"Optional output filename identifier", { default => ''}],
	[ "delete|D",	"Delete file(s) after parsing"],
	[ "classifiers|c=s@",	"section classifiers [table,unique_col1,unique_col2,..]. Repeat switch and argument to add more classifiers.", 
			{ default => [], hidden => 1 } ],
	[ "remap|m=s@",	"change column names [table,old_col_name,new_col_name]. Repeat switch and argument to add more column name changes.", 
			{ default => [], hidden => 1 } ],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	
	$self->usage_error("At least one file name is required") unless @$args;
	make_path($opt->{outdir}, { verbose => 1 });
	for (@$args) {
		die "The file $_ does not exist!\n" unless -e $_;	
	}
}

sub execute {
	my ($self, $opt, $args) = @_;
	for my $infile (@$args) {
		if (-s $infile) {
			my $sections = get_sections($opt->{ssep},$infile);
			my $header = parse_header($sections->[0],$opt->{rsep}); #assume first section is header, naughty naughty
			
			my @known;
			for my $plugin (plugins()) {
				if ( $plugin->can('recognize') && $plugin->recognize($header) ) {
					$plugin->process_header($header) if $plugin->can('process_header');
					$plugin->add_classifiers($opt,$header) if $plugin->can('add_classifiers');
					$plugin->add_remaps($opt,$header) if $plugin->can('add_remaps');
					push @known, $plugin;	
				}
			}
			
			for (1..$#$sections) {
				my ($table,$cols,$data) = parse_section($sections->[$_],$opt);
				if ($table) {
					remap_cols($opt->{remap},$table,$cols);	#make remapping of column names possible, to conform to possibly already existing naming conventions
					counter_ll_lc($cols); #trailing letters of counters need to be lowercase
					
					if (scalar @$data > 0) {
						for my $plugin (@known) {
							$plugin->parse_section($table,$cols,$data) if $plugin->can('parse_section');
						}
						to_csv($infile,$opt,$header,$table,$cols,$data);
					}
					else {
						warn "No data was found in $infile for the section belonging to table $table\n";
					}	
				}	
			}
		}
		else {
			warn "File $infile will not be parsed because it has zero size!\n";
		}
		if ($opt->{delete}) {
			print "Deleting: $infile (-D command line option was provided)\n";
			unlink($infile);
		}
	}		
}

sub to_csv {
	my ($file,$opt,$header,$table,$cols,$data) = @_;
	
	my ($outdir,$sep,$omc,$type,$id) = @{$opt}{qw/outdir ofsep omc type identifier/};
	my @hcols = sort keys %$header;
	my @hvals = @$header{@hcols};
	
	my @file = Common::File::split_path($file);
	my $outfile = join('.',$omc,$type,$table,$file[$#file],$id,'csv');
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
	my ($section,$opt) = @_;
	my (@cols,@data);
	my $table = undef;
	for my $line ( split($opt->{rsep},$section)  ) {
		next unless $line =~ /\w+/;
		my @fields = split($opt->{fsep},$line);
		my $id = classify(\@fields,$opt->{classifiers});
		
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

#last letters to lowercase
sub counter_ll_lc {
	my $cols = shift;
	for (0..$#$cols) {
		if ( ($cols->[$_] =~ /^(MC\d+)(.*?)$/) || ($cols->[$_] =~ /^(P\d+)(.*?)$/) || ($cols->[$_] =~ /^(C\d+)(.*?)$/) ) {
			$cols->[$_] = $1.lc($2);
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