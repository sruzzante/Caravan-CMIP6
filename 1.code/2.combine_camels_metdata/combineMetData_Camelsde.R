# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<- read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-de/CAMELS_DE_climatic_attributes.csv")
dat<-vector(mode = "list",length = nrow(watersheds))
for(it in 1:nrow(watersheds)){
  tic(it)
  
  obs = read.csv(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-de/timeseries/CAMELS_DE_hydromet_timeseries_%s.csv",
                         watersheds$gauge_id[it]))%>%
    mutate(date = ymd(date),
           Year =year(date))%>%
    filter(Year%in% (1981:2010))%>%
    mutate(gauge_id = watersheds$gauge_id[it])%>%
    select(gauge_id,date,precipitation_mean,humidity_mean,radiation_global_mean,temperature_mean,temperature_min,temperature_max)
  
  sim =  read.csv(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-de/timeseries_simulated/CAMELS_DE_discharge_sim_%s.csv",
                          watersheds$gauge_id[it]))%>%
    mutate(date = ymd(date),
           Year =year(date))%>%
    filter(Year%in% (1981:2010))%>%
    
    select(date,pet_hargreaves)
  
  
  dat[[it]]<-left_join(obs,sim)
    
  
  toc()
}

dat = bind_rows(dat)

dir.create("2.data/2.working/histMetData/camels-de")


dat$temperature_minDiff = dat$temperature_min-dat$temperature_mean
dat$temperature_maxDiff = dat$temperature_max-dat$temperature_mean
saveRDS(dat,"2.data/2.working/histMetData/camels-de/metdata.RDS")
