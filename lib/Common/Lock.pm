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

1;