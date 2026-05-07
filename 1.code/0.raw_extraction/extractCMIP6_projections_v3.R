# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script extracts the raw climate data using the catchment polygons


args = commandArgs(trailingOnly=TRUE)
it_split = 1
numsplit = 900
activity_id_it = "ScenarioMIP" #  "CMIP"
watershed_it = 1

# test if there is at least two arguments: if not, continue without splitting
if (length(args)<2) {
  print("No arguments supplied, continuing without splitting data")
}else{    
it_split = as.integer(args[1])
numsplit = as.integer(args[2])
activity_id_it = as.character(args[3])
watershed_it = as.numeric(args[4])
    }


setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
# setwd(paste0(Sys.getenv("USERPROFILE"), "/OneDrive - University of Victoria/low-flows-BC/")) #Set the working directory


suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(terra))
suppressMessages(library(lubridate))
suppressMessages(library(tictoc))
library(stringr)
library(CFtime)
library(ncdf4)

source("1.code/utils.R")

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
  
  filter(activity_id == activity_id_it)

# Load a subset of the catchments
watersheds<-terra::vect(sprintf("2.data/2.working/shapefiles/combined_subset_%s.gpkg",watershed_it))

# dataframe of climate projections
datasets<-datasets%>%
  mutate(
    fileName = paste(
      variable_id,"day",source_id,experiment_id,variant_label,
      grid_label,".*.nc",
      sep ="_"
    ),
    filePathExtracted = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",source_id,experiment_id,variable_id, sep= "/"),
    
    fileNameExtracted  =  paste(
      variable_id,"day",source_id,
      experiment_id,variant_label,
      grid_label,"uncorrected.rds",
      
      sep ="_"
    ))%>%
  mutate(fileName = case_when(str_detect(src_folder,"CFday")~str_replace(fileName,"day","CFday"),
                              !str_detect(src_folder,"CFday") ~fileName))


# select a subset of climate projections
datasets$i<-1:nrow(datasets)

if(numsplit>1){
  x<-split(1:nrow(datasets),cut(seq_along(1:nrow(datasets)), breaks = numsplit, labels = FALSE))
  datasets<-datasets[x[[it_split]],]
  
}

