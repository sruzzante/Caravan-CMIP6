# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script calculates the net surface shorwave radiation (rss) from the raw climate data

args = commandArgs(trailingOnly=TRUE)
it_split = 1
numsplit = 1


#it_split = as.integer(args[1])
#numsplit = as.integer(args[2])
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
datasets_wide<-filter(datasets_wide,is.na(rss)&!is.na(rsus)&!is.na(rsds))
for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in 1:10){
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets_wide$i[it],datasets_wide$rsds[it],it_sub))
    
    targetDir = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rss",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    }
    
    # net shortwave radiation
    flNm = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                 datasets_wide$source_id[it],
                 datasets_wide$experiment_id[it],
                 "rss",
                 paste(
                   "rss",
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
    
    rsds<-nc_open(datasets_wide$rsds[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    dts_rsds<- CFtime::CFtime(rsds$dim$time$units, rsds$dim$time$calendar, rsds$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    rsus<-nc_open(datasets_wide$rsus[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    dts_rsus<- CFtime::CFtime(rsus$dim$time$units, rsus$dim$time$calendar, rsus$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    
    msk_rsds<-dts_rsds%in%dts_rsus
    msk_rsus<-dts_rsus%in%dts_rsds
    
    rsds_mat<-ncvar_get(rsds,varid = "rsds")[,msk_rsds]
    rsus_mat<-ncvar_get(rsus,varid = "rsus")[,msk_rsus]
    rss_mat<-rsds_mat-rsus_mat
    
    rss_mat<-(rss_mat-offsets[["rss"]])*fctrs[["rss"]]
    
    # create rss ncdf file
    # get attributes from rsus file
    
    
    cal<-rsus$dim$time$calendar
    
    time_dim <- rsus$dim$time
    
    gauge_dim <- rsus$dim$id
    
    
    
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    
    var_def <- ncvar_def(
      name  = "rss",
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
    
    rss <- nc_create(paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                           datasets_wide$source_id[it],
                           datasets_wide$experiment_id[it],
                           "rss",
                           paste(
                             "rss",
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
    
    ncvar_put(rss, var_def, rss_mat)
    
    
    # ncvar_put(nc, gauge_var, id_vals)
    # ncvar_put(nc, gauge_var, id_char)
    
    
    ncatt_put(rss, "id", "gauge_id",ncatt_get(rsds,varid = "id",attname = "gauge_id")$value)
    ncatt_put(rss, 0, "institution_id",ncatt_get(rsds,0,attname = "institution_id")$value)
    ncatt_put(rss, 0, "institution",ncatt_get(rsds,0,attname = "institution")$value)
    ncatt_put(rss, 0, "source_id",ncatt_get(rsds,0,attname = "source_id")$value)
    ncatt_put(rss, 0, "source",ncatt_get(rsds,0,attname = "source")$value)
    ncatt_put(rss, 0, "experiment_id",ncatt_get(rsds,0,attname = "experiment_id")$value)
    ncatt_put(rss, 0, "variant_label", ncatt_get(rsds,0,attname = "variant_label")$value)
    ncatt_put(rss, 0, "grid_label",ncatt_get(rsds,0,attname = "grid_label")$value)
    ncatt_put(rss, 0, "grid",ncatt_get(rsds,0,attname = "grid")$value)
    
    
    ncatt_put(rss, 0, "license",ncatt_get(rsds,0,attname = "license")$value)
    ncatt_put(rss, 0, "Conventions",ncatt_get(rsds,0,attname = "Conventions")$value)
    ncatt_put(rss, 0, "contact",ncatt_get(rsds,0,attname = "Contact")$value)
    ncatt_put(rss, 0, "further_info_url",ncatt_get(rsds,0,attname = "further_info_url")$value)
    
    ncatt_put(rss, "rss", "scale_factor", 1/fctrs["rss"])
    ncatt_put(rss,"rss", "add_offset", offsets["rss"])
    
    
    
    nc_close(rss)
    
    nc_close(rsus)
    
    nc_close(rsds)
    
    
    
  }
}




