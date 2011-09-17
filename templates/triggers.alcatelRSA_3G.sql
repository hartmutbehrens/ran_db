#TRIGGERS

drop trigger if exists upd_rnccn_utrancell_h;
delimiter //
create trigger upd_rnccn_utrancell_h before insert on RNCCN_UTRANCELL_H
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
end;
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a1_h;
delimiter //
create trigger upd_rnccn_utrancell_a1_h before insert on RNCCN_UTRANCELL_A1_H
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
end;
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a2_h;
delimiter //
create trigger upd_rnccn_utrancell_a2_h before insert on RNCCN_UTRANCELL_A2_H
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a3_h;
delimiter //
create trigger upd_rnccn_utrancell_a3_h before insert on RNCCN_UTRANCELL_A3_H
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a4_h;
delimiter //
create trigger upd_rnccn_utrancell_a4_h before insert on RNCCN_UTRANCELL_A4_H
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a5_h;
delimiter //
create trigger upd_rnccn_utrancell_a5_h before insert on RNCCN_UTRANCELL_A5_H
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_d;
delimiter //
create trigger upd_rnccn_utrancell_d before insert on RNCCN_UTRANCELL_D
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
	set NEW.GRANULARITY = '86400';
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a1_d;
delimiter //
create trigger upd_rnccn_utrancell_a1_d before insert on RNCCN_UTRANCELL_A1_D
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
	set NEW.GRANULARITY = '86400';
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a2_d;
delimiter //
create trigger upd_rnccn_utrancell_a2_d before insert on RNCCN_UTRANCELL_A2_D
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
	set NEW.GRANULARITY = '86400';
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a3_d;
delimiter //
create trigger upd_rnccn_utrancell_a3_d before insert on RNCCN_UTRANCELL_A3_D
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
	set NEW.GRANULARITY = '86400';
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a4_d;
delimiter //
create trigger upd_rnccn_utrancell_a4_d before insert on RNCCN_UTRANCELL_A4_D
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
	set NEW.GRANULARITY = '86400';
end
//
delimiter ;

drop trigger if exists upd_rnccn_utrancell_a5_d;
delimiter //
create trigger upd_rnccn_utrancell_a5_d before insert on RNCCN_UTRANCELL_A5_D
for each row
begin
	set NEW.CI = getCellId_Cell(NEW.UtranCell);
	set NEW.LAC = getLocationCode_Cell(NEW.UtranCell);
	set NEW.NodeBName = getNodeBfromCell(NEW.CI,NEW.LAC);
	set NEW.GRANULARITY = '86400';
end
//
delimiter ;

drop trigger if exists upd_rnccn_tmu_d;
delimiter //
create trigger upd_rnccn_tmu_d before insert on RNCCN_TMU_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_neighbouringrnc_d;
delimiter //
create trigger upd_rnccn_neighbouringrnc_d before insert on RNCCN_NEIGHBOURINGRNC_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_neighbouringrnc_a1_d;
delimiter //
create trigger upd_rnccn_neighbouringrnc_a1_d before insert on RNCCN_NEIGHBOURINGRNC_A1_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_neighbouringrnc_a2_d;
delimiter //
create trigger upd_rnccn_neighbouringrnc_a2_d before insert on RNCCN_NEIGHBOURINGRNC_A2_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_iubifaal2_d; 
delimiter //
create trigger upd_rnccn_iubifaal2_d before insert on RNCCN_IUBIFAAL2_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_function_d; 
delimiter //
create trigger upd_rnccn_function_d before insert on RNCCN_RNCFUNCTION_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_function_a1_d;
delimiter //
create trigger upd_rnccn_function_a1_d before insert on RNCCN_RNCFUNCTION_A1_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_rnccn_function_a2_d;
delimiter //
create trigger upd_rnccn_function_a2_d before insert on RNCCN_RNCFUNCTION_A2_D
for each row
begin
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_btscell_h;
delimiter //
create trigger upd_nodeb_btscell_h before insert on NODEB_BTSCELL_H
for each row
begin
	set NEW.CI = getCellId(NEW.NAME,NEW.BtsCell);
	set NEW.LAC = getLocationCode(NEW.NAME,NEW.BtsCell);
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_btscell_d;
delimiter //
create trigger upd_nodeb_btscell_d before insert on NODEB_BTSCELL_D
for each row
begin
	set NEW.CI = getCellId(NEW.NAME,NEW.BtsCell);
	set NEW.LAC = getLocationCode(NEW.NAME,NEW.BtsCell);
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_hsservice_h;
delimiter //
create trigger upd_nodeb_hsservice_h before insert on NODEB_HSDPASERVICE_H
for each row
begin
	set NEW.CI = getCellId(NEW.NAME,NEW.BtsCell);
	set NEW.LAC = getLocationCode(NEW.NAME,NEW.BtsCell);
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_hsservice_a1_h;
delimiter //
create trigger upd_nodeb_hsservice_a1_h before insert on NODEB_HSDPASERVICE_A1_H
for each row
begin
	set NEW.CI = getCellId(NEW.NAME,NEW.BtsCell);
	set NEW.LAC = getLocationCode(NEW.NAME,NEW.BtsCell);
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_hsservice_d;
delimiter //
create trigger upd_nodeb_hsservice_d before insert on NODEB_HSDPASERVICE_D
for each row
begin
	set NEW.CI = getCellId(NEW.NAME,NEW.BtsCell);
	set NEW.LAC = getLocationCode(NEW.NAME,NEW.BtsCell);
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_hsservice_a1_d;
delimiter //
create trigger upd_nodeb_hsservice_a1_d before insert on NODEB_HSDPASERVICE_A1_D
for each row
begin
	set NEW.CI = getCellId(NEW.NAME,NEW.BtsCell);
	set NEW.LAC = getLocationCode(NEW.NAME,NEW.BtsCell);
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_imagroup_h;
delimiter //
create trigger upd_nodeb_imagroup_h before insert on NODEB_IMAGROUP_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_imagroup_d;
delimiter //
create trigger upd_nodeb_imagroup_d before insert on NODEB_IMAGROUP_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;


