#TRIGGERS

drop trigger if exists upd_t180_adj_h;
delimiter //
create trigger upd_t180_adj_h before insert on T180_ADJ_H
for each row
begin
	set NEW.TARGET_CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.TARGET_LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
end
//
delimiter ;

drop trigger if exists upd_lacci_t110_sector_h;
delimiter //
create trigger upd_lacci_t110_sector_h before insert on T110_SECTOR_H
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_lacci_t110_sector_d;
delimiter //
create trigger upd_lacci_t110_sector_d before insert on T110_SECTOR_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_lacci_t110_trx_h;
delimiter //
create trigger upd_lacci_t110_trx_h before insert on T110_TRX_H
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_lacci_t110_trx_d;
delimiter //
create trigger upd_lacci_t110_trx_d before insert on T110_TRX_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_mfsname_gpm_pvc_h;
delimiter //
create trigger upd_mfsname_gpm_pvc_h before insert on GPM_PVC_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
end;
//
delimiter ;


drop trigger if exists upd_gpm_cell_h;
delimiter //
create trigger upd_gpm_cell_h before insert on GPM_CELL_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_cellptu_h;
delimiter //
create trigger upd_gpm_cellptu_h before insert on GPM_CELLPTU_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_cell_D;
delimiter //
create trigger upd_gpm_cell_D before insert on GPM_CELL_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_cellptu_d;
delimiter //
create trigger upd_gpm_cellptu_d before insert on GPM_CELLPTU_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_bts_h;
delimiter //
create trigger upd_gpm_bts_h before insert on GPM_BTS_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_bts_d;
delimiter //
create trigger upd_gpm_bts_d before insert on GPM_BTS_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_lapd_h;
delimiter //
create trigger upd_gpm_lapd_h before insert on GPM_LAPD_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_lapd_d;
delimiter //
create trigger upd_gpm_lapd_d before insert on GPM_LAPD_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_distcell_h;
delimiter //
create trigger upd_gpm_distcell_h before insert on GPM_DISTCELL_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;


drop trigger if exists upd_mfsname_gpm_bc_h;
delimiter //
create trigger upd_mfsname_gpm_bc_h before insert on GPM_BEARERCHANNEL_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_bc_d;
delimiter //
create trigger upd_gpm_bc_d before insert on GPM_BEARERCHANNEL_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_bsc_h;
delimiter //
create trigger upd_gpm_bsc_h before insert on GPM_BSC_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_bsctdm_h;
delimiter //
create trigger upd_gpm_bsctdm_h before insert on GPM_BSCTDM_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_gpm_bsctdm_d;
delimiter //
create trigger upd_gpm_bsctdm_d before insert on GPM_BSCTDM_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;


drop trigger if exists upd_gpm_bsc_d;
delimiter //
create trigger upd_gpm_bsc_d before insert on GPM_BSC_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_lcscell_h;
delimiter //
create trigger upd_lcscell_h before insert on GPM_LCSCELL_H
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_lcscell_D;
delimiter //
create trigger upd_lcscell_D before insert on GPM_LCSCELL_D
for each row
begin
	set NEW.MFS_NAME = getMFS_Name(NEW.MFS,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSS,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_t31_bfi_d;
delimiter //
create trigger upd_t31_bfi_d before insert on T31_BFI_AMR_TA_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;


drop trigger if exists upd_t31_bfi_tab_d;
delimiter //
create trigger upd_t31_bfi_tab_d before insert on T31_BFI_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;


drop trigger if exists upd_t31_cell_d;
delimiter //
create trigger upd_t31_cell_d before insert on T31_CELL_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
	set NEW.TAB_PAR_MEAS_LEVEL_0 = 62;
	set NEW.TAB_PAR_MEAS_LEVEL_10 = 1;
	set NEW.TAB_PAR_MEAS_C_I_0 = 1;
	set NEW.TAB_PAR_MEAS_C_I_10 = 125;
	set NEW.TAB_PAR_MEAS_STAT_S_0 = 0;
	set NEW.TAB_PAR_MEAS_STAT_S_10 = 127;
	set NEW.TAB_PAR_MEAS_PATH_BALANCE_0 = 1;
	set NEW.TAB_PAR_MEAS_PATH_BALANCE_10 = 219;
	set NEW.TAB_PAR_MEAS_STAT_TA_0 = 1;
	set NEW.TAB_PAR_MEAS_STAT_TA_10 = 62;
	set NEW.TAB_PAR_MEAS_STAT_BFI_0 = 0;
	set NEW.TAB_PAR_MEAS_STAT_BFI_10 = 24;

end;
//
delimiter ;

drop trigger if exists upd_t31_cif_d;
delimiter //
create trigger upd_t31_cif_d before insert on T31_CIF_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_t31_cin_d;
delimiter //
create trigger upd_t31_cin_d before insert on T31_CIN_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;


drop trigger if exists upd_t31_dl_d;
delimiter //
create trigger upd_t31_dl_d before insert on T31_DL_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_t31_ul_d;
delimiter //
create trigger upd_t31_ul_d before insert on T31_UL_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;

drop trigger if exists upd_t31_trx_d;
delimiter //
create trigger upd_t31_trx_d before insert on T31_TRX_D
for each row
begin
	set NEW.CI = getCI(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.LAC = getLAC(NEW.BSC_ID,NEW.BTS_ID,NEW.SECTOR,NEW.OMC_ID);
	set NEW.BSC_NAME = getBSC_Name(NEW.BSC_ID,NEW.OMC_ID);
end;
//
delimiter ;
