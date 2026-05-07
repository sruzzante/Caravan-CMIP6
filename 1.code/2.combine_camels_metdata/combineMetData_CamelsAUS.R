# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/01_id_name_metadata/id_name_metadata.csv")


precipitation_AGCD<-read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/01_precipitation_timeseries/precipitation_AGCD.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "precipitation_AGCD")
# pivot_longer(cols  = !c(year,month,day),names_to = "gauge_id",values_to = "precipitation_AGCD")

precipitation_SILO = read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/01_precipitation_timeseries/precipitation_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "precipitation_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "precipitation_SILO")

et_morton_point_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/02_EvaporativeDemand_timeseries/et_morton_point_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "et_morton_point_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "et_morton_point_SILO")
et_morton_wet_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/02_EvaporativeDemand_timeseries/et_morton_wet_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "et_morton_wet_SILO")
et_morton_actual_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/02_EvaporativeDemand_timeseries/et_morton_actual_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "et_morton_actual_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "et_morton_point_SILO")

et_short_crop_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/02_EvaporativeDemand_timeseries/et_short_crop_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "et_short_crop_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "et_short_crop_SILO")

tmax_AGCD =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/AGCD/tmax_AGCD.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "tmax_AGCD")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "tmax_AGCD")

tmin_AGCD =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/AGCD/tmin_AGCD.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "tmin_AGCD")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "tmin_AGCD")

# # AGCD does not provide mean daily vapour pressure
# vapourpres_h09_AGCD =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/AGCD/vapourpres_h09_AGCD.csv",check.names = FALSE)%>%
#   pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "vapourpres_h09_AGCD")

vp_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/SILO/vp_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "vp_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "vp_SILO")
vp_deficit_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/SILO/vp_deficit_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "vp_deficit_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "vp_deficit_SILO")

mslp_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/SILO/mslp_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "mslp_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "mslp_SILO")
radiation_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/SILO/radiation_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "radiation_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "radiation_SILO")
tmax_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/SILO/tmax_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "tmax_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "tmax_SILO")
tmin_SILO =  read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-aus-v2/05_hydrometeorology/03_Other/SILO/tmin_SILO.csv",check.names = FALSE)%>%
  filter(year %in% (1981:2010))%>%
  mutate(var_camels = "tmin_SILO")
# pivot_longer(cols = !c(year,month,day),names_to = "gauge_id",values_to = "tmin_SILO")

dat = rbind(precipitation_AGCD,
            precipitation_SILO,
            et_short_crop_SILO,
            et_morton_point_SILO,
            et_morton_actual_SILO,
            et_morton_wet_SILO,
            tmax_AGCD,
            tmin_AGCD,
            tmax_SILO,
            tmin_SILO,
            radiation_SILO,
            mslp_SILO,
            vp_SILO,
            vp_deficit_SILO)%>%
  filter(year %in% (1981:2010))%>%
  pivot_longer(cols = !c(year,month,day,var_camels),names_to = "gauge_id",values_to = "value")%>%
  pivot_wider(names_from = "var_camels",
              values_from = "value")


dat$tmin_AGCDDiff = dat$tmin_AGCD - dat$tmax_AGCD
dat$tmin_SILODiff = dat$tmin_SILO - dat$tmax_SILO


dat$date = ymd(paste(dat$year,dat$month,dat$day))

saveRDS(dat,"2.data/2.working/histMetData/camels-aus/metdata.RDS")

