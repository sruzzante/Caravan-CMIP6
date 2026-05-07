# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script calculates the surface longwave radiation (rss) from the raw climate data


args = commandArgs(trailingOnly=TRUE)
it_split = 1
numsplit = 5


it_split = as.integer(args[1])
numsplit = as.integer(args[2])
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
# setwd(paste0(Sys.getenv("USERPROFILE"), "/OneDrive - University of Victoria/low-flows-BC/")) #Set the working directory


suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(terra))
suppressMessages(library(lubridate))
suppressMessages(library(tictoc))
library(stringr)
library(ncdf4)
source("1.code/utils.R")



datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")

datasets<-datasets%>%
  mutate(
    fileName = paste(
      variable_id,"day",source_id,experiment_id,variant_label,
      grid_label,".*.nc",
      sep ="_"
    ),
    filePathExtracted = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",source_id,experiment_id,variable_id, sep= "/"),
    
    fileNameExtracted  =  paste(
      variable_id,"day",source_id,
      experiment_id,variant_label,
      grid_label,"uncorrected.nc",
      
      sep ="_"
    ))%>%
  mutate(fileName = case_when(str_detect(src_folder,"CFday")~str_replace(fileName,"day","CFday"),
                              !str_detect(src_folder,"CFday") ~fileName))


datasets_wide<-datasets%>%
  mutate(uncorrectedFile = paste(filePathExtracted,fileNameExtracted,sep = "/"))%>%
  pivot_wider(id_cols = c(project,activity_id,institution_id,source_id,experiment_id,variant_label,frequency,grid_label),
              values_from =uncorrectedFile,
              names_from = variable_id)



datasets_wide$i<-1:nrow(datasets_wide)

if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
  
}
datasets_wide<-filter(datasets_wide,!is.na(rlus)&!is.na(rlds))
for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in 1:10){
     
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets_wide$i[it],datasets_wide$rlds[it],it_sub))
    
    targetDir = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    }
    
    # net longwave radiation
    flNm = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                 datasets_wide$source_id[it],
                 datasets_wide$experiment_id[it],
                 "rls",
                 paste(
                   "rls",
                   "day",
                   datasets_wide$source_id[it],
                   datasets_wide$experiment_id[it],
                   datasets_wide$variant_label[it],
                   datasets_wide$grid_label[it],
                   "uncorrected",
                   paste0(it_sub,
                          ".nc"),
                   
                   sep ="_"
                 ),
                 sep= "/"
    )
    if(file.exists(flNm)){
      print("already calculated, skipping")
      next
    }
    
    
    rlds<-nc_open(datasets_wide$rlds[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    dts_rlds<- CFtime::CFtime(rlds$dim$time$units, rlds$dim$time$calendar, rlds$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    
    rlus<-nc_open(datasets_wide$rlus[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    dts_rlus<- CFtime::CFtime(rlus$dim$time$units, rlus$dim$time$calendar, rlus$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    
    msk_rlds<-dts_rlds%in%dts_rlus
    msk_rlus<-dts_rlus%in%dts_rlds
    
    
    rlds_mat<-ncvar_get(rlds,varid = "rlds")[,msk_rlds]
    rlus_mat<-ncvar_get(rlus,varid = "rlus")[,msk_rlus]
    rls_mat<-rlds_mat-rlus_mat
    
    rls_mat<-(rls_mat-offsets[["rls"]])*fctrs[["rls"]]
    
    # create rls ncdf file
    # get attributes from rlds file
    
    cal<-rlus$dim$time$calendar
    
    time_dim <- rlus$dim$time
    
    gauge_dim <- rlus$dim$id
    
    
    
    
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    
    var_def <- ncvar_def(
      name  = "rls",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "W m-2",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Net Shortwave Surface Radiation",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    rls <- nc_create(paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                           datasets_wide$source_id[it],
                           datasets_wide$experiment_id[it],
                         "rls",
                          paste(
                            "rls",
                            "day",
                            datasets_wide$source_id[it],
                            datasets_wide$experiment_id[it],
                            datasets_wide$variant_label[it],
                            datasets_wide$grid_label[it],
                            "uncorrected",
                            paste0(it_sub,
                                   ".nc"),
                            
                            sep ="_"
                          ),
                          sep= "/"
    ),
    vars = list(var_def))
    
    ncvar_put(rls, var_def, rls_mat)
    
    
    # ncvar_put(nc, gauge_var, id_vals)
    # ncvar_put(nc, gauge_var, id_char)
    
    
    ncatt_put(rls, "id", "gauge_id", ncatt_get(rlds,varid = "id",attname = "gauge_id")$value)
    ncatt_put(rls, 0, "institution_id",ncatt_get(rlds,0,attname = "institution_id")$value)
    ncatt_put(rls, 0, "institution",ncatt_get(rlds,0,attname = "institution")$value)
    ncatt_put(rls, 0, "source_id",ncatt_get(rlds,0,attname = "source_id")$value)
    ncatt_put(rls, 0, "source",ncatt_get(rlds,0,attname = "source")$value)
    ncatt_put(rls, 0, "experiment_id",ncatt_get(rlds,0,attname = "experiment_id")$value)
    ncatt_put(rls, 0, "variant_label", ncatt_get(rlds,0,attname = "variant_label")$value)
    ncatt_put(rls, 0, "grid_label",ncatt_get(rlds,0,attname = "grid_label")$value)
    ncatt_put(rls, 0, "grid",ncatt_get(rlds,0,attname = "grid")$value)
    
    
    ncatt_put(rls, 0, "license",ncatt_get(rlds,0,attname = "license")$value)
    ncatt_put(rls, 0, "Conventions",ncatt_get(rlds,0,attname = "Conventions")$value)
    ncatt_put(rls, 0, "contact",ncatt_get(rlds,0,attname = "Contact")$value)
    ncatt_put(rls, 0, "further_info_url",ncatt_get(rlds,0,attname = "further_info_url")$value)
    
    ncatt_put(rls, "rls", "scale_factor", 1/fctrs["rls"])
    ncatt_put(rls,"rls", "add_offset", offsets["rls"])
    
    
    
    nc_close(rls)
    
    nc_close(rlus)
    
    nc_close(rlds)
    
    
    
  }
}




