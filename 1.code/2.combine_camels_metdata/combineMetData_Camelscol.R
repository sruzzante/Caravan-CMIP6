# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-st_read("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-col/03_CAMELS_COL_Basin_boundary/CAMELS_COL_catchments_boundaries.shp")
dat<-vector(mode = "list",length = nrow(watersheds))

for(it in 1:nrow(watersheds)){
  tic(it)
  
  
  dat[[it]]<-read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-col/04_CAMELS_COL_Hydrometeorological_data/Hydromet_data_%s.txt.txt",
                           watersheds$IDEAM_CODE[it]),sep  ="")%>%
    mutate(date = ymd(Date),
           gauge_id=  watersheds$IDEAM_CODE[it],
           year = year(date)
    )%>%
    
    filter(year%in% (1981:2010))%>%
    
    select(gauge_id,date,
           pr,
           poten_evapo,
           t_max,t_min,t_mean)
  
  
  
  toc()
}

dat = bind_rows(dat)


dat$t_minDiff = dat$t_min-dat$t_mean
dat$t_maxDiff = dat$t_max-dat$t_mean
saveRDS(dat,"2.data/2.working/histMetData/camels-col/metdata.RDS")
