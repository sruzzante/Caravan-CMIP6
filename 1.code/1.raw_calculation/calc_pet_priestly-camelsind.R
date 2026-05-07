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
  select(project,activity_id,institution_id,source_id,experiment_id,variant_label,variable_id,frequency,grid_label,nominal_resolution,src_folder)
datasets=rbind(
  datasets,
  datasets%>%
    filter(variable_id=="psl")%>%
    mutate(variable_id="ps"),
  datasets%>%
    filter(variable_id=="rsds")%>%
    mutate(variable_id="rss"),
  datasets%>%
    filter(variable_id=="rlds")%>%
    mutate(variable_id="rls")
)

datasets<-datasets[!duplicated(datasets%>%select(!src_folder)),]

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
datasets_wide<-filter(datasets_wide,!is.na(hurs)&!is.na(tas)&!is.na(tas)& (!is.na(sfcWind)|!is.na(uas))&
                        (!is.na(psl)|!is.na(ps))&
                        (!is.na(rss)|(!is.na(rsds)&!is.na(rsus)))&
                        (!is.na(rlds)&!is.na(rlus)))


if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
  
}

for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in "camelsind"){
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %s",datasets_wide$i[it],datasets_wide$tas[it],it_sub))
    
    
    
    targetDir = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/petpriestly",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    flNm = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                 datasets_wide$source_id[it],
                 datasets_wide$experiment_id[it],
                 "petpriestly",
                 paste(
                   "petpriestly",
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
      # if(file.mtime(flNm))
      print("already calculated, skipping")
      # next
    }
    
    
    
    tas = nc_open(datasets_wide$tas[it]%>%str_replace("d.nc",sprintf("d_%s.nc",it_sub)))
    
    ps = nc_open(datasets_wide$ps[it]%>%str_replace("d.nc",sprintf("d_%s.nc",it_sub)))
    
    
    rss = nc_open(datasets_wide$rss[it]%>%str_replace("d.nc",sprintf("d_%s.nc",it_sub)))
    rls = nc_open(datasets_wide$rls[it]%>%str_replace("d.nc",sprintf("d_%s.nc",it_sub)))
    
    
    dts_rls<- CFtime::CFtime(rls$dim$time$units, rls$dim$time$calendar, rls$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_rss<- CFtime::CFtime(rss$dim$time$units, rss$dim$time$calendar, rss$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_tas<- CFtime::CFtime(tas$dim$time$units, tas$dim$time$calendar, tas$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_ps<- CFtime::CFtime(ps$dim$time$units, ps$dim$time$calendar, ps$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_list = list(dts_rls,dts_rss,dts_tas,dts_ps)
    
    
    
    mask_rls = dts_rls %in% dts_list[[1]]& dts_rls %in% dts_list[[2]] & 
      dts_rls %in% dts_list[[3]]& dts_rls %in% dts_list[[4]] 
    
    
    mask_rss = dts_rss %in% dts_list[[1]]& dts_rss %in% dts_list[[2]] & 
      dts_rss %in% dts_list[[3]]& dts_rss %in% dts_list[[4]] 
    
    
    mask_tas = dts_tas %in% dts_list[[1]]& dts_tas %in% dts_list[[2]] & 
      dts_tas %in% dts_list[[3]]& dts_tas %in% dts_list[[4]] 
    
    
    
    mask_ps = dts_ps %in% dts_list[[1]]& dts_ps %in% dts_list[[2]] & 
      dts_ps %in% dts_list[[3]]& dts_ps %in% dts_list[[4]]
    
    
    dts = dts_tas[mask_tas]
    
    tas_mat<-ncvar_get(tas,varid = "tas")[,mask_tas]
    ps_mat = ncvar_get(ps,varid = "ps")[,mask_ps]
    
    rss_mat = ncvar_get(rss,varid = "rss")[,mask_rss]
    rls_mat = ncvar_get(rls,varid = "rls")[,mask_rls]
    
    petpriestly_mat = pet_priestly_func(p =ps_mat,
                                ta = tas_mat,
                                
                                rs = rss_mat,
                                rl = rls_mat)
    
    # apply scaling and offset
    petpriestly_mat = (petpriestly_mat-offsets["petpriestly"])*fctrs["petpriestly"]
    
    
    
    # create petpriestly ncdf file
    # get attributes from tas file
    
    
    cal<-rss$dim$time$calendar
    
    time_dim <- rss$dim$time
    time_dim$vals = time_dim$vals[mask_rss]
    
    gauge_dim <- rss$dim$id
    
    
    
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    
    var_def <- ncvar_def(
      name  = "petpriestly",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "mm d-1",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Penman-Monteith Reference Evapotranspiration (FAO-56 method)",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    petpriestly <- nc_create(paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                                   datasets_wide$source_id[it],
                                   datasets_wide$experiment_id[it],
                                   "petpriestly",
                                   paste(
                                     "petpriestly",
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
    
    ncvar_put(petpriestly, var_def, petpriestly_mat)
    
    ncatt_put(petpriestly, "petpriestly", "scale_factor", 1/fctrs["petpriestly"])
    ncatt_put(petpriestly,"petpriestly", "add_offset", offsets["petpriestly"])
    
    # ncvar_put(nc, gauge_var, id_vals)
    # ncvar_put(nc, gauge_var, id_char)
    
    
    ncatt_put(petpriestly, "id", "gauge_id", ncatt_get(tas,varid = "id",attname = "gauge_id")$value)
    ncatt_put(petpriestly, 0, "institution_id",ncatt_get(tas,0,attname = "institution_id")$value)
    ncatt_put(petpriestly, 0, "institution",ncatt_get(tas,0,attname = "institution")$value)
    ncatt_put(petpriestly, 0, "source_id",ncatt_get(tas,0,attname = "source_id")$value)
    ncatt_put(petpriestly, 0, "source",ncatt_get(tas,0,attname = "source")$value)
    ncatt_put(petpriestly, 0, "experiment_id",ncatt_get(tas,0,attname = "experiment_id")$value)
    ncatt_put(petpriestly, 0, "variant_label", ncatt_get(tas,0,attname = "variant_label")$value)
    ncatt_put(petpriestly, 0, "grid_label",ncatt_get(tas,0,attname = "grid_label")$value)
    ncatt_put(petpriestly, 0, "grid",ncatt_get(tas,0,attname = "grid")$value)
    
    
    ncatt_put(petpriestly, 0, "license",ncatt_get(tas,0,attname = "license")$value)
    ncatt_put(petpriestly, 0, "Conventions",ncatt_get(tas,0,attname = "Conventions")$value)
    ncatt_put(petpriestly, 0, "contact",ncatt_get(tas,0,attname = "Contact")$value)
    ncatt_put(petpriestly, 0, "further_info_url",ncatt_get(tas,0,attname = "further_info_url")$value)
    
    nc_close(tas)
    nc_close(ps)
    nc_close(rss)
    nc_close(rls)
    nc_close(petpriestly)
    gc()
  }
}




