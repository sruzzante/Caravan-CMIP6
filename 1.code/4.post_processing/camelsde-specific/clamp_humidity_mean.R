
suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
suppressMessages(library(MBC))
library(ncdf4)
# library(sf)
library(CFtime)
library(stringr)
library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
source("1.code/utils.R")
# camels factors and offsets

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
  
 
  group_by(project,source_id,experiment_id,variant_label)%>%
  summarize()%>%
  mutate(flNm = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_camels-de_netcdf/%s/%s/%s_%s_%s.nc",
                        source_id,experiment_id,source_id,experiment_id,variant_label))

it=1
for(it in 1:nrow(datasets)){
  tic(it)
  nc = nc_open(datasets$flNm[it],
               write = TRUE)
  
  hurs = ncvar_get(nc,"humidity_mean")
  # range(hurs)
  
  hurs = hurs%>%pmax(0)%>%pmin(100)
  
  ncvar_put(nc,varid= "humidity_mean",
            vals = hurs*100)
  nc_close(nc)
  toc()
}
