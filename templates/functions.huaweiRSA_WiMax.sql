#function to return the date and time with the time set to the start of the hour
delimiter //
create function startDateTime_Hour (sdt datetime) returns datetime
begin
	declare rv datetime;
	select concat(date(sdt),' ',maketime(hour(sdt),0,0)) into rv;
	return rv;
end
//
delimiter ;

