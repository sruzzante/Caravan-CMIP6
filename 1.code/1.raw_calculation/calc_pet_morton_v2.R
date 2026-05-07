args = commandArgs(trailingOnly=TRUE)
it_split = 1
numsplit = 5


it_split = as.integer(args[1])
numsplit = as.integer(args[2])
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
# setwd(paste0(Sys.getenv("USERPROFILE"), "/OneDrive - University of Victoria/low-flows-BC/")) #Set the working directory


suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
# suppressMessages(library(terra))
suppressMessages(library(lubridate))
suppressMessages(library(tictoc))
# library(weathermetrics)
library(stringr)
library(ncdf4)
# library(sf)
# sf_use_s2(T)
library(CFtime)
source("1.code/utils.R")


datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")%>%
  # mutate(frequency = case_when(str_detect(src_folder,"CFday")~"CFday",
  #                             !str_detect(src_folder,"CFday") ~"day"))%>%
  group_by(project,activity_id,source_id,institution_id,experiment_id,variant_label, frequency,grid_label)%>%
  summarize(N=n())%>%
  cross_join(data.frame(variable_id =c("tas","ps","psl","rss","rls","hurs")))

datasets<-datasets%>%
  mutate(
    
    filePathExtracted = paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected",source_id,experiment_id,variable_id, sep= "/"),
    
    fileNameExtracted  =  paste(
      variable_id,"day",source_id,
      experiment_id,variant_label,
      grid_label,"uncorrected.nc",
      
      sep ="_"
    ))


datasets_wide<-datasets%>%
  mutate(uncorrectedFile = paste(filePathExtracted,fileNameExtracted,sep = "/"))%>%
  pivot_wider(id_cols = c(project,activity_id,institution_id,source_id,experiment_id,variant_label,frequency,grid_label),
              values_from =uncorrectedFile,
              names_from = variable_id)



datasets_wide$i<-1:nrow(datasets_wide)
datasets_wide<-filter(datasets_wide,!is.na(hurs)&!is.na(tas))

if(numsplit>1){
  x<-split(1:nrow(datasets_wide),cut(seq_along(1:nrow(datasets_wide)), breaks = numsplit, labels = FALSE))
  datasets_wide<-datasets_wide[x[[it_split]],]
  
}
it = it_sub = 1

