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
# library(weathermetrics)
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
    filePathExtracted = paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected",source_id,experiment_id,variable_id, sep= "/"),
    
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

# 
# datasets_wide = datasets_wide%>%filter(source_id == "TaiESM1")
datasets_wide$i<-1:nrow(datasets_wide)
datasets_wide<-filter(datasets_wide,!is.na(hurs)&!is.na(tas))

if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
  
}


for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in 1:10){
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets_wide$i[it],datasets_wide$tas[it],it_sub))
    
    
    
    targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/%s/%s/vp",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    flNm = paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected",
                 datasets_wide$source_id[it],
                 datasets_wide$experiment_id[it],
                 "vp",
                 paste(
                   "vp",
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
      #print("already calculated, skipping")
      # next
    }
    
    
    
    tas = nc_open(datasets_wide$tas[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    hurs = nc_open(datasets_wide$hurs[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    
    
    tas_mat<-ncvar_get(tas,varid = "tas")
    # tasC_mat = tas_mat-273.15
    hurs_mat<-ncvar_get(hurs,varid = "hurs")
    
    vp_mat = vp_func(hur = hurs_mat,ta = tas_mat)
    
    #   apply scaling and offset
    vp_mat = (vp_mat-offsets["vp"])*fctrs["vp"]
    
    # create vp ncdf file
    # get attributes from tas file
    
    
    cal<-tas$dim$time$calendar
    
    time_dim <- tas$dim$time
    
    gauge_dim <- tas$dim$id
    
    
    
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    
    var_def <- ncvar_def(
      name  = "vp",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "Pa",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Vapor pressure at 2m derived by Improved Magnus approximation",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    vp <- nc_create(paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected",
                            datasets_wide$source_id[it],
                            datasets_wide$experiment_id[it],
                            "vp",
                            paste(
                              "vp",
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
    
    ncvar_put(vp, var_def, vp_mat)
    
    
    # ncvar_put(nc, gauge_var, id_vals)
    # ncvar_put(nc, gauge_var, id_char)
    
    
    ncatt_put(vp, "id", "gauge_id", ncatt_get(tas,varid = "id",attname = "gauge_id")$value)
    ncatt_put(vp, 0, "institution_id",ncatt_get(tas,0,attname = "institution_id")$value)
    ncatt_put(vp, 0, "institution",ncatt_get(tas,0,attname = "institution")$value)
    ncatt_put(vp, 0, "source_id",ncatt_get(tas,0,attname = "source_id")$value)
    ncatt_put(vp, 0, "source",ncatt_get(tas,0,attname = "source")$value)
    ncatt_put(vp, 0, "experiment_id",ncatt_get(tas,0,attname = "experiment_id")$value)
    ncatt_put(vp, 0, "variant_label", ncatt_get(tas,0,attname = "variant_label")$value)
    ncatt_put(vp, 0, "grid_label",ncatt_get(tas,0,attname = "grid_label")$value)
    ncatt_put(vp, 0, "grid",ncatt_get(tas,0,attname = "grid")$value)
    
    
    ncatt_put(vp, 0, "license",ncatt_get(tas,0,attname = "license")$value)
    ncatt_put(vp, 0, "Conventions",ncatt_get(tas,0,attname = "Conventions")$value)
    ncatt_put(vp, 0, "contact",ncatt_get(tas,0,attname = "Contact")$value)
    ncatt_put(vp, 0, "further_info_url",ncatt_get(tas,0,attname = "further_info_url")$value)
    
    ncatt_put(vp, "vp", "scale_factor", 1/fctrs["vp"])
    ncatt_put(vp,"vp", "add_offset", offsets["vp"])
    
    
    
    nc_close(vp)
    
    nc_close(tas)
    
    nc_close(hurs)
    
    
    
  }
}




