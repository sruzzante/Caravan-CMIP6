# Author: Sacha Ruzzante
# Email: sachawruzzante@gmail.com

# This script performs the quantile mapping for Caravan. The procedure is the same for all the CAMELS, except 
# all the data are done at once. For Caravan the large number of stations required splitting into 10 subdatasets.


args = commandArgs(trailingOnly=TRUE)

it_split = 3
numsplit = 1000
x_elapsed = NULL
start_it_sub=1


# test if there is at least two arguments: if not, continue without splitting
if (length(args)<3) {
  print("Not enough arguments supplied, continuing without splitting data")
}else{    

it_split = as.integer(args[1])
numsplit = as.integer(args[2])
start_it_sub = as.integer(args[3])
    }

suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(tictoc))
suppressMessages(library(MBC))
library(ncdf4)
# library(sf)
library(CFtime)
library(stringr)
# library(lubridate)
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
source("1.code/utils.R")
# ERA5-land factors and offsets
param_trans<-read.csv("2.data/2.working/histMetData/param_trans_ERA5-Land.csv")%>%
  filter( bias_correct_target == T)

#climate models, scenario, variants, and variables
datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")

# fucnction to read remaining time for batch job
print(Sys.getenv("SLURM_JOB_TIME_LIMIT"))
get_slurm_time_remaining <- function() {
  job_id <- Sys.getenv("SLURM_JOB_ID")
  if (job_id == "") return(NULL)  # not running in Slurm
  
  result <- system(
    paste0('squeue -j ', job_id, ' --noheader -o "%L"'),
    intern = TRUE
  )
  return(result)  # returns remaining time as "D-HH:MM:SS" or "HH:MM:SS"
}

parse_slurm_time <- function(time_str) {
  # Handles "D-HH:MM:SS" or "HH:MM:SS" or "MM:SS"
  parts <- strsplit(time_str, "-")[[1]]
  days <- 0
  if (length(parts) == 2) {
    days <- as.integer(parts[1])
    time_str <- parts[2]
  }
  hms <- as.integer(strsplit(time_str, ":")[[1]])
  if (length(hms) == 3) {
    seconds <- days*86400 + hms[1]*3600 + hms[2]*60 + hms[3]
  } else {
    seconds <- hms[1]*60 + hms[2]
  }
  return(seconds)
}

maxTime <- parse_slurm_time(get_slurm_time_remaining())


datasets_ERA5<-
  datasets%>%group_by(source_id,variant_label,experiment_id,grid_label)%>%
  summarize(n())%>%
  cross_join(param_trans%>%filter(var_ERA5_Land %in% c("surface_net_solar_radiation_mean",
                                                       "surface_net_thermal_radiation_mean",
                                                       "surface_pressure_mean",
                                                       "temperature_2m_mean",
                                                       "wind_10m_mean",
                                                       "total_precipitation_sum",
                                                       "dewpoint_temperature_2m_mean",
                                                       "temperature_2m_min_diff",
                                                       "temperature_2m_max_diff",
                                                       "snow_depth_water_equivalent_mean"
  )))%>%
  
  filter(!(source_id %in% c("CNRM-CM6-1-HR","TaiESM1")& var_CMIP6== "snw"))
datasets_ERA5 = readRDS("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM/datasets_ERA5_nDone.RDS")%>%
  filter(nDone<10)


datasets_ERA5$i<-1:nrow(datasets_ERA5)

