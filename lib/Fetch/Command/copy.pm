package Fetch::Command::copy;

=head1 NAME
Fetch::Command::copy
=cut
#pragmas
use strict;
use warnings;
#modules
use Common::Lock;
use Common::Date;
use Data::Dumper;
use Fcntl qw(:flock);
use Fetch -command;
use File::Basename;
use File::Copy qw(copy);
use File::DirWalk;
use File::Path qw(make_path);
use Time::Local qw(timelocal);

my @month = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my %month = map {$month[$_] => $_+1 } (0..$#month);

sub abstract {
	return 'copy data and log';
}

sub usage_desc {
	return "%c copy %o";
}

sub opt_spec {
	return (
    [ "what=s", 	"Files to retrieve, can be regex or filename", { required => 1}],
    [ "where=s", 	"Directory to start looking for files", { required => 1}],
    [ "dir|d=s",	"Local directory to store files", { default => '../data'}],
    [ "log|l=s", 	"Log directory", { default => '../copylog'}],
    [ "ignore", 	"Copy files, even if they were already copied (copied files are logged)."],
    [ "maxdays|m=s", 	"Only copy files that are up to maxdays old"],		#sometimes, you just dont want to copy everything..
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	
	$self->usage_error("No arguments allowed") if @$args;
	$opt->{log} = $1 if $opt->{log} =~ /(.*)\/$/;	#remove trailing slash
	$opt->{where} .= '/' unless $opt->{where} =~ /\/$/;	#in case no ending backslash was provided
	make_path($opt->{dir},$opt->{log},$opt->{dir}, { verbose => 1 });
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	(my $lock = $opt->{what}) =~ s/\W//g;
	Common::Lock::get_lock('.'.$lock) or Common::Lock::bail('.'.$lock);
	
	my $have;
	unless ($opt->{ignore}) { 
		$have = fetched_already($opt);
	}
	copy_files($opt, $have);
}

sub copy_files {
	my ($opt,$have) = @_;
	#print Dumper($opt);
	#exit;
	my %dir = ();
	my $count = 0;
	my $dw = File::DirWalk->new();
	$dw->onFile(sub {         
		my ($file) = @_;
		if ($file =~ /$opt->{what}/) {
			my $size = -s $file;
			my $entry = join(';',$file,$size);
			if ( exists $have->{$entry}) {
					$count++;
			}
			else {
				if (  (! exists $opt->{maxdays}) ||  ( (exists $opt->{maxdays}) && (-M $file < $opt->{maxdays}) )  ) {
					my ($name,$path) = fileparse($file);
					(my $prefix = $path) =~ s/\W/_/g; 	#guarantee unique file name if two files have same name
					my $outfile = $opt->{dir}.'/'.$prefix.$name;
					print "Copy: $file to $outfile\n";
					my $success = copy($file,$outfile);
					logit($opt,$file,$size) if $success;	#need to record file sizes as well
				}
				else {
					my $day = $opt->{maxdays} == 1 ? 'day' : 'days';
					warn "Skipping $file because it is older than $opt->{maxdays} $day and --maxdays command line option was provided.\n";
				}
			}
		}              
		return File::DirWalk::SUCCESS; 
	});
	$dw->walk($opt->{where});
	warn "$count files were not copied because they were already copied previously - see log file in \"$opt->{log}\" (or use --ignore command line option to copy anyway).\n" if $count > 0; 	
}

sub logit {
	my ($opt,$file,$size) = @_;
	my $today = Common::Date::today();
	my $logname = $today.".".log_name($opt).".cplog";
	open my $log ,'>>', $opt->{log}.'/'.$logname;
	print $log "$file;$size\n";
	close $log;
}

sub file_exists_or_die {
	my $file = shift;
	die "File $file does not exist.\n" unless -e $file;
}

#generate name of what is being copied from where, for logging purposes
sub log_name {
	my $opt = shift;
	my $name = $opt->{what};
	$name =~ s/\W//g;
	return $name;
}

sub fetched_already {
	my ($opt) = @_;
	my %seen;
	my $log_name = log_name($opt);
	my $log_dir = $opt->{log};
	opendir my $dir, $log_dir || die "Could not open $log_dir for reading: $!\n";
	while (my $file = readdir $dir) {
		next unless ($file =~ /$log_name/); 
		$seen{$_} = 1 for log_entries_in("$log_dir/$file");   
	}
	return \%seen;
}

sub log_entries_in {
	my $logfile = shift;
	my %seen;
	open my $in ,'<', $logfile || die "Could not open $logfile : $!\n";
	while (my $line = <$in>) {
		chomp $line;
		$seen{$line} = 1;
	}
	close $in;
	return keys %seen;
}


sub bail {
	my ($name) = @_;
	print "FTP for this type of file is already running because lockfile .$name exists. Exiting.\n";
	exit(1);
}

1;