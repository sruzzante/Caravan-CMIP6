args = commandArgs(trailingOnly=TRUE)

it_split = 1
numsplit = 1

if(length(args)>0){
  it_split = as.integer(args[1])
  numsplit = as.integer(args[2])
  
  
}

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



param_trans<-
 
  rbind(
    read.csv("2.data/2.working/histMetData/camels-us/param_trans_camels-daymet.csv")%>%mutate(metdata = "daymet"),
    read.csv("2.data/2.working/histMetData/camels-us/param_trans_camels-maurer.csv")%>%mutate(metdata = "maurer"),
    read.csv("2.data/2.working/histMetData/camels-us/param_trans_camels-nldas.csv")%>%mutate(metdata = "nldas")
  )%>%
      filter(final_var)

datasets_camels<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
  group_by(source_id,variant_label,grid_label,experiment_id)%>%
  summarize(N=n())%>%
  cross_join(param_trans)

# datasets_camels = readRDS("/scratch/ruzzante/temp//CMIP6_ESGF_QDM_camels-ind/datasets_camels_nDone.RDS")%>%
#   filter( nDone ==0)
# split dataset


datasets_camels$i<-1:nrow(datasets_camels)

if(numsplit>1){
  x<-split(1:nrow(datasets_camels),cut(seq_along(1:nrow(datasets_camels)), breaks = numsplit, labels = FALSE))
  datasets_camels<-datasets_camels[x[[it_split]],]
  
}


