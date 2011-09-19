package Common::Date;

=head1 NAME
Common::XML;
=cut

#pragmas
use strict;
use warnings;
#modules
use Time::Local qw(timelocal timelocal_nocheck);

sub today {
	my (undef,undef,undef,$gmday,$gmon,$gyear,undef,undef,undef) = localtime(time);
	my $today = sprintf("%04d-%02d-%02d",$gyear+1900,$gmon+1,$gmday);
	my $epsec_today = timelocal(0,0,0,$gmday,$gmon,$gyear);
	return wantarray ? ($today,$epsec_today,$gyear,$gmon,$gmday) : $today;
}

sub make_date_time {
	my ($timestamp,$granularity) = @_;
	my ($year,$mon,$day,$hour,$min,$sec) = ($timestamp =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/);
	my ($edate,$etime) = (join('-',$year,$mon,$day),join(':',$hour,$min,$sec));
	my ($ssec,$smin,$shour,$sday,$smon,$syear) =  map(sprintf("%02d",$_),localtime(timelocal_nocheck($sec,$min,$hour,$day,--$mon,$year) - $granularity));
	$smon++;
	$syear += 1900;
	my ($sdate,$stime) = (join('-',$syear,$smon,$sday),join(':',$shour,$smin,$ssec));
	return ($sdate,$stime,$edate,$etime);
}


1;