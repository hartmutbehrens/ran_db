#function to return the date and time with the time set to the start of the hour
delimiter //
create function giveDayStart (sdt datetime) returns datetime
begin
	declare rv datetime;
	select concat(date(sdt),' ',maketime(0,0,0)) into rv;
	return rv;
end
//
delimiter ;