for(it in 1:nrow(datasets_camels)){
  
  
  
  flNm = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                 datasets_camels$source_id[it],
                 datasets_camels$experiment_id[it],
                 datasets_camels$var_camels[it],
                 datasets_camels$var_camels[it],
                 datasets_camels$source_id[it],
                 
                 datasets_camels$experiment_id[it],
                 datasets_camels$variant_label[it],
                 datasets_camels$metdata[it])
  
  if(!file.exists(flNm)){print(paste("no file: ",flNm)); next}
  
  nc = nc_open(flNm,write = T)
  
  if(ncatt_get(nc,varid = datasets_camels$var_camels[it],attname = "number_clamped")$hasatt){next}
  
  
  if(! ncatt_get(nc,varid = datasets_camels$var_camels[it],attname = "add_offset")$hasatt|
     !ncatt_get(nc, 0, "further_info_url")$hasatt){
    print(sprintf("Incomplete file: row %d,  %s,  %s >> %s",
                  datasets_camels$i[it],
                  # it_sub,
                  sprintf("%s_%s_%s_%s",
                          datasets_camels$source_id[it],
                          datasets_camels$experiment_id[it],
                          datasets_camels$variant_label[it],
                          datasets_camels$grid_label[it]),
                  datasets_camels$var_CMIP6[it],
                  datasets_camels$var_camels[it]))
    
    
    
    var_corr = ncvar_get(nc,varid = datasets_camels$var_camels[it] )
    # print(range(var_corr))
    sprintf("max: %0.2f, min: %0.2f, #NA: %d, #<0: %d",
            min(var_corr,na.rm = T),
            max(var_corr,na.rm = T),
            sum(is.na(var_corr)),
            sum(var_corr<0,na.rm = T)
    )%>%print()
    print("deleting file")
    nc_close(nc)
    file.remove(flNm)
    next
  }else{
    
    if(!is.na(as.numeric(datasets_camels$max_theo[it]))){
      max_theo = as.numeric(datasets_camels$max_theo[it])
    }else if(datasets_camels$max_theo[it]%in% c("tmax.C.")){
      
      nc_temp =  sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                         datasets_camels$source_id[it],
                         datasets_camels$experiment_id[it],
                         datasets_camels$max_theo[it],
                         datasets_camels$max_theo[it],
                         datasets_camels$source_id[it],
                         
                         datasets_camels$experiment_id[it],
                         datasets_camels$variant_label[it],
                         datasets_camels$metdata[it])%>%
        nc_open()
      max_theo =ncvar_get(nc_temp,datasets_camels$max_theo[it])
      nc_close(nc_temp)
    }else if(datasets_camels$max_theo[it]%in% c("svp.Pa.")& datasets_camels$metdata[it]=="daymet" ){
      
      tmax.C. = nc_open(sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                                datasets_camels$source_id[it],
                                datasets_camels$experiment_id[it],
                               "tmax.C.",
                               "tmax.C.",
                                datasets_camels$source_id[it],
                                
                                datasets_camels$experiment_id[it],
                                datasets_camels$variant_label[it],
                               datasets_camels$metdata[it]))
      
      tmin.C. =  nc_open(sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                                 datasets_camels$source_id[it],
                                 datasets_camels$experiment_id[it],
                                 "tmin.C.",
                                 "tmin.C.",
                                 datasets_camels$source_id[it],
                                 
                                 datasets_camels$experiment_id[it],
                                 datasets_camels$variant_label[it],
                                 datasets_camels$metdata[it]))
      
      
      
      tmax.C._mat<-ncvar_get(tmax.C.,varid = "tmax.C.")
      tmin.C._mat<-ncvar_get(tmin.C.,varid = "tmin.C.")
      
      nc_close(tmax.C.)
      nc_close(tmin.C.)
      
      tmin.C._mat = pmin(tmin.C._mat,tmax.C._mat)
      
      # tmin.C.diff_mat[tmin.C.diff_mat>0] = 0 # ensure difference is always < 0
      
      tmean.C._mat = (tmax.C._mat+tmin.C._mat)/2
      
      svp_Pa = vp_func(100,tmean.C._mat+273.15)
      
      max_theo = svp_Pa
    }else if(datasets_camels$max_theo[it]%in% c("svp.Pa.")& datasets_camels$metdata[it]!="daymet" ){
      
      tmax.C. = nc_open(sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                                datasets_camels$source_id[it],
                                datasets_camels$experiment_id[it],
                               "tmax.C.",
                               "tmax.C.",
                                datasets_camels$source_id[it],
                                
                                datasets_camels$experiment_id[it],
                                datasets_camels$variant_label[it],
                               datasets_camels$metdata[it]))
      
      
      
      tmean.C._mat<-ncvar_get(tmax.C.,varid = "tmax.C.")
      
      
      nc_close(tmax.C.)

      
      svp_Pa = vp_func(100,tmean.C._mat+273.15)
      
      max_theo = svp_Pa
    }
    
    
    
    if(!is.na(as.numeric(datasets_camels$min_theo[it]))){
      min_theo = as.numeric(datasets_camels$min_theo[it])
    }
    
    if(datasets_camels$min_theo[it]=="tmax.C."){
      nc_temp =  sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%s.nc",
                         datasets_camels$source_id[it],
                         datasets_camels$experiment_id[it],
                         datasets_camels$max_theo[it],
                         datasets_camels$max_theo[it],
                         datasets_camels$source_id[it],
                         
                         datasets_camels$experiment_id[it],
                         datasets_camels$variant_label[it],
                         datasets_camels$metdata[it])%>%
        nc_open()
      min_theo =ncvar_get(nc_temp,datasets_camels$max_theo[it])
      nc_close(nc_temp)

    }
    
    var_corr = ncvar_get(nc,varid = datasets_camels$var_camels[it] )
    
    num_above_max_theo = sum(var_corr>max_theo,na.rm = TRUE)
    num_below_min_theo = sum(var_corr<min_theo,na.rm = TRUE)
    

    if(max_theo[1]==3276.7){
      
      num_above_max_theo = sum(var_corr>=max_theo,na.rm = TRUE)
    }
    
    
    print(sprintf("Range of %0.2f to %0.2f for %s, file: row %d,   %s",
                  min(var_corr,na.rm = TRUE),
                  max(var_corr,na.rm = TRUE),
                  datasets_camels$var_camels[it],
                  datasets_camels$i[it],
                  sprintf("%s_%s_%s_%s",
                          datasets_camels$source_id[it],
                          datasets_camels$experiment_id[it],
                          datasets_camels$variant_label[it],
                          datasets_camels$grid_label[it])))
    
    
    if (num_below_min_theo>0|num_above_max_theo>0){
      print ("---------------------WARNING - EDITING FILE -----------------------------------")
      print(  sprintf("After bias correction %d values (of %d total) were reduced to a theoretical maximum value of %s; %d values were increased to a theoretical minimum value of %s",
                      num_above_max_theo,
                      length(var_corr),
                      datasets_camels$max_theo[it],
                      num_below_min_theo,
                      datasets_camels$min_theo[it]))
      var_corr = pmax(var_corr,min_theo)
      var_corr = pmin(var_corr,max_theo)
      
      # APPLY OFFSET and SCALING
      var_corr = (var_corr-datasets_camels$offset_camels[it])*datasets_camels$scale_camels[it]
      
      
      
      ncvar_put(nc,varid = datasets_camels$var_camels[it],
                vals = var_corr )
    }
    
    ncatt_put(nc,varid = datasets_camels$var_camels[it] ,
              attname = "number_clamped",
              sprintf("After bias correction %d values (of %d total) were reduced to a theoretical maximum value of %s; %d values were increased to a theoretical minimum value of %s",
                      num_above_max_theo,
                      length(var_corr),
                      datasets_camels$max_theo[it],
                      num_below_min_theo,
                      datasets_camels$min_theo[it]))
    
  }
  
  
  nc_close(nc)
  
  gc()
  
  # readline('sdf')
}
