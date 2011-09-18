
#function to calculate haversine distance between two locations given in radians
drop function if exists haversineDistance;
delimiter //
create function haversineDistance (lat float,lon float,tlat float, tlon float) returns float
begin
	declare rv float;
	declare a float;
	select power(sin((tlat-(lat))/2),2) + cos(lat)*cos(tlat)*power(sin((tlon-(lon))/2),2) into a;
	select 6378*2*atan2(sqrt(a),sqrt(1-a)) into rv;
	return rv;
end
//
delimiter ;
