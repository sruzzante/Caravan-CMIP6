args = commandArgs(trailingOnly=TRUE)
it_split = 1
numsplit = 4

it_split = as.integer(args[1])
numsplit = as.integer(args[2])

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
suppressMessages(library(MBC))
library(ncdf4)
# library(sf)
library(CFtime)
library(stringr)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
source("1.code/utils.R")
# camels factors and offsets
param_trans<-read.csv("2.data/2.working/histMetData/camels-us/param_trans_camels-daymet.csv")%>%
  filter(!var_camels == 'swe.mm.') %>%# camels data is 0 for swe.mm for all basins and times
  select(!bias_correct_target) 

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
  mutate(variable_id = case_when(variable_id == "hurs"~ "vp",
                                 variable_id == "tasmin" ~"tasminDtasmax",
                                 !variable_id %in% c("hurs","tasmin") ~variable_id))



datasets_camels<-left_join(datasets,param_trans,by = c("variable_id" = "var_CMIP6"))%>%
  mutate(var_CMIP6 = variable_id)%>%
  filter(!is.na(var_camels))%>%
  cross_join(data.frame(bias_correct_target = c("daymet","maurer","nldas")))

datasets_camels$flNm = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                               datasets_camels$source_id,
                               datasets_camels$experiment_id,
                               datasets_camels$var_camels,
                               datasets_camels$var_camels,
                               datasets_camels$source_id,
                               
                               datasets_camels$experiment_id,
                               datasets_camels$variant_label,
                               datasets_camels$bias_correct_target)


datasets_wide = datasets_camels%>%
  pivot_wider(names_from = var_camels,values_from = flNm,
              id_cols = c(source_id,experiment_id,variant_label,bias_correct_target))


datasets_wide<-datasets_wide%>%
  mutate(flNm = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/srad.W.m2./srad.W.m2._day_%s_%s_%s_uncorrected_%s.nc",
                        source_id,
                        experiment_id,
                        source_id,
                        
                        experiment_id,
                        variant_label,
                        bias_correct_target),
         flNm.dayl = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/dayl.s./dayl.s._day_%s_%s_%s_uncorrected_%s.nc",
                        source_id,
                        experiment_id,
                        source_id,
                        
                        experiment_id,
                        variant_label,
                        bias_correct_target))

datasets_wide$i<-1:nrow(datasets_wide)
# datasets_wide<-filter(datasets_wide,!is.na(hurs)&!is.na(tas))

if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
}

