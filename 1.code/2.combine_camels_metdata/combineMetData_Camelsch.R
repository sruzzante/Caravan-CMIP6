# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-ch/camels_ch/static_attributes/CAMELS_CH_climate_attributes_obs.csv",
                     skip=1,
                       sep = ",")
dat_ls<-vector(mode = "list",length = nrow(watersheds))
for(it in 1:nrow(watersheds)){

  tic(it)
    
  dat_obs = read.csv(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-ch/camels_ch/timeseries/observation_based/CAMELS_CH_obs_based_%d.csv",watersheds$gauge_id[it]))%>%
    mutate(gauge_id = watersheds$gauge_id[it])%>%
    select(date,gauge_id,precipitation.mm.d.,temperature_min.degC., temperature_max.degC.,temperature_mean.degC.)
  dat_sim = read.csv(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-ch/camels_ch/timeseries/simulation_based/CAMELS_CH_sim_based_%s.csv",watersheds$gauge_id[it]))%>%
    select(date,precipitation_sim.mm.d.,temperature_sim.degC.,radiation_sim.W.m2.,wind_sim.m.s.,rel_humidity_sim...,pet_sim.mm.d.)
  dat_ls[[it]] = left_join(dat_obs,dat_sim)%>%
    mutate(date = ymd(date))%>%
    
    filter(date %in% seq.Date(ymd("1981-10-01"),ymd("2011-09-30"),by = "day"))
  
  toc()
}

dat = bind_rows(dat_ls)

dat$temperature_min.degC.diff = dat$temperature_min.degC.-dat$temperature_mean.degC.
dat$temperature_max.degC.diff = dat$temperature_max.degC.-dat$temperature_mean.degC.



saveRDS(dat,"2.data/2.working/histMetData/camels-ch/metData.rds")



  
