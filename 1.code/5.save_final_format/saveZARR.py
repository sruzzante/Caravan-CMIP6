# Sacha Ruzzante
# sachawruzzante@gmail.com

# This script saves the bias-corrected Caravan data to a zarr file

# a great resource: https://guide.cloudnativegeo.org/zarr/zarr-in-practice.html

import numpy as np
import xarray as xr
import zarr
import pandas as pd
import numcodecs
import time
from numcodecs import Blosc
import os
import sys
#import matplotlib.pyplot as plt
from netCDF4 import Dataset

datasets = pd.read_csv("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/2.data/2.working/CMIP6_ESGF/caravan/datasets_caravan.csv")


# same gauge_ids for all arrays

gauge_list = pd.read_csv("/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/2.data/2.working/CMIP6_ESGF/caravan/gauge_list.csv")

gauge_ids = gauge_list['gauge_id']
# same gauge_ids for all arrays
# same compression for all variables
compressor = Blosc(
    cname="zstd",
    clevel=3,
    shuffle=Blosc.BITSHUFFLE
)
encoding = {vname: {'compressor': compressor} for vname in set(datasets['var_camels'])}

 # do this in xarray

source_ids = list(dict.fromkeys(datasets.source_id))

it_num = [int(sys.argv[1])]
store = zarr.storage.LocalStore("/scratch/ruzzante/temp/Caravan_CMIP6_QDM.zarr")

print(it_num)

