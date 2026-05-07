# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-st_read("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/camels_cl_boundaries/camels_cl_boundaries.shp")
dat<-vector(mode = "list",length = nrow(watersheds))

dat = rbind(
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/pet_hargreaves_mm_day.csv")%>%mutate(var_id = "pet_hargreaves_mm_day"),
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/precip_chirps_mm_day.csv")%>%mutate(var_id = "precip_chirps_mm_day"),
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/precip_cr2met_mm_day.csv")%>%mutate(var_id = "precip_cr2met_mm_day"),
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/precip_mswep_mm_day.csv")%>%mutate(var_id = "precip_mswep_mm_day"),
  
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/tmax_cr2met_C_day.csv")%>%mutate(var_id = "tmax_cr2met_C_day"),
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/tmin_cr2met_C_day.csv")%>%mutate(var_id = "tmin_cr2met_C_day"),
  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-cl/CAMELS_CL_v202201/tmean_cr2met_C_day.csv")%>%mutate(var_id = "tmean_cr2met_C_day")
)%>%
  pivot_longer(cols = X1001001:X12930001,names_to = "gauge_id")%>%
  mutate(gauge_id = substr(gauge_id,2,100))%>%
  filter(dat,year %in% (1981:2010))%>%
  pivot_wider(names_from = "var_id")%>%
  arrange(gauge_id,year,month,day)


dat$tminDiff_cr2met_C_day_diff = dat$tmin_cr2met_C_day-dat$tmean_cr2met_C_day
dat$tmaxDiff_cr2met_C_day_diff = dat$tmax_cr2met_C_day-dat$tmean_cr2met_C_day

saveRDS(dat,"2.data/2.working/histMetData/camels-cl/metdata.RDS")
