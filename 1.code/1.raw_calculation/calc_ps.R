# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script calculates the surface-level pressure from the raw climate data


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

datasets_wide<-filter(datasets_wide, is.na(ps))


if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
  
}

for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in 1:10){
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets_wide$i[it],datasets_wide$psl[it],it_sub))
    
    
    
    targetDir = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/ps",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    flNm = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                 datasets_wide$source_id[it],
                 datasets_wide$experiment_id[it],
                 "ps",
                 paste(
                   "ps",
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
    
    
    
    tas = nc_open(datasets_wide$tas[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    psl = nc_open(datasets_wide$psl[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    
    
    tas_mat<-ncvar_get(tas,varid = "tas")
    
    psl_mat<-ncvar_get(psl,varid = "psl")
 
    h = readRDS(sprintf("2.data/2.working/CMIP6_dems/basin_elevations/basin_elev_%s_%s.RDS",
                        datasets_wide$source_id[it],
                        it_sub))
      
    h_mat = h[,rep("dtm_elevation_merit.dem_m_250m_s0..0cm_2017_v1.0",dim(psl_mat)[2])]%>%
      unname()%>%
      as.matrix()
       
    ps_mat = ps_func(psl = psl_mat,ta = tas_mat,h = h_mat)
    
    
    # apply scaling and offset
    ps_mat = (ps_mat-offsets["ps"])*fctrs["ps"]
    
    
    
    # create ps ncdf file
    # get attributes from psl file
    
    
    cal<-tas$dim$time$calendar
    
    time_dim <- tas$dim$time
    
    gauge_dim <- tas$dim$id
    
    
    
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    
    var_def <- ncvar_def(
      name  = "ps",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "K",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Surface Pressure calculated using US standard atmosphere (1976) eq 33a",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    ps <- nc_create(paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                            datasets_wide$source_id[it],
                            datasets_wide$experiment_id[it],
                            "ps",
                            paste(
                              "ps",
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
    
    ncvar_put(ps, var_def, ps_mat)
    
    
    # ncvar_put(nc, gauge_var, id_vals)
    # ncvar_put(nc, gauge_var, id_char)
    
    
    ncatt_put(ps, "id", "gauge_id", ncatt_get(tas,varid = "id",attname = "gauge_id")$value)
    ncatt_put(ps, 0, "institution_id",ncatt_get(tas,0,attname = "institution_id")$value)
    ncatt_put(ps, 0, "institution",ncatt_get(tas,0,attname = "institution")$value)
    ncatt_put(ps, 0, "source_id",ncatt_get(tas,0,attname = "source_id")$value)
    ncatt_put(ps, 0, "source",ncatt_get(tas,0,attname = "source")$value)
    ncatt_put(ps, 0, "experiment_id",ncatt_get(tas,0,attname = "experiment_id")$value)
    ncatt_put(ps, 0, "variant_label", ncatt_get(tas,0,attname = "variant_label")$value)
    ncatt_put(ps, 0, "grid_label",ncatt_get(tas,0,attname = "grid_label")$value)
    ncatt_put(ps, 0, "grid",ncatt_get(tas,0,attname = "grid")$value)
    
    
    ncatt_put(ps, 0, "license",ncatt_get(tas,0,attname = "license")$value)
    ncatt_put(ps, 0, "Conventions",ncatt_get(tas,0,attname = "Conventions")$value)
    ncatt_put(ps, 0, "contact",ncatt_get(tas,0,attname = "Contact")$value)
    ncatt_put(ps, 0, "further_info_url",ncatt_get(tas,0,attname = "further_info_url")$value)
    
    ncatt_put(ps, "ps", "scale_factor", 1/fctrs["ps"])
    ncatt_put(ps, "ps", "add_offset",   offsets["ps"])
    
    
    
    nc_close(ps)
    
    nc_close(tas)
    
    nc_close(psl)
    
    
    
  }
}