for i in it_num:
    root = zarr.open_group(store, mode="a")
    #group_i = root.require_group(source_ids[i])
    datasets_i = datasets[datasets.source_id == source_ids[i]].reset_index(drop=True)
    experiment_ids = list(dict.fromkeys(datasets_i.experiment_id))
    experiment_ids = experiment_ids[::-1] # reverse
        
    for j in range(len(experiment_ids)):
        #group_ij = group_i.require_group(experiment_ids[j])
        
        datasets_ij = datasets_i[datasets_i.experiment_id == experiment_ids[j]].reset_index(drop=True)
         
        variant_labels = list(dict.fromkeys(datasets_ij.variant_label))
        variant_labels = variant_labels[::-1] # reverse

        for k in range(len(variant_labels)):
            #group_ijk =  group_ij.require_group(variant_labels[k])
            
            datasets_ijk = datasets_ij[datasets_ij.variant_label == variant_labels[k]].reset_index(drop=True)
            variable_ids = list(dict.fromkeys(datasets_ijk.var_camels))
            fname =  "/home/ruzzante/projects/def-tgleeson/ruzzante/caravan-CMIP6/2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM_caravan_netcdf/%s/%s/%s_%s_%s.nc" % \
                                 (datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],\
                                 datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],datasets_ijk.variant_label[0])

            # if os.path.isfile(fname): 
            #     continue

            dirname =  '/scratch/ruzzante/temp/Caravan_CMIP6_QDM.zarr/%s/%s/%s'%(datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],datasets_ijk.variant_label[0])
            if(os.path.isdir(dirname)):
                print('already exists:%s, skipping'%dirname)
                continue
            
            for l in range(datasets_ijk.shape[0]):
                print("starting %s" % datasets_ijk.var_camels[l])
                t = time.time()

                paths = [
                    "/project/6018060/ruzzante/caravan-CMIP6/2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_QDM/"
                    "%s/%s/%s/%s_day_%s_%s_%s_uncorrected_%d.nc"
                    % (
                        datasets_ijk.source_id[l],
                        datasets_ijk.experiment_id[l],
                        datasets_ijk.var_camels[l],
                        datasets_ijk.var_camels[l],
                        datasets_ijk.source_id[l],
                        datasets_ijk.experiment_id[l],
                        datasets_ijk.variant_label[l],
                        i
                    )
                    for i in range(1, 11)
                ]
                
                # add number_clamped
                max_reduce = []
                min_increase = []
                total_vals = []
                max_theo = []
                min_theo = []
                
                for path in paths:
                    with Dataset(path) as ds:
                        x0 = ds.variables[datasets_ijk.var_camels[l]].getncattr("number_clamped")
                        x1 = x0.split()
                        max_reduce.append(x1[3])
                        min_increase.append(x1[17])
                        total_vals.append(x1[6])
                        max_theo.append(x1[16])
                        min_theo.append(x1[27])
                max_reduce_sum = np.array(max_reduce, dtype=int).sum()
                min_increase_sum = np.array(min_increase, dtype=int).sum()
                total_vals_sum = np.array(total_vals, dtype=int).sum()
                
                
                x1[3] = max_reduce_sum
                x1[6] = total_vals_sum
                x1[17] = min_increase_sum
                
                number_clamped = " ".join(str(x) for x in x1)
                
                
                
                
                # combine subsets of same variable
                nc_comb = xr.open_mfdataset(paths,
                                            decode_cf=False,
                                            concat_dim = "id",
                                            combine='nested',
                                            chunks={},          
                                            #parallel=True,
                                            combine_attrs="override")
                
                
                nc_comb[datasets_ijk.var_camels[l]].attrs['_FillValue'] = datasets_ijk.fill_value[l]
                nc_comb[datasets_ijk.var_camels[l]].attrs['number_clamped'] = number_clamped
                
                # add gauge_id as the id variable
                nc_comb["id"] = gauge_ids
                # rechunk
                nc_comb[datasets_ijk.var_camels[l]] = nc_comb[datasets_ijk.var_camels[l]].chunk({"time":nc_comb.time.shape[0],"id":100})
                
                # append to full dataset
                
                if l==0:
                    nc_comb_ls = nc_comb
                else:
                    nc_comb_ls = xr.merge([nc_comb_ls,nc_comb],fill_value  = dict(zip(datasets_ijk['var_camels'], datasets_ijk['fill_value'])))
                
                print(time.time()-t)
            
            # t = time.time()
            # print("writing netcdf %s/%s/%s" % (datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],datasets_ijk.variant_label[0]))

            # os.makedirs("/scratch/ruzzante/temp/CMIP6_ESGF_QDM_caravan_netcdf/%s/%s/" % \
            #             (datasets_ijk.source_id[0],datasets_ijk.experiment_id[0]),
            #            exist_ok = True)
                     
            # nc_comb_ls.to_netcdf(fname,
            #                      mode = "w",
            #                     )    
            # print(time.time()-t)

            # reset id coordinate

            nc_comb_ls = nc_comb_ls.set_index(dim_0="id").rename({"dim_0": "id"})
            nc_comb_ls = nc_comb_ls.reset_coords(drop=True)
            
            t = time.time()
            print("writing zarr array %s/%s/%s" % (datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],datasets_ijk.variant_label[0]))
            nc_comb_ls.to_zarr("/scratch/ruzzante/temp/Caravan_CMIP6_QDM.zarr",
             group = "%s/%s/%s" % (datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],datasets_ijk.variant_label[0]),
             mode = "w",
             #append_dim=None,   # IMPORTANT
             zarr_format=2,   # CRITICAL
             encoding = encoding,
             #compressor=zarr.codecs.BloscCodec(cname='lz4', clevel=5, shuffle="shuffle", blocksize=0),
             consolidated = True)    
            print(time.time()-t)
            # variant metadata
            group_ijk = zarr.open_group('/scratch/ruzzante/temp/Caravan_CMIP6_QDM.zarr/%s/%s/%s'%(datasets_ijk.source_id[0],datasets_ijk.experiment_id[0],datasets_ijk.variant_label[0]))
            
            group_ijk.attrs.update({
             "variant_label":variant_labels[k]
            })
        
        # experiment id metadata
        group_ij = zarr.open_group('/scratch/ruzzante/temp/Caravan_CMIP6_QDM.zarr/%s/%s'%(datasets_ij.source_id[0],datasets_ij.experiment_id[0]))
        
        group_ij.attrs.update({
        "experiment_id" : experiment_ids[j]
        })
    # # source_id metadata
    nc = xr.open_dataset("../2.data/2.working/ClimateChangeProjections/CMIP6_ESGF_uncorrected/%s/%s/%s/%s_day_%s_%s_%s_%s_uncorrected_%d.nc"% (datasets_i.source_id[0],datasets_i.experiment_id[0],"tas","tas",datasets_i.source_id[0],datasets_i.experiment_id[0], datasets_i.variant_label[0],datasets_i.grid_label[0],1),decode_cf=False)
    
    group_i = zarr.open_group('/scratch/ruzzante/temp/Caravan_CMIP6_QDM.zarr/%s'%(datasets_i.source_id[0]))
    
    group_i.attrs.update({
    "institution_id": nc.attrs["institution_id"],
    "institution":  nc.attrs["institution"],
    "source_id": nc.attrs["source_id"],
    "source" : nc.attrs["source"],
    "license_GCM" : nc.attrs["license"],
    "Conventions": nc.attrs["Conventions"],
    "source_grid" : nc.attrs["grid"],
    "source_grid_label" : nc.attrs["grid_label"],
    "source_nominal_resolution": datasets_i.nominal_resolution[0]
     }
    )