for(it in 1:nrow(datasets_wide)){
  
  for(it_sub in c(1)){
    # watersheds = st_read(sprintf("2.data/2.working/shapefiles/combined_subset_%d.gpkg",it_sub))%>%
    #   st_make_valid()
    # 
    # watersheds_ct = st_centroid(watersheds)
    # watersheds_ct$lat = (st_coordinates(watersheds_ct))[,2]
    
    print(sprintf( "Beginning dataset row %d, %s, watershed subset %d",datasets_wide$i[it],datasets_wide$tas[it],it_sub))
    
    
    
    targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/%s/%s/et_morton_potential",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    
    
    targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/%s/%s/et_morton_potential",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    
    
    targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/%s/%s/et_morton_wet",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    
    
    targetDir = sprintf("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/%s/%s/et_morton_actual",datasets_wide$source_id[it],datasets_wide$experiment_id[it])
    
    if(!dir.exists(targetDir)){
      dir.create(targetDir,recursive = T)
    } # dir.create(sprintf("2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/rls",datasets_wide$source_id[it],datasets_wide$experiment_id[it]))
    # 
    # flNm = paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected",
    #              datasets_wide$source_id[it],
    #              datasets_wide$experiment_id[it],
    #              "et_morton_potential",
    #              paste(
    #                "et_morton_potential",
    #                "day",
    #                datasets_wide$source_id[it],
    #                datasets_wide$experiment_id[it],
    #                datasets_wide$variant_label[it],
    #                datasets_wide$grid_label[it],
    #                "uncorrected",
    #                paste0(it_sub,
    #                       ".nc"),
    #                
    #                sep ="_"
    #              ),
    #              sep= "/"
    # )
    # 
    # if(file.exists(flNm)){
    #   print("already calculated, skipping")
    #   next
    # }
    # 
    # 
    
    tas =  nc_open(datasets_wide$tas[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    rss =  nc_open(datasets_wide$rss[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    rls =  nc_open(datasets_wide$rls[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    ps =  nc_open(datasets_wide$ps[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    psl =  nc_open(datasets_wide$psl[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    hurs =  nc_open(datasets_wide$hurs[it]%>%str_replace("d.nc",sprintf("d_%d.nc",it_sub)))
    
    
    dts_rls<- CFtime::CFtime(rls$dim$time$units, rls$dim$time$calendar, rls$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_rss<- CFtime::CFtime(rss$dim$time$units, rss$dim$time$calendar, rss$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_tas<- CFtime::CFtime(tas$dim$time$units, tas$dim$time$calendar, tas$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_hurs<- CFtime::CFtime(hurs$dim$time$units, hurs$dim$time$calendar, hurs$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_ps<- CFtime::CFtime(ps$dim$time$units, ps$dim$time$calendar, ps$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    dts_psl<- CFtime::CFtime(psl$dim$time$units, psl$dim$time$calendar, psl$dim$time$vals)%>%
      CFtime::as_timestamp(format = "date")
    # dts_sfcWind<- CFtime::CFtime(sfcWind$dim$time$units, sfcWind$dim$time$calendar, sfcWind$dim$time$vals)%>%
    #   CFtime::as_timestamp(format = "date")
    dts_list = list(dts_rls,dts_rss,dts_tas,dts_hurs,dts_ps,dts_psl)
    
    
    
    mask_rls = dts_rls %in% dts_list[[1]]& dts_rls %in% dts_list[[2]] &
      dts_rls %in% dts_list[[3]]& dts_rls %in% dts_list[[5]] &
      dts_rls %in% dts_list[[5]]& dts_rls %in% dts_list[[6]]
    
    
    mask_rss = dts_rss %in% dts_list[[1]]& dts_rss %in% dts_list[[2]] &
      dts_rss %in% dts_list[[3]]& dts_rss %in% dts_list[[5]] &
      dts_rss %in% dts_list[[5]]& dts_rss %in% dts_list[[6]]
    
    
    mask_tas = dts_tas %in% dts_list[[1]]& dts_tas %in% dts_list[[2]] &
      dts_tas %in% dts_list[[3]]& dts_tas %in% dts_list[[5]] &
      dts_tas %in% dts_list[[5]]& dts_tas %in% dts_list[[6]]
    
    
    mask_hurs = dts_hurs %in% dts_list[[1]]& dts_hurs %in% dts_list[[2]] &
      dts_hurs %in% dts_list[[3]]& dts_hurs %in% dts_list[[5]] &
      dts_hurs %in% dts_list[[5]]& dts_hurs %in% dts_list[[6]]
    
    
    mask_ps = dts_ps %in% dts_list[[1]]& dts_ps %in% dts_list[[2]] &
      dts_ps %in% dts_list[[3]]& dts_ps %in% dts_list[[5]] &
      dts_ps %in% dts_list[[5]]& dts_ps %in% dts_list[[6]]
    
    mask_psl = dts_psl %in% dts_list[[1]]& dts_psl %in% dts_list[[2]] &
      dts_psl %in% dts_list[[3]]& dts_psl %in% dts_list[[5]] &
      dts_psl %in% dts_list[[5]]& dts_psl %in% dts_list[[6]]
    
    
    dts = dts_tas[mask_tas]
    
    gauge_ids =str_split(ncatt_get(tas,varid = "id")$gauge_id,pattern = ",")[[1]]
    
    ind = str_detect(gauge_ids,"camelsaus_")
    strt_hist_mdl_id = which(ind)%>%min()
    cnt_hist_mdl_id = which(ind)%>%max()-strt_hist_mdl_id+1
    
    gauge_ids = gauge_ids[ind]
    
    
    tas_mat<-ncvar_get(tas,varid = "tas",
                       start = c(strt_hist_mdl_id,min(which(mask_tas))),
                       count = c(cnt_hist_mdl_id,max(which(mask_tas))-min(which(mask_tas))+1)
                       )
    
    rss_mat<-ncvar_get(rss,varid = "rss",
                       start = c(strt_hist_mdl_id,min(which(mask_rss))),
                       count = c(cnt_hist_mdl_id,max(which(mask_rss))-min(which(mask_rss))+1)
    )
    rls_mat<-ncvar_get(rls,varid = "rls",
                       start = c(strt_hist_mdl_id,min(which(mask_rls))),
                       count = c(cnt_hist_mdl_id,max(which(mask_rls))-min(which(mask_rls))+1)
    )
    ps_mat<-ncvar_get(ps,varid = "ps",
                      start = c(strt_hist_mdl_id,min(which(mask_ps))),
                      count = c(cnt_hist_mdl_id,max(which(mask_ps))-min(which(mask_ps))+1)
    )
    psl_mat<-ncvar_get(psl,varid = "psl",
                       start = c(strt_hist_mdl_id,min(which(mask_psl))),
                       count = c(cnt_hist_mdl_id,max(which(mask_psl))-min(which(mask_psl))+1)
    )
    hurs_mat<-ncvar_get(hurs,varid = "hurs",
                        start = c(strt_hist_mdl_id,min(which(mask_hurs))),
                        count = c(cnt_hist_mdl_id,max(which(mask_hurs))-min(which(mask_hurs))+1)
    )
    
    
    # cf <- CFtime::CFtime(tas$dim$time$units, tas$dim$time$calendar, tas$dim$time$vals)
    # dts <- as_timestamp(cf,format= "date")
    cal = tas$dim$time$calendar
    
    # dts_mat = rep(dts,dim(tas_mat)[1])%>%
    #   matrix(ncol = dim(tas_mat)[2],nrow = dim(tas_mat)[1],byrow = T)
    
    petmort_mat_ls = pet_morton_func(ta = tas_mat,
                                  ps = ps_mat,
                                  psl = psl_mat,
                                  rs = rss_mat,
                                  rl = rls_mat,
                                  hur = hurs_mat
                                  )
    
    et_morton_potential =( petmort_mat_ls$et_morton_potential-offsets["et_morton_potential"])*fctrs["et_morton_potential"]
    et_morton_wet =( petmort_mat_ls$et_morton_wet-offsets["et_morton_wet"])*fctrs["et_morton_wet"]
    et_morton_actual =( petmort_mat_ls$et_morton_actual-offsets["et_morton_actual"])*fctrs["et_morton_actual"]
    
    # create tdps ncdf file
    # get attributes from tas file
    
    
    time_dim <- tas$dim$time
    time_dim$vals = time_dim$vals[mask_tas]
    gauge_dim <- tas$dim$id
    
    gauge_dim$len = length(gauge_ids)
    gauge_dim$vals = 1:length(gauge_ids)
    if(cal=="360_day"){
      chunk_size = 3600
    }else{
      chunk_size = 3650
    }
    
    # potential
    var_def <- ncvar_def(
      name  = "et_morton_potential",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "mm",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Point potential evapotranspiration calculated by Morton's method (1983)",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    et_morton_potential_nc <- nc_create(paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/",
                            datasets_wide$source_id[it],
                            datasets_wide$experiment_id[it],
                            "et_morton_potential",
                            paste(
                              "et_morton_potential",
                              "day",
                              datasets_wide$source_id[it],
                              datasets_wide$experiment_id[it],
                              datasets_wide$variant_label[it],
                              datasets_wide$grid_label[it],
                              "uncorrected",
                              paste0(it_sub,
                                     ".nc"),
                              
                              sep ="_"
                            ),
                            sep= "/"
    ),
    vars = list(var_def))
    
    ncvar_put(et_morton_potential_nc, var_def, et_morton_potential)
    
    
    
    ncatt_put(et_morton_potential_nc, "id", "gauge_id", paste(gauge_ids,collapse = ","))
    ncatt_put(et_morton_potential_nc, 0, "institution_id",ncatt_get(tas,0,attname = "institution_id")$value)
    ncatt_put(et_morton_potential_nc, 0, "institution",ncatt_get(tas,0,attname = "institution")$value)
    ncatt_put(et_morton_potential_nc, 0, "source_id",ncatt_get(tas,0,attname = "source_id")$value)
    ncatt_put(et_morton_potential_nc, 0, "source",ncatt_get(tas,0,attname = "source")$value)
    ncatt_put(et_morton_potential_nc, 0, "experiment_id",ncatt_get(tas,0,attname = "experiment_id")$value)
    ncatt_put(et_morton_potential_nc, 0, "variant_label", ncatt_get(tas,0,attname = "variant_label")$value)
    ncatt_put(et_morton_potential_nc, 0, "grid_label",ncatt_get(tas,0,attname = "grid_label")$value)
    ncatt_put(et_morton_potential_nc, 0, "grid",ncatt_get(tas,0,attname = "grid")$value)
    
    
    ncatt_put(et_morton_potential_nc, 0, "license",ncatt_get(tas,0,attname = "license")$value)
    ncatt_put(et_morton_potential_nc, 0, "Conventions",ncatt_get(tas,0,attname = "Conventions")$value)
    ncatt_put(et_morton_potential_nc, 0, "contact",ncatt_get(tas,0,attname = "Contact")$value)
    ncatt_put(et_morton_potential_nc, 0, "further_info_url",ncatt_get(tas,0,attname = "further_info_url")$value)
    
    ncatt_put(et_morton_potential_nc, "et_morton_potential", "scale_factor", 1/fctrs["et_morton_potential"])
    ncatt_put(et_morton_potential_nc,"et_morton_potential", "add_offset", offsets["et_morton_potential"])
    
    nc_close(et_morton_potential_nc)
    
    # wet environment
    
    
    
    var_def <- ncvar_def(
      name  = "et_morton_wet",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "mm",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Wet-environment potential evapotranspiration calculated by Morton's method (1983)",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    et_morton_wet_nc <- nc_create(paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/",
                                        datasets_wide$source_id[it],
                                        datasets_wide$experiment_id[it],
                                        "et_morton_wet",
                                        paste(
                                          "et_morton_wet",
                                          "day",
                                          datasets_wide$source_id[it],
                                          datasets_wide$experiment_id[it],
                                          datasets_wide$variant_label[it],
                                          datasets_wide$grid_label[it],
                                          "uncorrected",
                                          paste0(it_sub,
                                                 ".nc"),
                                          
                                          sep ="_"
                                        ),
                                        sep= "/"
    ),
    vars = list(var_def))
    
    ncvar_put(et_morton_wet_nc, var_def, et_morton_wet)
    
    
    
    ncatt_put(et_morton_wet_nc, "id", "gauge_id", paste(gauge_ids,collapse = ","))
    ncatt_put(et_morton_wet_nc, 0, "institution_id",ncatt_get(tas,0,attname = "institution_id")$value)
    ncatt_put(et_morton_wet_nc, 0, "institution",ncatt_get(tas,0,attname = "institution")$value)
    ncatt_put(et_morton_wet_nc, 0, "source_id",ncatt_get(tas,0,attname = "source_id")$value)
    ncatt_put(et_morton_wet_nc, 0, "source",ncatt_get(tas,0,attname = "source")$value)
    ncatt_put(et_morton_wet_nc, 0, "experiment_id",ncatt_get(tas,0,attname = "experiment_id")$value)
    ncatt_put(et_morton_wet_nc, 0, "variant_label", ncatt_get(tas,0,attname = "variant_label")$value)
    ncatt_put(et_morton_wet_nc, 0, "grid_label",ncatt_get(tas,0,attname = "grid_label")$value)
    ncatt_put(et_morton_wet_nc, 0, "grid",ncatt_get(tas,0,attname = "grid")$value)
    
    
    ncatt_put(et_morton_wet_nc, 0, "license",ncatt_get(tas,0,attname = "license")$value)
    ncatt_put(et_morton_wet_nc, 0, "Conventions",ncatt_get(tas,0,attname = "Conventions")$value)
    ncatt_put(et_morton_wet_nc, 0, "contact",ncatt_get(tas,0,attname = "Contact")$value)
    ncatt_put(et_morton_wet_nc, 0, "further_info_url",ncatt_get(tas,0,attname = "further_info_url")$value)
    
    ncatt_put(et_morton_wet_nc, "et_morton_wet", "scale_factor", 1/fctrs["et_morton_wet"])
    ncatt_put(et_morton_wet_nc,"et_morton_wet", "add_offset", offsets["et_morton_wet"])
    nc_close(et_morton_wet_nc)
    
    
    # actual
    
    
    var_def <- ncvar_def(
      name  = "et_morton_actual",
      # units = sprintf("%s * %0.1f",unique(units(xRast)),fctrs[datasets$variable_id[it]]),
      units = "mm",
      dim   = list(gauge_dim, time_dim),
      missval = -32768,
      longname = "Areal actual evapotranspiration calculated by Morton's method (1983)",
      prec = "short",
      shuffle = T,
      compression = 9,
      chunk = c(10, chunk_size)
    )
    
    et_morton_actual_nc <- nc_create(paste("/scratch/ruzzante/temp/CMIP6_ESGF_uncorrected/",
                                           datasets_wide$source_id[it],
                                           datasets_wide$experiment_id[it],
                                           "et_morton_actual",
                                           paste(
                                             "et_morton_actual",
                                             "day",
                                             datasets_wide$source_id[it],
                                             datasets_wide$experiment_id[it],
                                             datasets_wide$variant_label[it],
                                             datasets_wide$grid_label[it],
                                             "uncorrected",
                                             paste0(it_sub,
                                                    ".nc"),
                                             
                                             sep ="_"
                                           ),
                                           sep= "/"
    ),
    vars = list(var_def))
    
    ncvar_put(et_morton_actual_nc, var_def, et_morton_actual)
    
    
    
    ncatt_put(et_morton_actual_nc, "id", "gauge_id", paste(gauge_ids,collapse = ","))
    ncatt_put(et_morton_actual_nc, 0, "institution_id",ncatt_get(tas,0,attname = "institution_id")$value)
    ncatt_put(et_morton_actual_nc, 0, "institution",ncatt_get(tas,0,attname = "institution")$value)
    ncatt_put(et_morton_actual_nc, 0, "source_id",ncatt_get(tas,0,attname = "source_id")$value)
    ncatt_put(et_morton_actual_nc, 0, "source",ncatt_get(tas,0,attname = "source")$value)
    ncatt_put(et_morton_actual_nc, 0, "experiment_id",ncatt_get(tas,0,attname = "experiment_id")$value)
    ncatt_put(et_morton_actual_nc, 0, "variant_label", ncatt_get(tas,0,attname = "variant_label")$value)
    ncatt_put(et_morton_actual_nc, 0, "grid_label",ncatt_get(tas,0,attname = "grid_label")$value)
    ncatt_put(et_morton_actual_nc, 0, "grid",ncatt_get(tas,0,attname = "grid")$value)
    
    
    ncatt_put(et_morton_actual_nc, 0, "license",ncatt_get(tas,0,attname = "license")$value)
    ncatt_put(et_morton_actual_nc, 0, "Conventions",ncatt_get(tas,0,attname = "Conventions")$value)
    ncatt_put(et_morton_actual_nc, 0, "contact",ncatt_get(tas,0,attname = "Contact")$value)
    ncatt_put(et_morton_actual_nc, 0, "further_info_url",ncatt_get(tas,0,attname = "further_info_url")$value)
    
    ncatt_put(et_morton_actual_nc, "et_morton_actual", "scale_factor", 1/fctrs["et_morton_actual"])
    ncatt_put(et_morton_actual_nc,"et_morton_actual", "add_offset", offsets["et_morton_actual"])
    
    
    
    nc_close(et_morton_actual_nc)
    
    
    nc_close(hurs)
    nc_close(tas)
    nc_close(ps)
    nc_close(psl)
    nc_close(rss)
    nc_close(rls)
    
    
    
    
  }
}




