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
use Fcntl qw(:flock);
use Fetch -command;
use File::Path qw(make_path);
use Net::FTP;


sub abstract {
	return 'ftp data from source';
}

sub usage_desc {
	return "%c ftp %o";
}

sub opt_spec {
	return (
	[ "from|f=s",	"Host address", { required => 1}],
    [ "what|w=s", 	"Files to retrieve, can be regex", { required => 1}],
    [ "user|u=s", 	"User", { required => 1}],
    [ "pwd|p=s", 	"Password", { required => 1}],
    [ "dir|d=s",	"Local directory to store files", ],
    [ "log|l=s", 	"Log directory", { default => '../ftplog'}],
    [ "debug|D=s", 	"Debug FTP", { default => 0}],
  );
}

sub validate_args {
	my ($self, $opt, $args) = @_;
	
	$self->usage_error("No arguments allowed") if @$args;
	$opt->{log} = $1 if $opt->{log} =~ /(.*)\/$/;	#remove trailing slash
	make_path($opt->{dir},$opt->{log}, { verbose => 1 });
}

sub execute {
	my ($self, $opt, $args) = @_;
	
	(my $lock = $opt->{from}.$opt->{what}) =~ s/\W//g;;
	Common::Lock::get_lock($lock);
	#my $have = fetched_already($opt->{log},$source->{name}->{value},$what->{name}->{value});
	#my $ftp = open_connection($opt->{from},$opt->{user},$opt->{pwd},$opt->{debug});
	#ftp_files($ftp, map($what->{$_}->{value} ,qw(name location filemask) ) );
	#$ftp->quit;
}

sub ftp_files {
	my ($ftp,$name,$dir,$mask) = @_;	
}

sub recursive {
	
}

sub do_this {
	print "wanted\n";
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
	#$ftp->type('I');
	return $ftp;
}

sub fetched_already {
	my ($log_dir,$from,$what) = @_;
	my %seen;	
	opendir my $dir, $log_dir || die "Could not open $log_dir for reading: $!\n";
	while (my $file = readdir $dir) {
		next unless ($file =~ /$from/) && ($file =~ /$from/); 
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