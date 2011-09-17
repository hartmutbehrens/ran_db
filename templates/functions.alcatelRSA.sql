#function to retrieve MFS Name given MFS_ID and OMC
delimiter //
create function getMFS_Name (mfs int,omc varchar(50)) returns varchar(20)
begin
	declare rv varchar(20);
	select TRIM(BOTH '"' from UserLabel) into rv from RnlAlcatelMFS where RnlAlcatelMFS.RnlAlcatelMFSInstanceIdentifier = mfs and RnlAlcatelMFS.OMC_ID = omc order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to retrieve CI - given BSC,BTS,SECTOR and OMC
delimiter //
create function getCI (bsc int,bts int,sector int,omc varchar(50)) returns int
begin
	declare rv int;
	select CI into rv from Cell where Cell.BSC_ID = bsc and Cell.BTS_ID = bts and Cell.SECTOR = sector and Cell.OMC_ID = omc order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to retrieve LAC - given BSC,BTS,SECTOR and OMC
delimiter //
create function getLAC (bsc int,bts int,sector int,omc varchar(50)) returns int
begin
	declare rv int;
	select LAC into rv from Cell where Cell.BSC_ID = bsc and Cell.BTS_ID = bts and Cell.SECTOR = sector and Cell.OMC_ID = omc order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;

#function to retrieve MSC from BSC name
delimiter //
create function getMSC (bsc varchar(50)) returns varchar(10)
begin
	declare rv varchar(10);
	select mid(bsc,5,3) into rv;
	return rv;
end
//
delimiter ;

#function to retrieve BSC name from OMC,BSC id
delimiter //
create function getBSC_Name (bsc int,omc varchar(50)) returns varchar(20)
begin
	declare rv varchar(20);
	select TRIM(BOTH '"' from UserLabel) into rv from RnlAlcatelBSC where RnlAlcatelBSC.RnlAlcatelBSCInstanceIdentifier = bsc and RnlAlcatelBSC.OMC_ID = omc order by IMPORTDATE desc limit 1;
	return rv;
end
//
delimiter ;




#function to return region, given the BSC name (Vodacom RSA specific)
#delimiter //
#CREATE FUNCTION getRegion (bsc varchar(50)) RETURNS varchar(10)
#begin
#	declare rv varchar(10);
#	declare r varchar(1);
#	select mid(bsc,1,1) into r;
#	case r
#		when 'C' then select 'central' into rv;
#		when 'E' then select 'eastern' into rv;
#		when 'W' then select 'western' into rv;
#		else select 'unknown' into rv;
#	end case;
#	return rv;
#end
#//
#delimiter ;

#function to give DATETIME - useful for Citrix Sonar
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

#function to give DATETIME
delimiter //
create function giveDateTime (inDate date) returns datetime
begin
	declare rv datetime;
	select concat(inDate,' 00:00:00') into rv;
	return rv;
end
//
delimiter ;

#function to give start of month
delimiter //
create function giveMonthStart (inDate datetime) returns datetime
begin
	declare rv datetime;
	declare month int;
	declare year int;
	select YEAR(inDate) into year;
	select MONTH(inDate) into month;
	select concat(year,'-',month,'-01 00:00:00') into rv;
	return rv;
end
//
delimiter ;

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

#function to return yesterday's date when give the last 7 days' dates - useful for rolling weekly aggregations
delimiter //
create function giveRollingLastWeek (inDate date) returns date
begin
	declare rv date;
	declare diff int;
	declare yesterday date;
	select DATE(DATE_SUB(NOW(), interval 1 day)) into yesterday;
	select (TO_DAYS(NOW()) -TO_DAYS(inDate)) into diff;
	IF diff < 8 THEN SET rv = yesterday;
	ELSE SET rv = inDate;
	END IF;
	return rv;
end
//
delimiter ;


#function to return todays when give the last 7 days dates - useful for rolling weekly aggregations
delimiter //
create function giveRollingToday (inDate date) returns date
begin
	declare rv date;
	declare diff int;
	declare today date;
	select DATE(NOW()) into today;
	select (TO_DAYS(NOW()) -TO_DAYS(inDate)) into diff;
	IF diff < 8 THEN SET rv = today;
	ELSE SET rv = inDate;
	END IF;
	return rv;
end
//
delimiter ;
