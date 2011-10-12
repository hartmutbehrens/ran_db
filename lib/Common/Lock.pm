package Common::Lock;

=head1 NAME
Common::Lock;
=cut
#sometimes its necessary to prevent two long running proceses from starting at the same time..prevent this with locks

#pragmas
use strict;
use warnings;
#modules
use Fcntl qw(LOCK_EX LOCK_NB);
use File::NFSLock;

sub get_lock {
	my $name = shift;
	my $lock = File::NFSLock->new($name, LOCK_EX|LOCK_NB);
	die "A process with lockfile $name is already running!\n" unless $lock; 	
}

sub bail {
	my $name = shift;
	warn "A process with lockfile $name is already running!\n";
	exit(1);
}

1;