drop trigger if exists upd_nodeb_aal2_h;
delimiter //
create trigger upd_nodeb_aal2_h before insert on NODEB_AAL2_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_aal2_d;
delimiter //
create trigger upd_nodeb_aal2_d before insert on NODEB_AAL2_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_aal5_h;
delimiter //
create trigger upd_nodeb_aal5_h before insert on NODEB_AAL5_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_aal5_d;
delimiter //
create trigger upd_nodeb_aal5_d before insert on NODEB_AAL5_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;


drop trigger if exists upd_nodeb_atm_h;
delimiter //
create trigger upd_nodeb_atm_h before insert on NODEB_ATM_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_atm_d;
delimiter //
create trigger upd_nodeb_atm_d before insert on NODEB_ATM_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_ccm_h;
delimiter //
create trigger upd_nodeb_ccm_h before insert on NODEB_CCM_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_ccm_d;
delimiter //
create trigger upd_nodeb_ccm_d before insert on NODEB_CCM_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_cem_h;
delimiter //
create trigger upd_nodeb_cem_h before insert on NODEB_CEM_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_cem_d;
delimiter //
create trigger upd_nodeb_cem_d before insert on NODEB_CEM_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_hsresource_h;
delimiter //
create trigger upd_nodeb_hsresource_h before insert on NODEB_HSDPARESOURCE_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_hsresource_d;
delimiter //
create trigger upd_nodeb_hsresource_d before insert on NODEB_HSDPARESOURCE_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_ip_h;
delimiter //
create trigger upd_nodeb_ip_h before insert on NODEB_IPINTERFACE_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_ipran_h;
delimiter //
create trigger upd_nodeb_ipran_h before insert on NODEB_IPRAN_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_ipran_d;
delimiter //
create trigger upd_nodeb_ipran_d before insert on NODEB_IPRAN_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_ip_d;
delimiter //
create trigger upd_nodeb_ip_d before insert on NODEB_IPINTERFACE_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_lcellgroup_h;
delimiter //
create trigger upd_nodeb_lcellgroup_h before insert on NODEB_LOCALCELLGROUP_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_lcellgroup_d;
delimiter //
create trigger upd_nodeb_lcellgroup_d before insert on NODEB_LOCALCELLGROUP_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_equip_h;
delimiter //
create trigger upd_nodeb_equip_h before insert on NODEB_NODEBEQUIPMENT_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_equip_d;
delimiter //
create trigger upd_nodeb_equip_d before insert on NODEB_NODEBEQUIPMENT_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_passive_h;
delimiter //
create trigger upd_nodeb_passive_h before insert on NODEB_PASSIVECOMPONENTPA_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_passive_d;
delimiter //
create trigger upd_nodeb_passive_d before insert on NODEB_PASSIVECOMPONENTPA_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_pcm_h;
delimiter //
create trigger upd_nodeb_pcm_h before insert on NODEB_PCMLINK_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_pcm_d;
delimiter //
create trigger upd_nodeb_pcm_d before insert on NODEB_PCMLINK_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_trm_h;
delimiter //
create trigger upd_nodeb_trm_h before insert on NODEB_TRM_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;

drop trigger if exists upd_nodeb_trm_d;
delimiter //
create trigger upd_nodeb_trm_d before insert on NODEB_TRM_D
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
	set NEW.GRANULARITY = '86400';
end;
//
delimiter ;

drop trigger if exists upd_nodeb_rrh_h;
delimiter //
create trigger upd_nodeb_rrh_h before insert on NODEB_RRH_H
for each row
begin
	set NEW.RncName = getRncfromNodeB(NEW.NAME);
end;
//
delimiter ;


