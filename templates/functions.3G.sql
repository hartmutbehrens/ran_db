
#function to retrieve LAC - given CellName
drop function if exists getLocationCode;
delimiter //
create function getLocationCode (name varchar(100), sector int) returns int
begin
	declare rv int;
	select locationAreaCode into rv from Cell where NodeBName = name and rdnId = sector order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to retrieve LAC - given CellName
drop function if exists getLocationCode_Cell;
delimiter //
create function getLocationCode_Cell (name varchar(100)) returns int
begin
	declare rv int;
	select locationAreaCode into rv from Cell where CellName = name order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to retrieve CI - given CellName
drop function if exists getCellId;
delimiter //
create function getCellId (name varchar(100), sector int) returns int
begin
	declare rv int;
	select cellId into rv from Cell where NodeBName = name and rdnId = sector order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to retrieve CI - given CellName
drop function if exists getCellId_Cell;
delimiter //
create function getCellId_Cell (name varchar(100)) returns int
begin
	declare rv int;
	select cellId into rv from Cell where CellName = name order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to give DATETIME - useful for Citrix Sonar
drop function if exists giveDateTime;
delimiter //
create function giveDateTime (inDate date) returns datetime
begin
	declare rv datetime;
	select concat(inDate,' 12:00:00') into rv;
	return rv;
end
//
delimiter ;

#function to give DATETIME - useful for Citrix Sonar
drop function if exists giveStartDate;
delimiter //
create function giveStartDate (inDate date) returns datetime
begin
	declare rv datetime;
	declare diff int;
	declare theYear int;
	select (dayofyear(inDate)-weekday(inDate)) into diff;
	select year(inDate) into theYear;
	select case diff when 0 then concat(makedate((theYear-1),365),' 00:00:00') else concat(makedate(theYear,diff),' 00:00:00') end into rv;
	return rv;
end
//
delimiter ;

#function to give DATETIME - useful for Citrix Sonar
drop function if exists giveWeekStart;
delimiter //
create function giveWeekStart (inDate date) returns datetime
begin
	declare rv datetime;
	declare diff int;
	declare theYear int;
	select (dayofyear(inDate)-weekday(inDate)) into diff;
	select year(inDate) into theYear;
	select case diff when 0 then concat(makedate((theYear-1),365),' 00:00:00') else concat(makedate(theYear,diff),' 00:00:00') end into rv;
	return rv;
end
//
delimiter ;

#function to give DATETIME - useful for Citrix Sonar
drop function if exists giveWeekEnd;
delimiter //
create function giveWeekEnd (inDate date) returns datetime
begin
	declare rv datetime;
	declare diff int;
	declare theYear int;
	select (dayofyear(inDate)-weekday(inDate)+6) into diff;
	select year(inDate) into theYear;
	select case diff when 0 then concat(makedate((theYear-1),365),' 00:00:00') else concat(makedate(theYear,diff),' 00:00:00') end into rv;
	return rv;
end
//
delimiter ;

drop function if exists giveDayStart;
delimiter //
create function giveDayStart (sdt datetime) returns datetime
begin
	declare rv datetime;
	select concat(date(sdt),' ',maketime(0,0,0)) into rv;
	return rv;
end
//
delimiter ;

#function to find the RNC given a nodeB name
drop function if exists getRncfromNodeB;
delimiter //
create function getRncfromNodeB (name varchar(100)) returns varchar(100)
begin
	declare rv varchar(100);
	select RncName into rv from NodeB where NodeBName = name order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;


#function to retrieve NodeB name given LAC and CI
drop function if exists getNodeBfromCell;
delimiter //
create function getNodeBfromCell (cid int, laid int) returns varchar(100)
begin
	declare rv varchar(100);
	select NodeBName into rv from Cell where cellId = cid and locationAreaCode = laid limit 1;
	return rv;
end
//
delimiter ;