for(it in 1:nrow(datasets_wide)){
  
  print(sprintf( "Beginning dataset row %d, %s",datasets_wide$i[it],datasets_wide$flNm[it]))
  
  if(file.exists(datasets_wide$flNm[it])&
     file.exists(datasets_wide$flNm.dayl[it])
  ){print("already done, skipping"); next}
  
  
  targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/srad.W.m2.",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
  
  if(!dir.exists(targetDir)){
    dir.create(targetDir,recursive = T)
  } 
  
  targetDir.dayl = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/dayl.s.",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
  
  if(!dir.exists(targetDir.dayl)){
    dir.create(targetDir.dayl,recursive = T)
  } 
  
  rsds = nc_open(datasets_wide$rsds[it])
  
  
  dayl_yd<- readRDS("2.data/2.working/histMetData/camels-us/daylight_by_yday.RDS")%>%
    pivot_wider(names_from = "yd",
                values_from = "dayl.s.")
  
  
  
  rsds_mat<-ncvar_get(rsds,varid = "rsds")
  #check that gauge_ids are in the same order
  
  id_vals = (ncatt_get(rsds,"id",attname = "gauge_id")$value%>%
               str_split(pattern = ","))[[1]]%>%
    str_remove("camels_")
  
  if(!all(id_vals==dayl_yd$gauge_id)){stop("gauge ids are not the same")}
  
  
  dayl_yd_mat_small = dayl_yd%>%ungroup()%>%select(!gauge_id)%>%as.matrix()
  #   
  cf <- CFtime::CFtime(rsds$dim$time$units, rsds$dim$time$calendar, rsds$dim$time$vals)
  dts <- as_timestamp(cf,format= "date")
  cal = rsds$dim$time$calendar
  
  if(cal=="360_day"){
    mnths = substr(dts,6,7)%>%as.numeric()
    dys = substr(dts,9,10)%>%as.numeric()
    yd = (mnths-1)*30+dys
  }else{
    yd = lubridate::yday(dts)
    
  }

  
  dayl.mat = dayl_yd_mat_small[,yd]
  
  srad.W.m2._mat = rsds_mat/dayl.mat*86400
  
  srad.W.m2._mat = (srad.W.m2._mat-offsets["rsds"])*fctrs["rsds"] # hard-code offset and scale here, same as tmax
  
  # save netcdf file
  srad.W.m2._mat =  pmin(srad.W.m2._mat,32767)
  
  
  time_dim = rsds$dim$ time
  gauge_dim = rsds$dim $id
  
  
  
  cal<-time_dim$calendar
  if(cal=="360_day"){
    chunk_size = 3600
  }else{
    chunk_size = 3650
  }
  
  var_prec = "short"
  missing_value = -32768
  
  var_def <- ncvar_def(
    name  = "srad.W.m2.",
    longname = "Incident shortwave radiation flux density in watts per square meter, taken as an average over the daylight period of the day.",
    # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
    units ="W m-2",
    dim   = list(gauge_dim, time_dim),
    missval = missing_value,
    # longname = longnames(xRast),
    prec = var_prec,
    shuffle = T,
    compression = 9,
    chunk = c(100, chunk_size)
  )
  
  nc<-nc_create(datasets_wide$flNm[it],
                vars = list(var_def))
  
  ncatt_put(nc, "srad.W.m2.",  "scale_factor", 1/fctrs["rsds"])
  ncatt_put(nc,"srad.W.m2.", "add_offset", offsets["rsds"])
  
  
  ncvar_put(nc, var_def, srad.W.m2._mat)
  
  # copy over some attributes from CMIP6
  
  ncatt_put(nc, "id", "gauge_id", ncatt_get(rsds,"id",attname = "gauge_id")$value)
  ncatt_put(nc, 0, "institution_id",ncatt_get(rsds,0,attname = "institution_id")$value)
  ncatt_put(nc, 0, "institution",ncatt_get(rsds,0,attname = "institution")$value)
  ncatt_put(nc, 0, "source_id",ncatt_get(rsds,0,attname = "source_id")$value)
  ncatt_put(nc, 0, "source",ncatt_get(rsds,0,attname = "source")$value)
  ncatt_put(nc, 0, "experiment_id",ncatt_get(rsds,0,attname = "experiment_id")$value)
  ncatt_put(nc, 0, "variant_label", ncatt_get(rsds,0,attname = "variant_label")$value)
  ncatt_put(nc, 0, "grid_label",ncatt_get(rsds,0,attname = "grid_label")$value)
  ncatt_put(nc, 0, "grid",ncatt_get(rsds,0,attname = "grid")$value)
  
  
  ncatt_put(nc, 0, "license_GCM",ncatt_get(rsds,0,attname = "license")$value)
  ncatt_put(nc, 0, "Conventions",ncatt_get(rsds,0,attname = "Conventions")$value)
  ncatt_put(nc, 0, "contact",ncatt_get(rsds,0,attname = "Contact")$value)
  ncatt_put(nc, 0, "further_info_url",ncatt_get(rsds,0,attname = "further_info_url")$value)
  
  ncatt_put(nc, 0, "Bias_Correction",ncatt_get(rsds,0,attname = "Bias_Correction")$value)
  
  nc_close(nc)
  
  ### create dayl.s. file
  dayl.mat.offset = dayl.mat-30000 # offset. this setting is not safe for all locations, but works for CONUS latitudes
  
  
  var_def.dayl <- ncvar_def(
    name  = "dayl.s.",
    longname = "Duration of the daylight period in seconds per day. This calculation is based on the period of the day during which the sun is above a hypothetical flat horizon.",
    # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
    units ="s",
    dim   = list(gauge_dim, time_dim),
    missval = missing_value,
    # longname = longnames(xRast),
    prec = var_prec,
    shuffle = T,
    compression = 9,
    chunk = c(100, chunk_size)
  )
  
  nc.dayl<-nc_create(datasets_wide$flNm.dayl[it],
                vars = list(var_def.dayl))
  
  ncatt_put(nc.dayl, "dayl.s.",  "scale_factor", 1)
  ncatt_put(nc.dayl,"dayl.s.", "add_offset",30000)
  
  
  ncvar_put(nc.dayl, var_def.dayl, dayl.mat.offset)
  
  # copy over some attributes from CMIP6
  
  ncatt_put(nc.dayl, "id", "gauge_id", ncatt_get(rsds,"id",attname = "gauge_id")$value)
  ncatt_put(nc.dayl, 0, "institution_id",ncatt_get(rsds,0,attname = "institution_id")$value)
  ncatt_put(nc.dayl, 0, "institution",ncatt_get(rsds,0,attname = "institution")$value)
  ncatt_put(nc.dayl, 0, "source_id",ncatt_get(rsds,0,attname = "source_id")$value)
  ncatt_put(nc.dayl, 0, "source",ncatt_get(rsds,0,attname = "source")$value)
  ncatt_put(nc.dayl, 0, "experiment_id",ncatt_get(rsds,0,attname = "experiment_id")$value)
  ncatt_put(nc.dayl, 0, "variant_label", ncatt_get(rsds,0,attname = "variant_label")$value)
  ncatt_put(nc.dayl, 0, "grid_label",ncatt_get(rsds,0,attname = "grid_label")$value)
  ncatt_put(nc.dayl, 0, "grid",ncatt_get(rsds,0,attname = "grid")$value)
  
  
  ncatt_put(nc.dayl, 0, "license_GCM",ncatt_get(rsds,0,attname = "license")$value)
  ncatt_put(nc.dayl, 0, "Conventions",ncatt_get(rsds,0,attname = "Conventions")$value)
  ncatt_put(nc.dayl, 0, "contact",ncatt_get(rsds,0,attname = "Contact")$value)
  ncatt_put(nc.dayl, 0, "further_info_url",ncatt_get(rsds,0,attname = "further_info_url")$value)
  
 
  ncatt_put(nc.dayl, 0, "Bias_Correction",ncatt_get(rsds,0,attname = "Bias_Correction")$value)
  
  
  nc_close(rsds)
  nc_close(nc.dayl)
  
}