for(it in 1:nrow(datasets)){
  print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets$i[it],datasets$fileName[it],watershed_it))
  targetDir = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                    datasets$source_id[it],
                    datasets$experiment_id[it],
                    datasets$variable_id[it],sep = "/")
  if(!dir.exists(targetDir)){
    dir.create(targetDir,recursive = T)
  }
  
  flNm = paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
               datasets$source_id[it],
               datasets$experiment_id[it],
               datasets$variable_id[it],
               paste(
                 datasets$variable_id[it],
                 "day",
                 datasets$source_id[it],
                 datasets$experiment_id[it],
                 datasets$variant_label[it],
                 datasets$grid_label[it],
                 "uncorrected",
                 paste0(watershed_it,
                        ".nc"),
                 
                 sep ="_"
               ),
               sep= "/"
  )
  if(file.exists(flNm)){
    print("already extracted, skipping")
    next
  }
  
  
  tic()
  histFiles<-list.files(path = datasets$dest_folder[it],
                        pattern = datasets$fileName[it],
                        
                        full.names = TRUE)
  

    # There are spikes in the original UKESM1-0-LL tasmax data, so use the amended data
  if(datasets$source_id [it] =="UKESM1-0-LL"&
     datasets$variable_id [it]  == "tasmax"){
    
    histFiles<-list.files(path = datasets$dest_folder[it]%>%str_replace_all("tasmax","tasmaxAmended"),
                          pattern = datasets$fileName[it]%>%str_replace_all("tasmax","tasmaxAmended"),
                          
                          full.names = TRUE)
  }
  
  
  
  if(length(histFiles)==0){
    print(sprintf("ERROR: There are NO years in the the file %s - historical - %s - %s, it_row = %d",datasets$source_id[it],datasets$variable_id[it],datasets$variant_label[it], datasets$i[it]))
    
    next
  }
  
  
  flag<-TRUE
  tryCatch( { xRast<-terra::rast(histFiles) }
            , error = function(e) {flag<<-FALSE})
  if (!flag) {
    print(sprintf("ERROR: could not load the files for realization %s - historical - %s - %s,it_row = %d",datasets$source_id[it],datasets$variable_id[it],datasets$variant_label[it], datasets$i[it]))
    
    next
  }
  
  origHistExt<-ext(xRast)
  
  # get metadata from climate model raster
  dts<-c()
  for(it_nc in 1:length(histFiles)){
    nc<-nc_open(histFiles[it_nc])
    
    cf <- CFtime::CFtime(nc$dim$time$units, nc$dim$time$calendar, nc$dim$time$vals)
    dts <- c(dts,as_timestamp(cf,format= "date"))
    
    cal<-nc$dim$time$calendar
    
    license_nc<-ncatt_get(nc,varid = 0,attname = "license")
    source_nc<-ncatt_get(nc,varid = 0,attname = "source")
    grid_nc<-ncatt_get(nc,varid = 0,attname = "grid")
    Conventions_nc<-ncatt_get(nc,varid = 0,attname = "Conventions")
    contact_nc<- ncatt_get(nc,varid = 0,attname = "contact")
    institution_nc =  ncatt_get(nc,varid = 0,attname = "institution")
    further_info_url_nc<- ncatt_get(nc,varid = 0,attname = "further_info_url")
    nc_close(nc)
    
    
  }

    #subset to 1850-2100, if necessary
  yrs<-substr(dts,1,4)%>%as.numeric()
  if(activity_id_it=="CMIP"){
    xRast<-subset(xRast,yrs %in% (1850:2014))
    dts<-dts[yrs %in% (1850:2014)]
  }
  if(activity_id_it=="ScenarioMIP"){
    xRast<-subset(xRast,yrs %in% 2015:2100)
    dts<-dts[yrs %in% (2015:2100)]
  }

    # Basic checks for completeness of data
  if(datasets$experiment_id[it]%in% c("ssp126","ssp245","ssp585")){
    if(!dim(xRast)[3]%in%c(31411,31390,31025,31046,30960)){
      print(sprintf("ERROR: There are missing days in the the file %s - %s - %s - %s, it_row = %d",
                    datasets$source_id[it],datasets$experiment_id[it],datasets$variable_id[it],datasets$variant_label[it], datasets$i[it]))
      next
    }
  }
 if(datasets$experiment_id[it]%in% c("historical")){
    if(datasets$source_id[it]=="EC-Earth3"&
       dim(xRast)[3]==16436){
      print(sprintf("Using 1970-2014 for file %s - historical - %s - %s, it_row = %d",datasets$source_id[it],datasets$variable_id[it],datasets$variant_label[it],it))
      
    }else if(!dim(xRast)[3]%in%c(60265,60225,59400,23741)){
      print(sprintf("ERROR: There are missing days in the the file %s - historical - %s - %s, it_row = %d",datasets$source_id[it],datasets$variable_id[it],datasets$variant_label[it], datasets$i[it]))
      next
    }
  }
  
  # Most of the rasters are indexed from longitude 0 to 360; rotate to -180,180
  if(ext(xRast)[1]>-90){
    xRast<-terra::rotate(xRast)
  }
  
  if(crs(xRast)==""){
    crs(xRast)<-"EPSG:4326"
  }
  
  # project catchment polygons to raster crs
  watersheds_x<-terra::project(watersheds,xRast)

    # extract the mean value for each polygon
  xDF<-terra::extract(xRast,watersheds_x,
                      fun = mean,
                      exact = TRUE,
                      ID =FALSE,
                      na.rm = TRUE)
  
  
  xMAT<-as.matrix(xDF)%>%unname()
  
  # apply offsets and scaling
  xMAT<-(xMAT-offsets[[datasets$variable_id[it]]])*fctrs[[datasets$variable_id[it]]]
  
  
  
  origin <- as.Date("1850-01-01")
  
  
  # get time vals in CF calendar
  
  cf_all<- CFtime::CFtime("days since 1850-01-01", cal, seq(0,10^5))
  dts_all = as_timestamp(cf_all,format= "date")
  time_start = which(dts_all==dts[1])-1
  time_vals <- seq(time_start,time_start+dim(xMAT)[2]-1,1)
  
  
  # define netcdf time dimension
  time_dim <- ncdim_def(
    name  = "time",
    units = paste("days since", origin),
    calendar = cal,
    vals  = time_vals,
    unlim = TRUE
  )
  
  
  id_vals <- watersheds_x$gauge_id
  
  gauge_dim <- ncdim_def(
    name  = "id",
    units = "",
    vals  = seq_along(id_vals),
    create_dimvar = TRUE
  )
  
  
  if(cal=="360_day"){
    chunk_size = 3600
  }else{
    chunk_size = 3650
  }
  if(datasets$variable_id[it] == "snw"){
    var_prec  ="integer"
  }else{
    var_prec = "short"
  }

    # define netcdf variable
  var_def <- ncvar_def(
    name  = varnames(xRast),
    units = unique(units(xRast)),
    dim   = list(gauge_dim, time_dim),
    missval = -32768,
    longname = longnames(xRast),
    prec = var_prec,
    shuffle = T,
    compression = 9,
    chunk = c(10, chunk_size)
  )
  
  # create netcdf
  nc <- nc_create(paste("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected",
                        datasets$source_id[it],
                        datasets$experiment_id[it],
                        datasets$variable_id[it],
                        paste(
                          datasets$variable_id[it],
                          "day",
                          datasets$source_id[it],
                          datasets$experiment_id[it],
                          datasets$variant_label[it],
                          datasets$grid_label[it],
                          "uncorrected",
                          paste0(watershed_it,
                                 ".nc"),
                          
                          sep ="_"
                        ),
                        sep= "/"
  ),
  vars = list(var_def))
  
  ncvar_put(nc, var_def, xMAT)
  
  
  
  # write metadata
  ncatt_put(nc, "id", "gauge_id", paste(id_vals, collapse = ","))
  ncatt_put(nc, 0, "institution_id", datasets$institution_id[it])
  ncatt_put(nc, 0, "institution",institution_nc$value)
  ncatt_put(nc, 0, "source_id", datasets$source_id[it])
  ncatt_put(nc, 0, "source",source_nc$value)
  ncatt_put(nc, 0, "experiment_id", datasets$experiment_id[it])
  ncatt_put(nc, 0, "variant_label", datasets$variant_label[it])
  ncatt_put(nc, 0, "grid_label",datasets$grid_label[it])
  ncatt_put(nc, 0, "grid",grid_nc$value)
  
  
  ncatt_put(nc, 0, "license",license_nc$value)
  ncatt_put(nc, 0, "Conventions",Conventions_nc$value)
  ncatt_put(nc, 0, "contact",contact_nc$value)
  ncatt_put(nc, 0, "further_info_url",further_info_url_nc$value)
  
  ncatt_put(nc, varnames(xRast), "scale_factor", 1/fctrs[datasets$variable_id[it]])
  ncatt_put(nc,varnames(xRast), "add_offset", offsets[datasets$variable_id[it]])
  
  nc_close(nc)
  
  
  print(sprintf("Done %d of %d datasets, watershed subset %d",it,nrow(datasets),watershed_it))
  
  toc()
}
