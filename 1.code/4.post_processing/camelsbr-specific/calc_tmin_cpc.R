args = commandArgs(trailingOnly=TRUE)
it_split = 1
numsplit = 5

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

params<-read.csv("2.data/2.working/histMetData/camels-br/param_trans_camels_br.csv")%>%
  # filter(final_var)%>%
  mutate(data_type = "int16",
         fill_value = -32768)

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")
datasets = rbind(datasets,
                 datasets%>%filter(variable_id == "tasmax")%>%mutate(variable_id="tasmaxD"),
                 datasets%>%filter(variable_id == "tasmin")%>%mutate(variable_id="tasminD"),
                 datasets%>%filter(variable_id == "tasmin")%>%mutate(variable_id="tasminDtasmax"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="petfao56")
)




datasets_camels<-left_join(datasets,params,by = c("variable_id" = "var_CMIP6"))%>%
  mutate(var_CMIP6 = variable_id)%>%
  filter(!is.na(var_camels))%>%
  filter(var_camels %in% c('tmin_cpcDiff','tmin_cpc', "tmax_cpc"))

datasets_camels$flNm = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels-br/%s/%s/%s/%s_day_%s_%s_%s.nc",
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

if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
}

for(it in 1:nrow(datasets_wide)){
  
  print(sprintf( "Beginning dataset row %d, %s",datasets_wide$i[it],datasets_wide$tmin_cpc[it]))
  
  if(file.exists(datasets_wide$tmin_cpc[it])){
    print("already done, skipping")
    next
  }
  tic()
  targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels-br/%s/%s/tmin_cpc",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
  
  if(!dir.exists(targetDir)){
    dir.create(targetDir,recursive = T)
  } 
  
  tmax.C. = nc_open(datasets_wide$tmax_cpc[it])
  
  tmin.C.diff = nc_open(datasets_wide$tmin_cpcDiff[it])
  
  
  
  tmax.C._mat<-ncvar_get(tmax.C.,varid = "tmax_cpc")
  # tasC_mat = tas_mat-273.15
  tmin.C.diff_mat<-ncvar_get(tmin.C.diff,varid = "tmin_cpcDiff")
  
  # tmin.C.diff_mat[tmin.C.diff_mat>0] = 0 # ensure difference is always < 0
  
  tmin.C._mat = (tmax.C._mat+tmin.C.diff_mat)
  
  tmin.C._mat = (tmin.C._mat-0)*100 # hard-code offset and scale here, same as tmax
  
  # save netcdf file
  
  
  time_dim = tmax.C.$dim$ time
  gauge_dim = tmax.C.$dim $id
  

  
  cal<-time_dim$calendar
  if(cal=="360_day"){
    chunk_size = 3600
  }else{
    chunk_size = 3650
  }
  
  var_prec = "short"
  missing_value = -32768
  
  var_def <- ncvar_def(
    name  = "tmin_cpc",
    longname = "Daily minimum temperature from CPC",
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
  
  nc<-nc_create(datasets_wide$tmin_cpc[it],
                vars = list(var_def))
  
  ncatt_put(nc, "tmin_cpc",  "scale_factor", 1/100)
  ncatt_put(nc,"tmin_cpc", "add_offset", 0)
  
  
  ncvar_put(nc, var_def, tmin.C._mat)
  
  # copy over some attributes from CMIP6
  
  ncatt_put(nc, "id", "gauge_id", ncatt_get(tmax.C.,"id",attname = "gauge_id")$value)
  ncatt_put(nc, 0, "institution_id",ncatt_get(tmax.C.,0,attname = "institution_id")$value)
  ncatt_put(nc, 0, "institution",ncatt_get(tmax.C.,0,attname = "institution")$value)
  ncatt_put(nc, 0, "source_id",ncatt_get(tmax.C.,0,attname = "source_id")$value)
  ncatt_put(nc, 0, "source",ncatt_get(tmax.C.,0,attname = "source")$value)
  ncatt_put(nc, 0, "experiment_id",ncatt_get(tmax.C.,0,attname = "experiment_id")$value)
  ncatt_put(nc, 0, "variant_label", ncatt_get(tmax.C.,0,attname = "variant_label")$value)
  ncatt_put(nc, 0, "grid_label",ncatt_get(tmax.C.,0,attname = "grid_label")$value)
  ncatt_put(nc, 0, "grid",ncatt_get(tmax.C.,0,attname = "grid")$value)
  
  
  ncatt_put(nc, 0, "license_GCM",ncatt_get(tmax.C.,0,attname = "license")$value)
  ncatt_put(nc, 0, "Conventions",ncatt_get(tmax.C.,0,attname = "Conventions")$value)
  ncatt_put(nc, 0, "contact",ncatt_get(tmax.C.,0,attname = "Contact")$value)
  ncatt_put(nc, 0, "further_info_url",ncatt_get(tmax.C.,0,attname = "further_info_url")$value)
  
  ncatt_put(nc, 0, "Bias_Correction",ncatt_get(tmax.C.,0,attname = "Bias_Correction")$value)
  
  
  nc_close(tmax.C.)
  nc_close(tmin.C.diff)
  nc_close(nc)
  toc()
  
}
