# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")

# metData<-read.csv("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/caravan-de/timeseries/netcdf/camelsde/")

# watersheds<-st_read("2.data/2.working/shapefiles/combined_subset_1.gpkg")

# watersheds<-lapply(sprintf("2.data/2.working/shapefiles/combined_subset_%s.gpkg",1:10),st_read)%>%
#   bind_rows()
# unique(watersheds$src)

for(it_sub in 7){
  watersheds<-st_read(sprintf("2.data/2.working/shapefiles/combined_subset_%d.gpkg",it_sub))
  watersheds<-watersheds%>% mutate(fldr = recode(src,
                                                 "camels" = "caravan_v1p6/Caravan-nc",
                                                 "camelsaus" = "caravan_v1p6/Caravan-nc",
                                                 "camelsbr" = "caravan_v1p6/Caravan-nc",
                                                 "camelscl" = "caravan_v1p6/Caravan-nc",
                                                 "lamah" = "caravan_v1p6/Caravan-nc",
                                                 "camelsgb" = "caravan_v1p6/Caravan-nc",
                                                 "hysets" = "caravan_v1p6/Caravan-nc",
                                                 "camelses" = "camels-es",
                                                 "camelsil" = "Caravan_extension_Israel_Ver4",
                                                 "camelsdk" = "caravan-dk",
                                                 "grdc" = "caravan_ext_grdc/GRDC_Caravan_extension_nc/",
                                                 "lamahice" = "caravan_ice/LamaH-Ice_Caravan_Extension_v15",
                                                 "camelsde" = "caravan-de",
                                                 "camelsch" = "caravan-ch/Caravan_extension_CH/Caravan_extension_CH",
                                                 "camelscz" = "camels-cz/Caravan-Extension-CZ"))
  
  
  watersheds$src[watersheds$src=="camelsil"]<-"il"
  
  total_precipitation_sum<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  dewpoint_temperature_2m_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  snow_depth_water_equivalent_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  potential_evaporation_sum_FAO_PENMAN_MONTEITH<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  surface_net_solar_radiation_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  surface_net_thermal_radiation_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  surface_pressure_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  temperature_2m_max<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  temperature_2m_mean <-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  temperature_2m_min<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  u_component_of_wind_10m_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  v_component_of_wind_10m_mean<-data.frame(date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"))
  
  for(it in 1:nrow(watersheds)){
    tic(it)
    if(watersheds$src[it]=="camelses"){
      nc<-nc_open(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/%s/timeseries/netcdf_1980_2014/%s/%s.nc",watersheds$fldr[it],watersheds$src[it],watersheds$gauge_id[it]))
      
    }else {
      nc<-nc_open(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/%s/timeseries/netcdf/%s/%s.nc",watersheds$fldr[it],watersheds$src[it],watersheds$gauge_id[it]))
      
    }
    # nc$dim$date
    cf <- CFtime::CFtime(nc$dim$date$units, nc$dim$date$calendar, nc$dim$date$vals)
    dts <-CFtime::as_timestamp(cf,format= "date")%>%ymd()
    
    strt = pmax(which(dts==ymd("1981-01-02"))-1,1)
    cnt = which(dts==ymd("2010-12-31"))-strt+1
    
    if(dts[1]=="1981-01-02"){
      prepend = NA
    }else{
      prepend = NULL
    }
    
    total_precipitation_sum[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "total_precipitation_sum",start = strt,count = cnt ))
    dewpoint_temperature_2m_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "dewpoint_temperature_2m_mean",start = strt,count = cnt ))
    snow_depth_water_equivalent_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "snow_depth_water_equivalent_mean",start = strt,count = cnt ))
    potential_evaporation_sum_FAO_PENMAN_MONTEITH[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "potential_evaporation_sum_FAO_PENMAN_MONTEITH",start = strt,count = cnt ))
    surface_net_solar_radiation_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "surface_net_solar_radiation_mean",start = strt,count = cnt ))
    surface_net_thermal_radiation_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "surface_net_thermal_radiation_mean",start = strt,count = cnt ))
    surface_pressure_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "surface_pressure_mean",start = strt,count = cnt ))
    temperature_2m_max[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "temperature_2m_max",start = strt,count = cnt ))
    temperature_2m_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "temperature_2m_mean",start = strt,count = cnt ))
    temperature_2m_min[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "temperature_2m_min",start = strt,count = cnt ))
    u_component_of_wind_10m_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "u_component_of_wind_10m_mean",start = strt,count = cnt ))
    v_component_of_wind_10m_mean[[watersheds$gauge_id[it]]]<-c(prepend, ncvar_get(nc,varid = "v_component_of_wind_10m_mean",start = strt,count = cnt ))
    nc_close(nc)
    toc()
  }
  
  saveRDS(total_precipitation_sum,sprintf("2.data/2.working/histMetData/ERA5-Land/total_precipitation_sum_subset_%d.rds",it_sub))
  saveRDS(dewpoint_temperature_2m_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/dewpoint_temperature_2m_mean_subset_%d.rds",it_sub))
  saveRDS(snow_depth_water_equivalent_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/snow_depth_water_equivalent_mean_subset_%d.rds",it_sub))
  saveRDS(potential_evaporation_sum_FAO_PENMAN_MONTEITH,sprintf("2.data/2.working/histMetData/ERA5-Land/potential_evaporation_sum_FAO_PENMAN_MONTEITH_subset_%d.rds",it_sub))
  saveRDS(surface_net_solar_radiation_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/surface_net_solar_radiation_mean_subset_%d.rds",it_sub))
  saveRDS(surface_net_thermal_radiation_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/surface_net_thermal_radiation_mean_subset_%d.rds",it_sub))
  saveRDS(surface_pressure_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/surface_pressure_mean_subset_%d.rds",it_sub))
  saveRDS(temperature_2m_max,sprintf("2.data/2.working/histMetData/ERA5-Land/temperature_2m_max_subset_%d.rds",it_sub))
  saveRDS(temperature_2m_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/temperature_2m_mean_subset_%d.rds",it_sub))
  saveRDS(temperature_2m_min,sprintf("2.data/2.working/histMetData/ERA5-Land/temperature_2m_min_subset_%d.rds",it_sub))
  saveRDS(u_component_of_wind_10m_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/u_component_of_wind_10m_mean_subset_%d.rds",it_sub))
  saveRDS(v_component_of_wind_10m_mean,sprintf("2.data/2.working/histMetData/ERA5-Land/v_component_of_wind_10m_mean_subset_%d.rds",it_sub))
  
}


if(F){
  fls<-list.files("2.data/2.working/histMetData/ERA5-Land/",full.names = T)
  for(it in 1:length(fls)){
    dat<-readRDS(fls[it])
    dat<-filter(dat,date>=ymd("1981-01-01")&
                  date<=ymd("2010-12-31"))
    saveRDS(dat,fls[it])
    
  }
}