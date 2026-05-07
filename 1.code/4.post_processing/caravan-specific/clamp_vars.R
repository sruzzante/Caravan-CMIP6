args = commandArgs(trailingOnly=TRUE)

it_split = 191
numsplit = 400

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
param_trans<-read.csv("2.data/2.working/histMetData/param_trans_ERA5-Land.csv")%>%
  filter( final_var == T)%>%
  mutate(var_camels = var_ERA5_Land)%>%filter(var_CMIP6=="tasmax")

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")
datasets = rbind(datasets,
                 datasets%>%filter(variable_id == "uas")%>%mutate(variable_id="sfcWind"),
                 datasets%>%filter(variable_id == "rsds")%>%mutate(variable_id="rss"),
                 datasets%>%filter(variable_id == "rlds")%>%mutate(variable_id="rls"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="petfao56"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="tdps"),
                 datasets%>%filter(variable_id == "psl")%>%mutate(variable_id="ps")
)
datasets = datasets[!duplicated.data.frame(datasets%>%select(source_id,variant_label,experiment_id,variable_id)),]



datasets_camels<-left_join(datasets,param_trans,by = c("variable_id" = "var_CMIP6"))%>%
  mutate(var_CMIP6 = variable_id)%>%
  filter(!is.na(var_camels))


datasets_camels$i<-1:nrow(datasets_camels)

if(numsplit>1){
  x<-split(1:nrow(datasets_camels),cut(seq_along(1:nrow(datasets_camels)), breaks = numsplit, labels = FALSE))
  datasets_camels<-datasets_camels[x[[it_split]],]
  
}

it=954
it_sub = 3

for(it in 1:nrow(datasets_camels)){
  
  for(it_sub in 1:10){
    
    
    flNm = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%d.nc",
                   datasets_camels$source_id[it],
                   datasets_camels$experiment_id[it],
                   datasets_camels$var_camels[it],
                   datasets_camels$var_camels[it],
                   datasets_camels$source_id[it],
                   
                   datasets_camels$experiment_id[it],
                   datasets_camels$variant_label[it],
                   it_sub)
    if(!file.exists(flNm)){print(paste("no file: ",flNm)); next}
    
    nc = nc_open(flNm,write = F)
    
    if(ncatt_get(nc,varid = datasets_camels$var_camels[it],attname = "number_clamped")$hasatt){nc_close(nc); next}
    
    nc_close(nc)
    
    nc = nc_open(flNm,write = T)
    if(! ncatt_get(nc,varid = datasets_camels$var_camels[it],attname = "add_offset")$hasatt|
       !ncatt_get(nc, 0, "further_info_url")$hasatt){
      print(sprintf("Incomplete file: row %d, sub %d,  %s,  %s >> %s",
                    datasets_camels$i[it],
                    it_sub,
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
              max(var_corr,na.rm = T),
              min(var_corr,na.rm = T),
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
      }else if(datasets_camels$max_theo[it]=="temperature_2m_mean"){
        
        nc_temp =  sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM//%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%d.nc",
                           datasets_camels$source_id[it],
                           datasets_camels$experiment_id[it],
                           "temperature_2m_mean",
                           "temperature_2m_mean",
                           datasets_camels$source_id[it],
                           
                           datasets_camels$experiment_id[it],
                           datasets_camels$variant_label[it],
                           it_sub)%>%
          nc_open()
        max_theo =ncvar_get(nc_temp,"temperature_2m_mean")
        nc_close(nc_temp)
      }
      
      
      
      if(!is.na(as.numeric(datasets_camels$min_theo[it]))){
        min_theo = as.numeric(datasets_camels$min_theo[it])
      }else if(datasets_camels$min_theo[it]=="temperature_2m_mean"){
        
        nc_temp =  sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM//%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%d.nc",
                           datasets_camels$source_id[it],
                           datasets_camels$experiment_id[it],
                           "temperature_2m_mean",
                           "temperature_2m_mean",
                           datasets_camels$source_id[it],
                           
                           datasets_camels$experiment_id[it],
                           datasets_camels$variant_label[it],
                           it_sub)%>%
          nc_open()
        min_theo =ncvar_get(nc_temp,"temperature_2m_mean")
        
        nc_close(nc_temp)
      }
      
      var_corr = ncvar_get(nc,varid = datasets_camels$var_camels[it] )
      num_above_max_theo = sum(var_corr>max_theo,na.rm = TRUE)
      num_below_min_theo = sum(var_corr<min_theo,na.rm = TRUE)
      
      print(sprintf("Range of %0.2f to %0.2f for %s, file: row %d, sub %d,  %s",
                    min(var_corr,na.rm = TRUE),
                    max(var_corr,na.rm = TRUE),
                    datasets_camels$var_camels[it],
                    datasets_camels$i[it],
                    it_sub,
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
        
        
        # apply offset and scaling
        var_corr = (var_corr-datasets_camels$offset_ERA5_Land[it])*datasets_camels$scale_ERA5_Land[it]
        
        
        
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
      # readline("press enter")
    }
    
    
    nc_close(nc)
    
    gc()
    
  }

  # print(sprintf("Beginning row %d,  %s,  %s >> %s",
  #               datasets_camels$i[it],
  #               sprintf("%s_%s_%s_%s",
  #                       datasets_camels$source_id[it],
  #                       datasets_camels$experiment_id[it],
  #                       datasets_camels$variant_label[it],
  #                       datasets_camels$grid_label[it]),
  #               datasets_camels$var_CMIP6[it],
  #               datasets_camels$var_camels[it]))
  
}
