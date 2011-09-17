#TRIGGERS

delimiter //
create trigger upd_bs_mac_h before insert on BS_MAC_H
for each row
begin
	set NEW.BSID = NEW.MAC;
end;
//
delimiter ;

delimiter //
create trigger upd_bs_mac_d before insert on BS_MAC_D
for each row
begin
	set NEW.BSID = NEW.MAC;
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_bs_ms_phy_h before insert on BS_MS_PHY_H
for each row
begin
	set NEW.BSID = NEW.MS_PHY;
end;
//
delimiter ;

delimiter //
create trigger upd_bs_ms_phy_d before insert on BS_MS_PHY_D
for each row
begin
	set NEW.BSID = NEW.MS_PHY;
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_bs_phy_h before insert on BS_PHY_H
for each row
begin
	set NEW.BSID = NEW.PHY;
end;
//
delimiter ;

delimiter //
create trigger upd_bs_phy_d before insert on BS_PHY_D
for each row
begin
	set NEW.BSID = NEW.PHY;
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_wac_bs_h before insert on WAC_BS_H
for each row
begin
	set NEW.BSID = NEW.BS;
end;
//
delimiter ;

delimiter //
create trigger upd_wac_bs_d before insert on WAC_BS_D
for each row
begin
	set NEW.BSID = NEW.BS;
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_bscell_csn_link_h before insert on BS_BSCELL_CSN_LINK_H
for each row
begin
	set NEW.BSID = substr(NEW.BSCELL_CSN_LINK,1,INSTR(NEW.BSCELL_CSN_LINK,'/')-1);
	set NEW.CSN_LINK = substr(NEW.BSCELL_CSN_LINK,INSTR(NEW.BSCELL_CSN_LINK,'/')+1);
end;
//
delimiter ;

delimiter //
create trigger upd_bscell_csn_link_d before insert on BS_BSCELL_CSN_LINK_D
for each row
begin
	set NEW.BSID = substr(NEW.BSCELL_CSN_LINK,1,INSTR(NEW.BSCELL_CSN_LINK,'/')-1);
	set NEW.CSN_LINK = substr(NEW.BSCELL_CSN_LINK,INSTR(NEW.BSCELL_CSN_LINK,'/')+1);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_waccls before insert on WACCLBS
for each row
begin
	set NEW.BSID = getBSID(NEW.NAME);
end;
//
delimiter ;

delimiter //
create trigger upd_wac_aaa_d before insert on WAC_AAA_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_wac_wac_d before insert on WAC_WAC_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_wac_processor_d before insert on WAC_Processor_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_wac_physicallink_d before insert on WAC_PhysicalLink_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_WAC_BSCELL_CSN_LINK_D_d before insert on WAC_BSCELL_CSN_LINK_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

delimiter //
create trigger upd_WAC_WAC_CSN_LINK_D_d before insert on WAC_WAC_CSN_LINK_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;