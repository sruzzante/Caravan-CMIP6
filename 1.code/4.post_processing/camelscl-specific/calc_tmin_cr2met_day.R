

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
param_trans<-read.csv("2.data/2.working/histMetData/camels-cl/param_trans_camels_cl.csv")

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
  rbind(readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
          filter(variable_id %in% c("tasmax","tasmin"))%>%
          mutate(variable_id = case_when(variable_id == "tasmin" ~"tasminD",
                                         variable_id == "tasmax" ~"tasmaxD")))



datasets_camels<-left_join(datasets,param_trans,by = c("variable_id" = "var_CMIP6"))%>%
  mutate(var_CMIP6 = variable_id)%>%
  filter(!is.na(var_camels))



datasets_camels$flNm = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels-cl/%s/%s/%s/%s_day_%s_%s_%s.nc",
                               datasets_camels$source_id,
                               datasets_camels$experiment_id,
                               datasets_camels$var_camels,
                               datasets_camels$var_camels,
                               datasets_camels$source_id,
                               
                               datasets_camels$experiment_id,
                               datasets_camels$variant_label)


datasets_wide = datasets_camels%>%
  pivot_wider(names_from = var_camels,values_from = flNm,
              id_cols = c(source_id,experiment_id,variant_label))



datasets_wide$i<-1:nrow(datasets_wide)
# datasets_wide<-filter(datasets_wide,!is.na(hurs)&!is.na(tas))

# if(numsplit>1){
#   x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
#   datasets_wide<-datasets_wide[x[[it_split]],]
# }

for(it in 1:nrow(datasets_wide)){
  
  print(sprintf( "Beginning dataset row %d, %s",datasets_wide$i[it],datasets_wide$tmin_cr2met_C_day[it]))
  if(file.exists(datasets_wide$tmin_cr2met_C_day[it])){
    print("already done, skipping")
    next
  }
  
  tic()
  targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels-cl/%s/%s/tmin_cr2met_C_day",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
  
  if(!dir.exists(targetDir)){
    dir.create(targetDir,recursive = T)
  } 
  
  tmean.C. = nc_open(datasets_wide$tmean_cr2met_C_day[it])
  
  tmin.C.diff = nc_open(datasets_wide$tmin_cr2met_C_day_diff[it])
  
  
  
  tmean.C._mat<-ncvar_get(tmean.C.,varid = "tmean_cr2met_C_day")
  # tasC_mat = tas_mat-273.15
  tmin.C.diff_mat<-ncvar_get(tmin.C.diff,varid = "tmin_cr2met_C_day_diff")
  
  # tmin.C.diff_mat[tmin.C.diff_mat>0] = 0 # ensure difference is always < 0
  
  tmin.C._mat = (tmean.C._mat+tmin.C.diff_mat)
  
  tmin.C._mat = (tmin.C._mat-0)*100 # hard-code offset and scale here, same as tmean
  
  # save netcdf file
  
  
  time_dim = tmean.C.$dim$ time
  gauge_dim = tmean.C.$dim $id
  
  
  
  cal<-time_dim$calendar
  if(cal=="360_day"){
    chunk_size = 3600
  }else{
    chunk_size = 3650
  }
  
  var_prec = "short"
  missing_value = -32768
  
  var_def <- ncvar_def(
    name  = "tmin_cr2met_C_day",
    longname = "Daily minimum temperature from CR2METv1.3",
    # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
    units ="°C",
    dim   = list(gauge_dim, time_dim),
    missval = missing_value,
    # longname = longnames(xRast),
    prec = var_prec,
    shuffle = T,
    compression = 9,
    chunk = c(100, chunk_size)
  )
  
  nc<-nc_create(datasets_wide$tmin_cr2met_C_day[it],
                vars = list(var_def))
  
  ncatt_put(nc, "tmin_cr2met_C_day",  "scale_factor", 1/100)
  ncatt_put(nc,"tmin_cr2met_C_day", "add_offset", 0)
  
  
  ncvar_put(nc, var_def, tmin.C._mat)
  
  # copy over some attributes from CMIP6
  
  ncatt_put(nc, "id", "gauge_id", ncatt_get(tmean.C.,"id",attname = "gauge_id")$value)
  ncatt_put(nc, 0, "institution_id",ncatt_get(tmean.C.,0,attname = "institution_id")$value)
  ncatt_put(nc, 0, "institution",ncatt_get(tmean.C.,0,attname = "institution")$value)
  ncatt_put(nc, 0, "source_id",ncatt_get(tmean.C.,0,attname = "source_id")$value)
  ncatt_put(nc, 0, "source",ncatt_get(tmean.C.,0,attname = "source")$value)
  ncatt_put(nc, 0, "experiment_id",ncatt_get(tmean.C.,0,attname = "experiment_id")$value)
  ncatt_put(nc, 0, "variant_label", ncatt_get(tmean.C.,0,attname = "variant_label")$value)
  ncatt_put(nc, 0, "grid_label",ncatt_get(tmean.C.,0,attname = "grid_label")$value)
  ncatt_put(nc, 0, "grid",ncatt_get(tmean.C.,0,attname = "grid")$value)
  
  
  ncatt_put(nc, 0, "license_GCM",ncatt_get(tmean.C.,0,attname = "license")$value)
  ncatt_put(nc, 0, "Conventions",ncatt_get(tmean.C.,0,attname = "Conventions")$value)
  ncatt_put(nc, 0, "contact",ncatt_get(tmean.C.,0,attname = "Contact")$value)
  ncatt_put(nc, 0, "further_info_url",ncatt_get(tmean.C.,0,attname = "further_info_url")$value)
  
  ncatt_put(nc, 0, "Bias_Correction",ncatt_get(tmean.C.,0,attname = "Bias_Correction")$value)
  
  
  nc_close(tmean.C.)
  nc_close(tmin.C.diff)
  nc_close(nc)
  toc()
  
}

