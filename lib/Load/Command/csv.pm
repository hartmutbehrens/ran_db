package  Load::Command::csv;

=head1 NAME
Load::Command::csv;
=cut
#pragmas
use strict;
use warnings;

#modules
use Common::MySQL;
use Load -command;

sub abstract {
	return "load CSV files into a DB";
}

sub usage_desc {
	return "%c csv %o";
}

sub opt_spec {
	return (
	[ "csvdir|c=s",	"directory to load csv files from", { default => "../csvload" }],
	[ "fsep|f=s",	'input field separator (default ;)', { default => ';' }],
	[ "hline=s",	'specify header line. [line#, col1, col2, ..] to specify header column names', ],
	[ "cline=s",	'specify column line. [line#, col1, col2, ..] to manually specify column names or [line#,auto] to extract column names automatically', { required => 1 }],
	[ "remap|r=s@",	'[table,old_col,new_col] remap old col column name to new_col column name. Repeat switch and argument to add more remaps'],
	[ "user|u=s",	"database user", { required => 1 }],
	[ "pass|x=s",	"database password", { required => 1 }],
	[ "host|h=s",	"database host IP address", { required => 1 }],
	[ "db|d=s",	"database name", { required => 1 }],
	[ "port|P=s",	"database port", { hidden => 1, default => 3306 }],
	[ "nms|n=s",	"load files from this OMC-R or WNMS name (will be used to match against csv file name)", { required => 1 }],
	[ "type|t=s",	"file type to be loaded (will be used to match against csv file name) - e.g. t110,RNCCN..", { required => 1 }],
	[ "delete|D",	"Delete file(s) after parsing"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	if (defined $opt->{hline} && substr($opt->{hline},0,1) eq  substr($opt->{cline},0,1)) {
		die "Header line and column line cannot both be on the same line. Please fix the command line arguments!\n";
	}		
}

sub execute {
	my ($self, $opt, $args) = @_;
	my $dbh;
	my $count = 0;
	my $connected = Common::MySQL::connect(\$dbh,@{$opt}{qw/user pass host port db/});
	unless ($connected) {
		die "Could not connect user \"$opt->{user}\" to database \"$opt->{db}\" on host \"$opt->{host}\". Please check that the provided credentials are correct and that the databse exists!\n";
	}
	opendir my $dir, $opt->{csvdir} || die "Could not open $opt->{csvdir} for reading: $!\n";
	while (my $file = readdir $dir) {
		my $match = "$opt->{nms}.$opt->{type}.";
		next unless ($file =~ /$match/);
		print "About to load: $file\n";
		 my $success = load_csv($dbh,$opt,$file);
		 $count++ if $success;
		 if ($success && $opt->{delete}) {
			print "Deleting: $file (-D command line option was provided)\n";
			unlink($opt->{csvdir}.'/'.$file);
		}
	}
	if ($count == 0) {
		warn "No files of type \"$opt->{type}\" from \"$opt->{nms}\" could be loaded from \"$opt->{csvdir}\" !\n";
	}
}

sub load_csv {
	my ($dbh,$opt,$file) = @_;
	
	my ($source,$type,$table) = split('\.',$file);
	unless (defined($source) && defined($type) && defined($table)) {
		warn "$file does not conform to the naming convetion \"source.type.table\" and will be skipped ..\n";
		return 0;
	}
	
	return 0 unless Common::MySQL::has_table($dbh,$table);
	my $def = Common::MySQL::get_definition($dbh,$table);
	
	$dbh->do("lock tables $table write") || die($dbh->errstr) ;
	
	my ($i,$has_cols) = (0,0);
	my (%d,%only,@cols);
	open my $in ,"<",$opt->{csvdir}.'/'.$file || die "Could not open $opt->{csvdir}/$file for reading:$!\n";
	while(<$in>) {
		chomp;
		
		if (defined $opt ->{hline} && ($opt->{hline} =~ /^$./) ) {	#we have a header line
			my (undef,@hcols) = split('\W+',$opt->{hline});
			@d{@hcols} = split($opt->{fsep}, $_);
			for (@hcols) {
				$only{$_} = 1 if exists $def->{$_};
			}
			next;
		}
		
		if ($opt->{cline} =~ /^$./) {		#we have a column line
			my (undef,@ccols) = split('\W+',$opt->{cline});
			@cols = lc($ccols[0]) eq 'auto' ? split($opt->{fsep}, $_) : @ccols;
			remap_cols($opt->{remap},$table,\@cols) if defined $opt->{remap};
			for (@cols) {
				$only{$_} = 1 if exists $def->{$_};
			}
			$has_cols = 1;
			next;
		}
		
		next unless $has_cols;
		@d{@cols} = split($opt->{fsep}, $_);
		my %e = map { $_ => $d{$_}  } keys %only;

		clean(\%e); #remove problematic fields		
		$e{'OMC_ID'} = exists $e{'OMC_ID'} ? $e{'OMC_ID'} : $source if exists $def->{OMC_ID}; #fixed in to_csv for most file types, but not for rnl (because it is extracted as-is out of the archive coming from the OMC-R)
		
		my @vals = values %e;
		#my $sql = 'replace into '.$table.' ('.join(',',map('`'.$_.'`',keys %e)).') values ('.join(',',map('\''.$_.'\'',@vals)).')';
		my $sql = 'replace into '.$table.' ('.join(',',map('`'.$_.'`',keys %e)).') values ('.join(',',map('?',@vals)).')';
		my $sth = $dbh->prepare($sql);
		$sth->execute(@vals);
		#print "$sql\n";
		$i++;
		
	}
	close $in;
	$dbh->do("unlock tables") || die($dbh->errstr) ;
	print "Loaded $i records from $file into $table.\n";
	return 1;	
}

sub clean {
	my $href = shift;
	for my $k (keys %$href) {
		delete $href->{$k} if (defined($href->{$k}) && (uc($href->{$k}) eq 'NULL'));
		delete $href->{$k} if (defined($href->{$k}) && (uc($href->{$k}) eq '?'));	#obsynt
		delete $href->{$k} if (defined($href->{$k}) && (length($href->{$k}) == 0) );
	}
}

sub remap_cols {
	my ($map,$table,$cols) = @_;
	print "Running remap \n";
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

1;
