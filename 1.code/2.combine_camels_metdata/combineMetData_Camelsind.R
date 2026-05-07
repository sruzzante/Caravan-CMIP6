# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-st_read("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-ind/shapefiles_catchment/merged/all_catchments.shp")
dat<-vector(mode = "list",length = nrow(watersheds))

for(it in 1:nrow(watersheds)){
  tic(it)
  
  
  dat[[it]]<-read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-ind/catchment_mean_forcings/%s.csv",
                           watersheds$gauge_id[it]),sep  =",")%>%
    mutate(date = ymd(paste(year,month,day)),
           gauge_id=  watersheds$gauge_id[it]
    )%>%
    
    filter(year%in% (1981:2010))%>%
    
    select(gauge_id,date,
           prcp.mm.day.,
           tmax.C.,
           tmin.C.,
           tavg.C.,
           srad_lw.w.m2.,
           srad_sw.w.m2.,
           wind.m.s.,
           rel_hum...,
           pet.mm.day.,
           pet_gleam.mm.day.)
  
  
  
  toc()
}

dat = bind_rows(dat)



dat$tmax.C.Diff = dat$tmax.C.-dat$tavg.C.
dat$tmin.C.Diff = dat$tmin.C.-dat$tavg.C.
dat = readRDS("2.data/2.working/histMetData/camels-ind/metdata.RDS")
