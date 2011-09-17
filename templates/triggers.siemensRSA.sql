#TRIGGERS
delimiter //
create trigger upd_region_umtsalarms before insert on UmtsAlarms
for each row
begin
	set NEW.Region = mid(NEW.NetworkElement,-3);
	set NEW.SubRegion = mid(NEW.NetworkElement,-3);
	set NEW.Date_Time = concat(NEW.AlarmDate,' ',mid(NEW.AlarmTime,1,2));
end;
//
delimiter ;