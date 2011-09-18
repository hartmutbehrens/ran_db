package Common::Distance;

=head1 NAME
Common::Distance;
=cut

#pragmas
use strict;
use warnings;

sub haversine { # Haversine formula to calculate distance between two coordinates (in radians) in km
	my ($lat1, $lon1, $lat2, $lon2) = @_;      
  if ((defined $lat1) and (defined $lon1) and (defined $lat2) and (defined $lon2)) {
  	my $EarthRadiusKm = 6378; #km
  	my $a = (sin(($lat2-$lat1)/2))**2 + cos($lat1)*cos($lat2)*(sin(($lon2-$lon1)/2))**2;
    my $d = $EarthRadiusKm * 2 * atan2(sqrt($a), sqrt(1-$a));
    $d = sprintf("%.3f", $d);
    return($d);  # Distance in km
  }
  else {return 0;}
}

1;