package Common::Date;

=head1 NAME
Common::XML;
=cut

#pragmas
use strict;
use warnings;
#modules
use Time::Local;

sub today {
	my (undef,undef,undef,$gmday,$gmon,$gyear,undef,undef,undef) = localtime(time);
	my $today = sprintf("%04d-%02d-%02d",$gyear+1900,$gmon+1,$gmday);
	my $epsec_today = timelocal(0,0,0,$gmday,$gmon,$gyear);
	return wantarray ? ($today,$epsec_today) : $today;
}

1;