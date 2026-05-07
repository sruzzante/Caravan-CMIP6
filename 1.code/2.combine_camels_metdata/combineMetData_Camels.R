# save all met data

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
library(sf)
library(ncdf4)
# library(CFtime)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")


watersheds<-read.delim("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-us/camels_name.txt",
                       sep = ";",
                       colClasses = "character")
dat_daymet<-vector(mode = "list",length = nrow(watersheds))
dat_maurer<-vector(mode = "list",length = nrow(watersheds))
dat_nldas<-vector(mode = "list",length = nrow(watersheds))
for(it in 1:nrow(watersheds)){
  tic(it)
  dat_daymet[[it]]<-read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-us/basin_dataset_public_v1p2/basin_mean_forcing/daymet/%s/%s_lump_cida_forcing_leap.txt",
                                       watersheds$huc_02[it],watersheds$gauge_id[it]),
                               sep = "",
                               skip = 3)%>%
    filter(Year%in% (1981:2010))%>%
    mutate(date = ymd(paste(Year, Mnth, Day)),
           gauge_id = watersheds$gauge_id[it])%>%
    select(gauge_id,date,dayl.s.,prcp.mm.day.,srad.W.m2.,swe.mm.,tmax.C.,tmin.C.,
           vp.Pa.)
  
  dat_maurer[[it]]<-read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-us/basin_dataset_public_v1p2/basin_mean_forcing/maurer/%s/%s_lump_maurer_forcing_leap.txt",
                                       watersheds$huc_02[it],watersheds$gauge_id[it]),
                               sep = "",
                               skip = 3)%>%
    filter(Year%in% (1981:2010))%>%
    mutate(date = ymd(paste(Year, Mnth, Day)),
           gauge_id = watersheds$gauge_id[it])%>%
    dplyr::rename(dayl.s. = Dayl.s.,
                  prcp.mm.day. = PRCP.mm.day.,
                  srad.W.m2. = SRAD.W.m2.,
                  swe.mm. = SWE.mm.,
                  tmax.C. = Tmax.C.,
                  tmin.C.= Tmin.C.,
                  vp.Pa. = Vp.Pa.)%>%
    select(gauge_id,date,dayl.s.,prcp.mm.day.,srad.W.m2.,swe.mm.,tmax.C.,tmin.C.,vp.Pa.)
  
  dat_nldas[[it]]<-read.delim(sprintf("../DATA/1.Spatial_data/global/sw_surfacewater_streamflow_runoff_river_network_waterstress/camels-us/basin_dataset_public_v1p2/basin_mean_forcing/nldas/%s/%s_lump_nldas_forcing_leap.txt",
                                      watersheds$huc_02[it],watersheds$gauge_id[it]),
                              sep = "",
                              skip = 3)%>%
    filter(Year%in% (1981:2010))%>%
    mutate(date = ymd(paste(Year, Mnth, Day)),
           gauge_id = watersheds$gauge_id[it])%>%
    dplyr::rename(dayl.s. = Dayl.s.,
                  prcp.mm.day. = PRCP.mm.day.,
                  srad.W.m2. = SRAD.W.m2.,
                  swe.mm. = SWE.mm.,
                  tmax.C. = Tmax.C.,
                  tmin.C.= Tmin.C.,
                  vp.Pa. = Vp.Pa.)%>%
    select(gauge_id,date,dayl.s.,prcp.mm.day.,srad.W.m2.,swe.mm.,tmax.C.,tmin.C.,vp.Pa.)
  toc()
}

dat_daymet = bind_rows(dat_daymet)
dat_maurer = bind_rows(dat_maurer)
dat_nldas = bind_rows(dat_nldas)
dat_daymet<-readRDS("2.data/2.working/histMetData/camels-us/daymet.rds")

dat_maurer<-readRDS("2.data/2.working/histMetData/camels-us/maurer.rds")

dat_nldas<-readRDS("2.data/2.working/histMetData/camels-us/nldas.rds")


dat_daymet$rsds = dat_daymet$srad.W.m2.*dat_daymet$dayl.s./86400
dat_maurer$rsds = dat_maurer$srad.W.m2.*dat_maurer$dayl.s./86400
dat_nldas$rsds = dat_daymet$srad.W.m2.*dat_nldas$dayl.s./86400

dat_daymet$tmin.C.diff = dat_daymet$tmin.C.-dat_daymet$tmax.C.
dat_maurer$tmin.C.diff = dat_maurer$tmin.C.-dat_maurer$tmax.C.
dat_nldas$tmin.C.diff = dat_nldas$tmin.C.-dat_nldas$tmax.C.


library(lubridate)
library(ggplot2)
dat_maurer%>%
  filter(gauge_id == "01013500")%>%
  mutate(yd = yday(date))%>%
  ggplot(aes(x = yd,y = dayl.s.))+
  geom_line()

saveRDS(dat_daymet,"2.data/2.working/histMetData/camels-us/daymet.rds")
saveRDS(dat_maurer,"2.data/2.working/histMetData/camels-us/maurer.rds")
saveRDS(dat_nldas,"2.data/2.working/histMetData/camels-us/nldas.rds")



dayl_yd = dat_daymet%>%
  # filter(year(date)==1981)%>%
  group_by(gauge_id,yd = yday(date))%>%
  summarize(dayl.s. = mean(dayl.s.))
saveRDS(dayl_yd,"2.data/2.working/histMetData/camels-us/daylight_by_yday.RDS")
  
