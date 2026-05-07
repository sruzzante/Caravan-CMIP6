
setwd("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/")
# setwd(paste0(Sys.getenv("USERPROFILE"), "/OneDrive - University of Victoria/low-flows-BC/")) #Set the working directory


suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(terra))
suppressMessages(library(lubridate))
suppressMessages(library(tictoc))
library(stringr)
library(ncdf4)
source("1.code/utils.R")


param_trans<-read.csv("2.data/2.working/histMetData/camels-aus/param_trans_camels_aus.csv")%>%
  filter(final_var)%>%
  mutate(data_type = "int16",
         fill_value = -32768)

datasets<-readRDS("2.data/2.working/CMIP6_ESGF/datasets_v2.rds")
datasets = rbind(datasets,
                 # datasets%>%filter(variable_id == "tasmax")%>%mutate(variable_id="tasmaxD"),
                 # datasets%>%filter(variable_id == "tasmin")%>%mutate(variable_id="tasminD"),
                 datasets%>%filter(variable_id == "tasmin")%>%mutate(variable_id="tasminDtasmax"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="petfao56"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="et_morton_potential"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="et_morton_actual"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="et_morton_wet"),
                 datasets%>%filter(variable_id == "tas")%>%mutate(variable_id="vp")
)




datasets_camels<-left_join(datasets,param_trans,by = c("variable_id" = "var_CMIP6"))%>%
  mutate(var_CMIP6 = variable_id)%>%
  filter(!is.na(var_camels))



# write.csv(datasets_ERA5,"2.data/2.working/CMIP6_ESGF/datasets_ERA5_vars.csv",row.names = F)
dir.create("2.data/2.working/CMIP6_ESGF/camelsaus/")


write.csv(datasets_camels%>%select(source_id,variant_label,experiment_id,grid_label,var_camels,longname_camels,
                                   units_camels,scale_camels,offset_camels,nominal_resolution, 
                                   data_type, fill_value),
          "2.data/2.working/CMIP6_ESGF/camelsaus/datasets_camelsaus.csv",row.names = F)

datasets_camels_raw = 
datasets_camels%>%select(source_id,variant_label,experiment_id,grid_label,var_CMIP6,
                         units_CMIP6,nominal_resolution, 
                         data_type, fill_value)
datasets_camels_raw = datasets_camels_raw[!duplicated(datasets_camels_raw),]


write.csv(datasets_camels_raw,
          "2.data/2.working/CMIP6_ESGF/camelsaus/datasets_camelsaus_raw.csv",row.names = F)
