# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script fixes the spikes in the raw climate data for tasmax from UKESM1-0-LL


args = commandArgs(trailingOnly=TRUE)


it_split = as.integer(args[1])
numsplit = as.integer(args[2])

setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
library(stringr)
library(tictoc)
library(ncdf4)
fls = list.files("../DATA/1.Spatial_data/global/clim_climate_precip_aridity_permafrost/clim1_CMIP6_ESGF_daily/UKESM1-0-LL/",
                 pattern = "tasmax_day_*",
                 recursive = T,
                 full.names = T)
# fls


if(numsplit>1){
  x<-split(1:length(fls),cut(seq_along(1:length(fls)), breaks = numsplit, labels = FALSE))
  fls<-fls[x[[it_split]]]
  
}


for(it in 1:length(fls)){
  file.copy(fls[it],
            fls[it]%>%str_replace_all("tasmax","tasmaxAmended"),
            overwrite =T)
  
  tic(it)
  print(fls[it])
  nc_tasmax = nc_open(fls[it]%>%str_replace_all("tasmax","tasmaxAmended"),write = T)
  tasmax =ncvar_get(nc_tasmax,"tasmax")
  msk = tasmax>335
  
  if(any(msk)){
    nc_tas = nc_open(fls[it]%>%str_replace_all("tasmax","tas"))
    tas =ncvar_get(nc_tas,"tas")
    
    nc_tasmin = nc_open(fls[it]%>%str_replace_all("tasmax","tasmin"))
    tasmin =ncvar_get(nc_tasmin,"tasmin")
    
    
    tasmax[msk] = 2*tas[msk]-tasmin[msk]
  }
  
  
  
  ncvar_put(nc = nc_tasmax,
            varid = "tasmax",
            vals = tasmax)
  ncatt_put(nc_tasmax,varid = "tasmax",attname = "num_spikes_fixed",
            attval = sprintf("Fixed %d spikes with values above 335 K", sum(sum(msk))))

 print( sprintf("Fixed %d spikes with values above 335 K", sum(sum(msk))))
  
  toc()
}
