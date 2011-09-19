package Common::Lock;

=head1 NAME
Common::Lock;
=cut

#pragmas
use strict;
use warnings;
#modules
use Fcntl qw(:flock);

sub get_lock {
	my $name = shift;	
	open my $fhpid, '>', '.'.$name || die "Error opening lockfile .$name: $!\n";
	flock($fhpid, LOCK_EX|LOCK_NB) or bail($name);
}

sub bail {
	my $name = shift;
	print "a process with lockfile $name is already running";
	exit(1);
}

1;