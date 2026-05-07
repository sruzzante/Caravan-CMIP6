# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-st_read("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-br/12_CAMELS_BR_catchment_boundaries/camels_br_catchments.gpkg")
dat<-vector(mode = "list",length = nrow(watersheds))
for(it in 1:nrow(watersheds)){
  tic(it)
  
  
  x_pr<-read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-br/05_CAMELS_BR_precipitation/%s_precipitation.txt",
                           watersheds$gauge_id[it]),sep  ="")%>%
    mutate(date = ymd(paste(year,month,day)),
                      gauge_id=  watersheds$gauge_id[it],
    )%>%
    
    filter(year%in% (1981:2010))%>%
    
    select(gauge_id,date,p_brdwgd,p_chirps,p_cpc,
           p_era5land,p_mswep)
  
  
  x_pet= read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-br/07_CAMELS_BR_potential_evapotransp/%s_potential_evapotransp.txt",
                            watersheds$gauge_id[it]),sep  ="")%>%
    mutate(date = ymd(paste(year,month,day)),
           gauge_id = watersheds$gauge_id[it],
    )%>%
    
    filter(year%in% (1981:2010))%>%
    
    select(gauge_id,date,pet_gleam ,pet_era5land)
  
  if(file.exists(fl_ret = sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-br/08_CAMELS_BR_reference_evapotransp/%s_reference_evapotransp.txt",
                                  watersheds$gauge_id[it]))){
    x_ret = read.delim(fl_ret,sep  ="")%>%
      mutate(date = ymd(paste(year,month,day)),
             gauge_id = watersheds$gauge_id[it],
      )%>%
      
      filter(year%in% (1981:2010))%>%
      
      select(gauge_id,date,eto_brdwgd)
    
  }else{
    x_ret = data.frame(gauge_id =watersheds$gauge_id[it],
                       date = seq.Date(ymd("1981-01-01"),ymd("2010-12-31"),by = "day"),
                       eto_brdwgd = NA)
  }
  x_tas= read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-br/09_CAMELS_BR_temperature/%s_temperature.txt",
                            watersheds$gauge_id[it]),sep  ="")%>%
    mutate(date = ymd(paste(year,month,day)),
           gauge_id = watersheds$gauge_id[it],
    )%>%
    
    filter(year%in% (1981:2010))%>%
    
    select(gauge_id,date,tmax_cpc ,tmax_era5land ,tmax_brdwgd , tmean_era5land ,
           tmin_cpc ,tmin_era5land,tmin_brdwgd,)
  
  dat[[it]] = left_join(x_pr,x_pet)%>%
    left_join(x_ret)%>%
    left_join(x_tas)
  
  toc()
}

dat = bind_rows(dat)

dir.create("2.data/2.working/histMetData/camels-br")
saveRDS(dat,"2.data/2.working/histMetData/camels-br/metdata.RDS")



dat = readRDS("2.data/2.working/histMetData/camels-br/metdata.RDS")


dat$tmax_era5landDiff = dat$tmax_era5land-dat$tmean_era5land
dat$tmin_era5landDiff = dat$tmin_era5land-dat$tmean_era5land
dat$tmin_cpcDiff = dat$tmin_cpc-dat$tmax_cpc
dat$tmin_brdwgdDiff = dat$tmin_brdwgd-dat$tmax_brdwgd


saveRDS(dat,"2.data/2.working/histMetData/camels-br/metdata.RDS")

