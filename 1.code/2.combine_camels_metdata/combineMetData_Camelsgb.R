# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-st_read("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-gb-v2/Catchment_Boundaries/camels_gb_v2_catchment_boundaries.shp")
dat<-vector(mode = "list",length = nrow(watersheds))
for(it in 1:nrow(watersheds)){
  tic(it)
  dat[[it]]<-read.csv(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-gb-v2/Catchment_Timeseries/hydro-meteorological/daily/camels_gb_v2_hydromet_daily_timeseries_%s_19701001-20220930.csv",
                                       watersheds$ID[it]))%>%
    mutate(date = ymd(date),
           Year =year(date))%>%
    filter(Year%in% (1981:2010))%>%
    mutate(gauge_id = watersheds$ID[it])%>%
    select(gauge_id,date,precipitation_cehgear,precipitation_haduk,pet_chess,
           pet_hydrope,temperature_chess,temperature_haduk)
  
  toc()
}

dat = bind_rows(dat)


saveRDS(dat,"2.data/2.working/histMetData/camels-gb-v2/metdata.RDS")




