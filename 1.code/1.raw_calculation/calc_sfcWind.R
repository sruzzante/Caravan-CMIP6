# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script calculates the magnitude of the surface wind from the raw climate data


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
library(weathermetrics)
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
datasets_wide<-filter(datasets_wide,!is.na(hurs)&!is.na(tas))

if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
  
}

for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in 1:10){
    
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets_wide$i[it],datasets_wide$uas[it],it_sub))
    
    
    targetDir = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/sfcWind",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    
    
    flNm = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                 datasets_wide$source_id[it],
                 datasets_wide$experiment_id[it],
                 "sfcWind",
                 paste(
                   "sfcWind",
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
    
    
    uas = nc_open(datasets_wide$uas[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    vas = nc_open(datasets_wide$vas[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    
    
    uas_mat<-ncvar_get(uas,varid = "uas")
    # tasC_mat = tas_mat-273.15
    vas_mat<-ncvar_get(vas,varid = "vas")
    
    sfcWind_mat = (uas_mat^2+vas_mat^2)^0.5
    
    sfcWind_mat = (sfcWind_mat-offsets["sfcWind"])*fctrs["sfcWind"]
    
    
    # create sfcWind ncdf file
    # get attributes from uas file
    
    cal<-uas$dim$time$calendar
    
    time_dim <- uas$dim$time
    
    gauge_dim <- uas$dim$id
    
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    
    var_def <- ncvar_def(
      name  = "sfcWind",
      units = "m s-1",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Daily-Mean Near-Surface Wind Speed",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    sfcWind <- nc_create(paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                               datasets_wide$source_id[it],
                               datasets_wide$experiment_id[it],
                               "sfcWind",
                               paste(
                                 "sfcWind",
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
    
    ncvar_put(sfcWind, var_def, sfcWind_mat)
    
    
    ncatt_put(sfcWind, "id", "gauge_id", ncatt_get(uas,varid = "id",attname = "gauge_id")$value)
    ncatt_put(sfcWind, 0, "institution_id",ncatt_get(uas,0,attname = "institution_id")$value)
    ncatt_put(sfcWind, 0, "institution",ncatt_get(uas,0,attname = "institution")$value)
    ncatt_put(sfcWind, 0, "source_id",ncatt_get(uas,0,attname = "source_id")$value)
    ncatt_put(sfcWind, 0, "source",ncatt_get(uas,0,attname = "source")$value)
    ncatt_put(sfcWind, 0, "experiment_id",ncatt_get(uas,0,attname = "experiment_id")$value)
    ncatt_put(sfcWind, 0, "variant_label", ncatt_get(uas,0,attname = "variant_label")$value)
    ncatt_put(sfcWind, 0, "grid_label",ncatt_get(uas,0,attname = "grid_label")$value)
    ncatt_put(sfcWind, 0, "grid",ncatt_get(uas,0,attname = "grid")$value)
    
    
    ncatt_put(sfcWind, 0, "license",ncatt_get(uas,0,attname = "license")$value)
    ncatt_put(sfcWind, 0, "Conventions",ncatt_get(uas,0,attname = "Conventions")$value)
    ncatt_put(sfcWind, 0, "contact",ncatt_get(uas,0,attname = "Contact")$value)
    ncatt_put(sfcWind, 0, "further_info_url",ncatt_get(uas,0,attname = "further_info_url")$value)
    
    ncatt_put(sfcWind, "sfcWind", "scale_factor", 1/fctrs["sfcWind"])
    ncatt_put(sfcWind,"sfcWind", "add_offset", offsets["sfcWind"])
    
    
    
    nc_close(uas)
    
    nc_close(vas)
    
    nc_close(sfcWind)
    
    
    
  }
}