if(numsplit>1){
  x<-split(1:nrow(datasets_ERA5),cut(seq_along(1:nrow(datasets_ERA5)), breaks = numsplit, labels = FALSE))
  datasets_ERA5<-datasets_ERA5[x[[it_split]],]
  
}
for(it in nrow(datasets_ERA5):1){
  for(watershed_it in start_it_sub){
    
    # do we have time for one more?
    if(!is.null(x_elapsed)){
      if(mean(x_elapsed)>(0.9*(maxTime-sum(x_elapsed)))){
        stop("Not enough time for another iteration, stopping now")
        break
      }
    }
    
    
    tic()
    
    print(sprintf("Beginning row %d,  %s,  %s >> %s",
                  datasets_ERA5$i[it],
                  sprintf("%s_%s_%s_%s_%s",
                          datasets_ERA5$source_id[it],
                          datasets_ERA5$experiment_id[it],
                          datasets_ERA5$variant_label[it],
                          datasets_ERA5$grid_label[it],watershed_it),
                  datasets_ERA5$var_CMIP6[it],
                  datasets_ERA5$var_ERA5_Land[it]))
    
    flNm = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%d.nc",
                   datasets_ERA5$source_id[it],
                   datasets_ERA5$experiment_id[it],
                   datasets_ERA5$var_ERA5_Land[it],
                   datasets_ERA5$var_ERA5_Land[it],
                   datasets_ERA5$source_id[it],
                   
                   datasets_ERA5$experiment_id[it],
                   datasets_ERA5$variant_label[it],
                   watershed_it)
    if(file.exists(flNm)){
      print("already done, skipping")
      next
    }
    
    
    ## observed historical reference period ###########
    histObserved = sprintf("2.data/2.working/histMetData/ERA5-Land/%s_subset_%d.rds",datasets_ERA5$var_ERA5_Land[it], watershed_it)%>%
      readRDS()%>%
      mutate(hm = as.character(date)%>%assignHalfMonth())
    

    ## modelled historical reference period ###########
    
    histModelled_nc<-ncdf4::nc_open(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/historical/%s/%s_day_%s_historical_%s_%s_uncorrected_%d.nc",
                                            datasets_ERA5$source_id[it],
                                            datasets_ERA5$var_CMIP6[it],
                                            datasets_ERA5$var_CMIP6[it],
                                            datasets_ERA5$source_id[it],
                                            datasets_ERA5$variant_label[it],
                                            datasets_ERA5$grid_label[it],
                                            watershed_it)
                                    
    )
    cf <- CFtime(histModelled_nc$dim$time$units, histModelled_nc$dim$time$calendar, histModelled_nc$dim$time$vals)
    dts <- as_timestamp(cf)
    
    # subset to reference period
    strt_hist_mdl = which(substr(dts,1,4)=="1981")%>%min()
    cnt_hist_mdl = which(substr(dts,1,4)=="2010")%>%max()-strt_hist_mdl+1
    
    histModelled<-ncvar_get(histModelled_nc,
                            start = c(1,strt_hist_mdl),
                            count = c(-1,cnt_hist_mdl))%>%
      t()%>%
      data.frame()
    
    histModelled<-(histModelled+datasets_ERA5$pre_adjust_offset[it])*datasets_ERA5$pre_adjust_scale[it]
    
    names(histModelled)<-str_split(ncatt_get(histModelled_nc,varid = "id")$gauge_id,pattern = ",")[[1]]
    
    cf_ref <- CFtime(histModelled_nc$dim$time$units, histModelled_nc$dim$time$calendar, histModelled_nc$dim$time$vals[strt_hist_mdl:(strt_hist_mdl+cnt_hist_mdl-1)])
    dts_ref <- as_timestamp(cf_ref)
    
    nc_close(histModelled_nc)
    
    histModelled<-cbind(data.frame(date = dts_ref),histModelled)

      # Sometimes all the observed data are NA
    maskNAHist = histModelled%>%
      ungroup()%>%
      summarize(across(2:ncol(histModelled),~all(is.na(.x))))%>%
      pivot_longer(cols = 1:(ncol(histModelled)-1),
                   names_to = "gauge_id",
                   values_to = "all_NA")
    
    ## modelled data to quantile map ###########
    
    projModelled_nc<-ncdf4::nc_open(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/%s/%s_day_%s_%s_%s_%s_uncorrected_%d.nc",
                                            datasets_ERA5$source_id[it],
                                            datasets_ERA5$experiment_id[it],
                                            datasets_ERA5$var_CMIP6[it],
                                            datasets_ERA5$var_CMIP6[it],
                                            datasets_ERA5$source_id[it],
                                            
                                            datasets_ERA5$experiment_id[it],
                                            datasets_ERA5$variant_label[it],
                                            datasets_ERA5$grid_label[it],
                                            watershed_it)
                                    
    )
    cf <- CFtime(projModelled_nc$dim$time$units, projModelled_nc$dim$time$calendar, projModelled_nc$dim$time$vals)
    dts <- as_timestamp(cf)
    
    
    projModelled<-ncvar_get(projModelled_nc)%>%
      t()%>%
      data.frame()
    
    projModelled<-(projModelled+datasets_ERA5$pre_adjust_offset[it])*datasets_ERA5$pre_adjust_scale[it]
    
    nms_proj_modelled = str_split(ncatt_get(projModelled_nc,varid = "id")$gauge_id,pattern = ",")[[1]]
    
    names(projModelled)<-nms_proj_modelled
    
    
    
    projModelled<-cbind(data.frame(date = dts),projModelled)
    
    
    maskNAProj = projModelled%>%
      ungroup()%>%
      summarize(across(2:ncol(projModelled),~all(is.na(.x))))%>%
      pivot_longer(cols = 1:(ncol(projModelled)-1),
                   names_to = "gauge_id",
                   values_to = "all_NA")
    
    
    
    # remove NA stations
    NA_stns = unique(c(maskNAHist$gauge_id[maskNAHist$all_NA],
                       maskNAProj$gauge_id[maskNAProj$all_NA])
    )
    if(length(NA_stns)>0){
      histModelled[NA_stns] = 1
      projModelled[NA_stns] = 1
      
    }
    
    
    
    # make lists of observed data
    
    # set target month to +/- 1 half-month
    histObserved<-rbind(histObserved%>%mutate(target_hm = hm),
                        histObserved%>%mutate(target_hm = (hm-1)%%24),
                        histObserved%>%mutate(target_hm = (hm+1)%%24))
    
    
    histObserved_long = pivot_longer(histObserved,cols = !c(date,hm, target_hm))
    histObserved_long$ID_hm = paste(histObserved_long$name,histObserved_long$target_hm,sep = ".")
    
    # there are NA values for 1981-01-01 for camels-dk
    histObserved_long<-histObserved_long%>%dplyr::filter(!is.na(value))
        
    histObserved_ls<-split.data.frame(histObserved_long,f=histObserved_long$ID_hm)
    

  
    
    
    # make lists of modelled hist
    
    histModelled<-histModelled%>%
      mutate(hm = as.character(date)%>%assignHalfMonth())
    
    
    # set target month to +/- 1 half-month
    histModelled<-rbind(histModelled%>%mutate(target_hm = hm),
                        histModelled%>%mutate(target_hm = (hm-1)%%24),
                        histModelled%>%mutate(target_hm = (hm+1)%%24))
    
    histModelled_long<-pivot_longer(histModelled,cols = !c(date,hm, target_hm))
    
    histModelled_long$ID_hm = paste(histModelled_long$name,histModelled_long$target_hm,sep = ".")
    histModelled_ls<-split.data.frame(histModelled_long,f=histModelled_long$ID_hm)
    
    
    # make lists of modelled projected
    
    projModelled<-projModelled%>%
      mutate(hm = as.character(date)%>%assignHalfMonth())
    
    
    # set target month to +/- 1 half-month
    projModelled<-rbind(projModelled%>%mutate(target_hm = hm),
                        projModelled%>%mutate(target_hm = (hm-1)%%24),
                        projModelled%>%mutate(target_hm = (hm+1)%%24))
    
    projModelled_long<-pivot_longer(projModelled,cols = !c(date,hm, target_hm))
    
    projModelled_long$ID_hm = paste(projModelled_long$name,projModelled_long$target_hm,sep = ".")
    
    projModelled_long$Year = substr(projModelled_long$date,1,4)%>%as.numeric()
    
    projModelled_long$Decade = pmin(floor(projModelled_long$Year/10)*10,2090)
    
    
    # set target decade to +/- 1 decade
    projModelled_long<-rbind(projModelled_long%>%mutate(target_decade = Decade),
                             projModelled_long%>%mutate(target_decade = Decade+10),
                             projModelled_long%>%mutate(target_decade = Decade-10)
    )
    
    if(datasets_ERA5$experiment_id[it]=="historical"){
      projModelled_long<-filter(projModelled_long,target_decade%in% seq(min(projModelled_long$Decade),2010,10))
      
    }else if (datasets_ERA5$experiment_id[it] %in% c("ssp126","ssp245","ssp585")){
      projModelled_long<-filter(projModelled_long,target_decade%in% seq(min(projModelled_long$Decade),2090,10))
      
    }
    
    
    projModelled_ls<-split.data.frame(projModelled_long,f=projModelled_long$target_decade)
    
    projModelled_ls2<-lapply(projModelled_ls,FUN = function(x){split.data.frame(x,f = x$ID_hm)})
    
    
    
    # Check lists #######
    
    if(!all(names(histModelled_ls)==names(projModelled_ls2[[1]]))){print("ERROR: names do not match"); break}
    if(!all(names(histObserved_ls)==names(projModelled_ls2[[1]]))){print("ERROR: names do not match"); break}
    
    
    cat(sprintf("Length of histObserved_ls is %d\nLength of histModelled_ls is %d\nLength of projModelled_ls is %d",
                length(histObserved_ls),
                length(histModelled_ls),
                length(projModelled_ls2[[1]])))
    
    nms<-lapply(projModelled_ls2,names)
    for(it_nm in 2:length(nms)){
      if(!all.equal(nms[[1]],nms[[it_nm]])){print("ERROR: names do not match"); break}
    }
    
    
    # perform quantile mapping ###########
    
    decades<-names(projModelled_ls2)
    
    xCorrected.mhat.p<-list()
    
    
    
    for(it_dec in 1:length(decades)){
      xCorrected<-
        mapply(FUN = function(o_c,m_c,m_p){MBC::QDM(o.c =  o_c$value, 
                                                    m.c =  m_c$value, 
                                                    m.p =  m_p$value,
                                                    
                                                    ratio = datasets_ERA5$ratio[it],
                                                    # trace = 1 #1 mm 
                                                    
        )},
        histObserved_ls,
        histModelled_ls,
        projModelled_ls2[[it_dec]],
        SIMPLIFY = TRUE
        )
      
      
      # xCorrected.mhat.c[[it_dec]] <- xCorrected["mhat.c",]
      xCorrected.mhat.p[[it_dec]] <- xCorrected["mhat.p",]
      
    }
    
    ## reformat data and filter to hm == target_hm #######
    
    for(it_stn in 1:length(xCorrected.mhat.p[[1]])){
      
      for(it_dec in 1:length(decades)){
        xCorrected.mhat.p[[it_dec]][[it_stn]]<-xCorrected.mhat.p[[it_dec]][[it_stn]]%>%
          data.frame()%>%
          mutate(gauge_id = projModelled_ls2[[it_dec]][[it_stn]]$name,
                 date = projModelled_ls2[[it_dec]][[it_stn]]$date,
                 hm = projModelled_ls2[[it_dec]][[it_stn]]$hm,
                 target_hm = projModelled_ls2[[it_dec]][[it_stn]]$target_hm,
                 
                 Decade = projModelled_ls2[[it_dec]][[it_stn]]$Decade,
                 target_decade = projModelled_ls2[[it_dec]][[it_stn]]$target_decade
          )%>%
          filter(hm == target_hm&
                   Decade==target_decade)%>% # keep only the target half-month and target half-decade
          dplyr::rename(value = ".")
      }
      
    }
    
    
    xCorrected.mhat.p<-lapply(xCorrected.mhat.p,bind_rows)%>%
      
      bind_rows()
    
    
    # remove gauge_ids that were NA
    xCorrected.mhat.p$value[xCorrected.mhat.p$gauge_id %in% NA_stns] = NA
    
    
    xCorrected.mhat.p_wide<-xCorrected.mhat.p%>%
      pivot_wider(names_from = gauge_id,values_from = value,id_cols = date)%>%
      arrange(date)
    
    
    xCorrected.mhat.p_wide<-xCorrected.mhat.p_wide%>%
      select(all_of(c("date",nms_proj_modelled)))
    
    
    xMAT<-xCorrected.mhat.p_wide%>%
      select(!date)%>%
      as.matrix()%>%
      unname()%>%t()
    
    # apply offsets and scaling
    xMAT<-(xMAT-datasets_ERA5$offset_ERA5_Land[it])*datasets_ERA5$scale_ERA5_Land[it]
    
    
    targetDir = sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM/%s/%s/%s/",
                        datasets_ERA5$source_id[it],
                        datasets_ERA5$experiment_id[it],
                        datasets_ERA5$var_ERA5_Land[it]
    )
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = TRUE)
    }
    
    # create and save nc file ##
    
    time_dim = projModelled_nc$dim$ time
    gauge_dim = projModelled_nc$dim $id
    
    cal<-time_dim$calendar
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    if(datasets_ERA5$var_ERA5_Land[it] == "snow_depth_water_equivalent_mean"){
      var_prec  ="integer"
    }else{
      var_prec = "short"
    }
    
    
    # clamp the variable to integer range; clamping to a theoretically reasonable range happens later
    if (var_prec == "integer"){
      xMAT = pmax(xMAT,-2^31)%>%pmin(2^31-1)
    }else{
      xMAT = pmax(xMAT,-32768)%>%pmin(32767)
    }
   
    
    
    var_def <- ncvar_def(
      name  =datasets_ERA5$var_ERA5_Land[it],
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = datasets_ERA5$units_ERA5_Land[it],
      dim   = list(gauge_dim, time_dim),
      missval = -9999,
      # longname = longnames(xRast),
      prec = var_prec,
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    nc<-nc_create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM/%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%d.nc",
                          datasets_ERA5$source_id[it],
                          datasets_ERA5$experiment_id[it],
                          datasets_ERA5$var_ERA5_Land[it],
                          datasets_ERA5$var_ERA5_Land[it],
                          datasets_ERA5$source_id[it],
                          
                          datasets_ERA5$experiment_id[it],
                          datasets_ERA5$variant_label[it],
                          watershed_it),
                  vars = list(var_def))
    ncatt_put(nc, datasets_ERA5$var_ERA5_Land[it],  "scale_factor", 1/datasets_ERA5$scale_ERA5_Land[it])
    ncatt_put(nc,datasets_ERA5$var_ERA5_Land[it], "add_offset", datasets_ERA5$offset_ERA5_Land[it])
    
    
    ncvar_put(nc, var_def, xMAT)
    
    # copy over some attributes from CMIP6
    
    ncatt_put(nc, "id", "gauge_id", ncatt_get(projModelled_nc,varid = "id",attname = "gauge_id")$value)
    ncatt_put(nc, 0, "institution_id",ncatt_get(projModelled_nc,0,attname = "institution_id")$value)
    ncatt_put(nc, 0, "institution",ncatt_get(projModelled_nc,0,attname = "institution")$value)
    ncatt_put(nc, 0, "source_id",ncatt_get(projModelled_nc,0,attname = "source_id")$value)
    ncatt_put(nc, 0, "source",ncatt_get(projModelled_nc,0,attname = "source")$value)
    ncatt_put(nc, 0, "experiment_id",ncatt_get(projModelled_nc,0,attname = "experiment_id")$value)
    ncatt_put(nc, 0, "variant_label", ncatt_get(projModelled_nc,0,attname = "variant_label")$value)
    ncatt_put(nc, 0, "grid_label",ncatt_get(projModelled_nc,0,attname = "grid_label")$value)
    ncatt_put(nc, 0, "grid",ncatt_get(projModelled_nc,0,attname = "grid")$value)
    
    
    ncatt_put(nc, 0, "license_GCM",ncatt_get(projModelled_nc,0,attname = "license")$value)
    ncatt_put(nc, 0, "Conventions",ncatt_get(projModelled_nc,0,attname = "Conventions")$value)
    ncatt_put(nc, 0, "contact",ncatt_get(projModelled_nc,0,attname = "Contact")$value)
    ncatt_put(nc, 0, "further_info_url",ncatt_get(projModelled_nc,0,attname = "further_info_url")$value)
    
    
    nc_close(projModelled_nc)
    nc_close(nc)
    
    toc_x<-toc()
    x_elapsed = c(x_elapsed,toc_x$toc-toc_x$tic)
    
    # clear memory
    rm(xMAT,xCorrected.mhat.p_wide,xCorrected.mhat.p, 
       histObserved,histObserved_ls,histObserved_long,
       histModelled,histModelled_long,histModelled_ls,
       projModelled,projModelled_long,projModelled_ls,projModelled_ls2)
    
    gc()
  }
}

