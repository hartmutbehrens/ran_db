package Fetch::Command::ftp;

=head1 NAME
Fetch::Command::ftp
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
use File::Path qw(make_path);
use Net::FTP;

my @month = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my %month = map {$month[$_] => $_+1 } (0..$#month);

sub abstract {
	return 'ftp data from source';
}

sub usage_desc {
	return "%c ftp %o";
}

sub opt_spec {
	return (
	[ "from|f=s",	"Host address", { required => 1}],
	[ "name|n=s",	"Host name (for file retrieval organization purposes)", { required => 1}],
    [ "what=s", 	"Files to retrieve, can be regex or filename", { required => 1}],
    [ "where=s", 	"FTP directory to start looking for files", { required => 1}],
    [ "user|u=s", 	"User", { required => 1}],
    [ "pwd|p=s", 	"Password", { required => 1}],
    [ "dir|d=s",	"Local directory to store files", { default => '../data'}],
    [ "log|l=s", 	"Log directory", { default => '../ftplog'}],
    [ "maxdays", 	"Only scan subdirectories recursively that are up to maxdays old", { default => 2}],		#wNMS keeps PM files forever..
    [ "ignore", 	"Copy files, even if they were already ftpd (ftpd files are logged)."],
    [ "debug", 	"Debug FTP"],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	
	$self->usage_error("No arguments allowed") if @$args;
	$opt->{log} = $1 if $opt->{log} =~ /(.*)\/$/;	#remove trailing slash
	make_path($opt->{dir},$opt->{log},$opt->{dir}.'/'.$opt->{name}, { verbose => 1 });
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	(my $lock = $opt->{from}.$opt->{what}) =~ s/\W//g;
	Common::Lock::get_lock('.'.$lock) or Common::Lock::bail('.'.$lock);
	
	my $have = fetched_already($opt);
	my $ftp = open_connection($opt->{from},$opt->{user},$opt->{pwd},$opt->{debug});
	ftp_files($ftp, $opt, $have);
	$ftp->quit;
}

sub ftp_files {
	my ($ftp,$opt,$have) = @_;
	my %dir = ();
	my $count = 0;
	find_recursively($ftp,\%dir,$opt->{where},$opt->{what},$opt->{maxdays});
	
	#print Dumper(\%dir);
	foreach my $dir (keys %dir) {
		$ftp->cwd($dir);
		foreach my $file (keys %{$dir{$dir}}) {
			my $fl = $dir{$dir}{$file};
			my ($attr,$sf) = ($fl =~ /^(.{15})(.*?)$/);
			if (exists $have->{$sf}) {
				$count++;
				next;	
			} #file was already copied
			 
			my $lf = $file;
			$lf =~ s/\:/\_/g if ($^O =~ /win/i);		#remove characters that are not allowed in a windows filename
			$lf =~ s/\s/\_/g;
			print "GET: $file\n";
			my $success = $ftp->get($file,$opt->{dir}.'/'.$opt->{name}.'/'.$lf);
			log_ftp($opt,$fl) if $success;
		}
	}
	warn "$count files were not copied because they were already copied previously - see ftplog in \"$opt->{log}\".\n" if $count > 0;	
}

sub log_ftp {
	my ($opt,$file) = @_;
	my $today = Common::Date::today();
	my $logname = $today.".".log_name($opt).".ftplog";
	open my $log ,'>>', $opt->{log}.'/'.$logname;
	print $log $file,"\n";
	close $log;
}

#go through sub and all subs below to log files that need to be ftpd
sub find_recursively {
	my ($ftp,$dref,$loc,$mask,$maxdays) = @_;
	my ($today,$epsec_today,$gyear,$gmon,$gmday) = Common::Date::today();
	print "Checking : $loc\n";
	my @items = $ftp->dir($loc);
	foreach my $i (@items) {
		my ($attr,$j) = ($i =~ /^(.{15})(.*?)$/);
		next unless defined $j;
		my (undef,undef,$fsiz,$mon,$day,$year_or_time,@rest) = split(' ',$j);
		my $name = join(' ',@rest);
		next if ($name =~ /^\./);			#skip . and .. subdirectories
		$dref->{$loc}->{$name} = $i if ($name =~ /$mask/);		#found file ? save into hashref
		if ($attr =~ /^d/) {  #found directory ? carry on recursing ..
			if ($year_or_time =~ /\:/) {  #*nix servers return dates as e.g. Jul 2 2009 for older files and e.g. Jul 28 14:21 for newer files - this test is to compensate for that
				$year_or_time = $month{$mon} > $gmon+1 ? $gyear +1900 -1 : $gyear + 1900;	#the above condition can also occur when changing from Dec 31/YEAR to Jan 1/YEAR+1 - this line is to compensate for that 
			}
			my $date = $year_or_time.'-'.sprintf("%.2d",$month{$mon}).'-'.sprintf("%.2d",$day);
			#print "Date is $date for directory $name\n";
			unless ($date =~ /\:/) {
				my $epsec_date = timelocal(0,0,0,$day,($month{$mon}-1),($year_or_time-1900));
				my $delta = int(($epsec_today - $epsec_date)/86400);				
				#print "SKIP: $loc $name days difference between $today and $date is $delta days\n";
				next if ($delta > $maxdays);
			}
			find_recursively($ftp,$dref,$loc.$name.'/',$mask,$maxdays);
		}
		
	}
	
}

sub file_exists_or_die {
	my $file = shift;
	die "File $file does not exist.\n" unless -e $file;
}


sub open_connection {
	my ($host,$user,$pwd,$debug) = @_;
	my $ftp = Net::FTP->new($host, TimeOut => 10, Debug => $debug, Passive => 0);
	die "Could not establish an ftp connection to $host: $@\n" unless defined $ftp;
	$ftp->login($user,$pwd) || die "Cannot login: ",$ftp->message,"\n";
	$ftp->type('I');
	return $ftp;
}

#generate name of what is being copied from where, for logging purposes
sub log_name {
	my $opt = shift;
	my $name = $opt->{name}.$opt->{from}.$opt->{what};
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
		my ($ugo,$rest) = ($line =~ /^(.{15})(.*?)$/);
		$seen{$rest} = 1;
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