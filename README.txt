This README.txt file was last updated on 2026-04-23 by Sacha Ruzzante

--------------------
GENERAL INFORMATION
--------------------

1. Title of Dataset: Caravan-CMIP6: Bias-corrected climate model projections for ten large-sample hydrometeorological datasets and over 23,000 global catchments

2. Author Information
    Name: Sacha Ruzzante
    Institution:  University of Victoria
    Email: sachawruzzante@gmail.com

3. Date of data collection: 2025-12-15 to 2026-04-01

4. Geographic location of data collection: The Caravan data are global 
   There are also data for 9 large-sample hydrometeorological (CAMELS) datasets, for the United States, Brazil, Chile, Colombia, Germany, Great Britain, Switzerland, India, and Australia

---------------------------
SHARING/ACCESS INFORMATION
---------------------------

1. Licenses/restrictions placed on the data: 

    These data are available under a Creative Commons Attribution 4.0 International License (CC BY 4.0; https://creativecommons.org/licenses/by/4.0/). By using these data you agree to also cite the relevant publications for the CAMELS datasets and the CMIP6 models.
	
    All CMIP6 data are also distributed under a CC BY 4.0 license. Please note that this supersedes the information in the 'license_GCM' global attribute found in the netCDF file headers of each file, which has been copied verbatim from the CMIP6 output files. Consult https://pcmdi.llnl.gov/CMIP6/TermsOfUse for terms of use governing CMIP6 output, including citation requirements and proper acknowledgment. The data producers and data providers make no warranty, either express or implied, including, but not limited to, warranties of merchantability and fitness for a particular purpose. All liabilities arising from the supply of the information (including any liability arising in negligence) are excluded to the fullest extent permitted by law.
	
    The license information for the large-sample hydro-meteorological datasets are as follows:
	
    Caravan: CC BY 4.0
    CAMELS: CC BY 4.0
    CAMELS-AUS: CC BY 4.0
    CAMELS-BR: CC BY 4.0
    CAMELS-CH: CC BY 4.0
    CAMELS-CL: CC BY 4.0
    CAMELS-COL: CC BY 4.0
    CAMELS-DE: CC BY 4.0
    CAMELS-GB-v2: Open Government License v3: https://eidc.ac.uk/licences/ogl/plain. Contains data supplied by UK Centre for Ecology & Hydrology.
    CAMELS-IND: CC BY 4.0
	
	
2. Links to publications that cite or use the data:     

3. Links/relationships to ancillary data sets or software packages: 

5. Was data derived from another source? yes
    The data are derived from 12 CMIP6 models and from 10 large-sample hydrology datasets. 

6. Recommended citation for this dataset: 
    Ruzzante, S. (2026). Caravan-CMIP6: Bias-corrected climate model projections for ten large-sample hydrometeorological datasets and over 25,000 global catchments. Federated Research Data Repository. https://doi.org/10.20383/103.01644

-------------------------
Folder and File Structure
-------------------------

Files are arranged in the following hierarchy:

Caravan-CMIP6
└── <LSH dataset>
    └── <RAW/QDM>
        └── <source_id>
            └── <experiment_id>
                └── <source_id>_<experiment_id>_<variant_label>.nc

<LSH dataset> denotes each of the 'CAMELS' datasets for which we extracted and bias-corrected climate data:
    - Caravan (Kratzert et al., 2023)
    - CAMELS (Newman et al., 2015; Addor et al., 2017)
    - CAMELS-AUS-v2 (Fowler et al., 2024)
    - CAMELS-BR (Chagas et al., 2020)
    - CAMELS-CH (Höge et al., 2023)
    - CAMELS-CL (Alvarez-Garreton et al., 2018)
    - CAMELS-COL (Jimenez et al., 2025)
    - CAMELS-DE (Loritz et al., 2024)
    - CAMELS-GB-v2 (Coxon et al., 2025)
    - CAMELS-IND (Mangukiya et al., 2025)
    
<RAW/QDM> denotes whether the data are the raw extracted climate model data (RAW), or the bias-corrected data (QDM). The bias-correction is done using Quantile Delta Mapping.

<source_id> is the CMIP6 model id:
    - ACCESS-ESM1-5 (Ziehn et al., 2020)
    - CanESM5 (Swart et al., 2019)
    - CNRM-CM6-1-HR (Voldoire et al., 2019)
    - EC-Earth3 (Döscher et al., 2022)
    - GFDL-CM4 (Held et al., 2019)
    - INM-CM5-0 (Volodin and Gritsun., 2018)
    - IPSL-CM6A-LR (Boucher et al., 2020)
    - MIROC6 (Tatebe et al., 2019)
    - MPI-ESM1-2-HR (Mauritsen et al., 2019)
    - MRI-ESM2-0 (Yukimoto et al, 2019)
    - TaiESM1 (Lee et al., 2020)
    - UKESM1-0-LL (Sellar et al., 2019)

<experiment_id> is the CMIP6 experiment identifier:
    - historical: 1850-2014
    - ssp126: 'Sustainability', 
    - ssp245: 'Middle of the road'
    - ssp585: 'Fossil-fueled development'

<variant_label> is the 'ripf' identifier for each ensemble member. See https://pcmdi.llnl.gov/CMIP6/Guide/dataUsers.html#:~:text=Individual%20members%20of%20an%20ensemble for details.
    
Within the lowest-level directory are the netcdf files for all variants associated with particular climate model. Each netcdf file contains a set of variables, and is indexed by 'id' (the catchment identifier) and 'time'. 

---------------------
Variables
---------------------
The 'raw' data files contain the following variables. For each LSH dataset, only raw variables corresponding to the bias-corrected data are included

Raw data variables
    Variable            Long_Name                                                                                               Units
    tas                 Near-surface air temperature (usually 2 m)                                                              K
    tasmax              Near-surface maximum daily air temperature (usually 2 m)                                                K
    tasmin              Near-surface maximum daily air temperature (usually 2 m)                                                K
    hurs                Near-surface relative humidity                                                                          %
    pr                  Precipitation                                                                                           kg m-2 s-1
    ps                  Surface air pressure                                                                                    Pa
    psl                 Sea level pressure                                                                                      Pa
    rlds                Surface downwelling longwave radiation                                                                  W m-2
    rlus                Surface upwelling longwave radiation                                                                    W m-2
    rls                 Net longwave surface radiation (downwards)                                                              W m-2
    rsds                Surface downwelling shortwave radiation                                                                 W m-2
    rsus                Surface upwelling shortwave radiation                                                                   W m-2
    rss                 Net shortwave surface radiation (downwards)                                                             W m-2
    sfcWind             Near-surface wind speed (10 m)                                                                          m s-1
    tdps                2 m dewpoint temperature                                                                                K
    vp                  Water vapour pressure                                                                                   Pa
    vpDeficit           Water vapour pressure deficit                                                                           Pa
    vpSat               Saturation water vapour pressure                                                                        Pa
    petfao56            Potential evapotranspiration calculated using the FAO-56 Penman-Monteith formula (Allen et al., 1998)   kg m-2 day-1
    petharg             Potential evapotranspiration calculated using the Hargreaves formula (Hargreaves and Samani, 1985)      kg m-2 day-1
    petpriestly         Potential evapotranspiration calculated using the Priestly-Taylor formula (Priestley and Taylor, 1972)  kg m-2 day-1
    et_morton_potential Potential (point) evapotranspiration calculated using the Morton formula (Morton, 1983)                 kg m-2 day-1
    et_morton_actual    Areal actual evapotranspiration calculated using the Morton formula (Morton, 1983)                      kg m-2 day-1
    et_morton_wet       Wet environment areal potential evapotranspiration calculated using the Morton formula (Morton, 1983)   kg m-2 day-1

---------------------
Below are the variables provided by each of the bias-corrected datasets:
---------------------
Caravan
    Variable                                        Long_Name                                                                    Units
    surface_net_solar_radiation_mean                Surface net solar radiation                                                  W/m2
    surface_net_thermal_radiation_mean              Surface net thermal radiation                                                W/m2
    surface_pressure_mean                           Surface pressure                                                             kPa
    temperature_2m_mean                             2m air temperature                                                           °C
    wind_10m_mean                                   wind speed at 10 m                                                           m/s
    total_precipitation_sum                         Total precipitation                                                          mm
    potential_evaporation_sum_FAO_PENMAN_MONTEITH   Potential Evaporation (FAO Penman-Monteith computed from ERA5-Land inputs)   mm
    dewpoint_temperature_2m_mean                    Dew point temperature                                                        °C
    temperature_2m_min                              2m minimum air temperature                                                   °C
    temperature_2m_max                              2m max air temperature                                                       °C
---------------------
CAMELS
    Variable            Long_Name                                                                                           Units
    tmax.C.daymet       2m max air temperature from daymet                                                                  °C
    tmin.C.daymet       2m max air temperature from daymet                                                                  °C
    tmean.C.maurer      2m mean air temperature from maurer*                                                                °C
    tmean.C.nldas       2m mean air temperature from nldas*                                                                 °C
    prcp.mm.day.daymet  Total precipitation from daymet                                                                     mm
    prcp.mm.day.maurer  Total precipitation from maurer                                                                     mm
    prcp.mm.day.nldas   Total precipitation from nldas                                                                      mm
    vp.Pa.daymet        Water vapor pressure from daymet                                                                    Pa
    vp.Pa.maurer        Water vapor pressure from maurer                                                                    Pa
    vp.Pa.nldas         Water vapor pressure from nldas                                                                     Pa
    srad.W.m2.daymet    Incident shortwave radiation flux density from daymet, average over the daylight period of the day. W m-2
    srad.W.m2.maurer    Incident shortwave radiation flux density from maurer, average over the daylight period of the day. W m-2
    srad.W.m2.nldas     Incident shortwave radiation flux density from nldas, average over the daylight period of the day.  W m-2
    dayl.s.             Duration of the daylight period. Based on the time the sun is above a hypothetical flat horizon.    s
    
* for the Maurer and NLDAS forcings, the maximum and minimum temperatures in CAMELS are in fact the mean daily temperature
---------------------
CAMELS-AUS-v2
    Variable                Long_Name                                                                                                                       Units
    precipitation_AGCD      Daily precipitation from Australian Gridded Climate Data v1.0.1 (Evans et al., 2020)                                            mm
    precipitation_SILO      Daily precipitation from Scientific Information for Land Owners (Jeffrey et al., 2001)                                          mm
    et_short_crop_SILO      FAO56 short crop Potential evapotranspiration from  Scientific Information for Land Owners (Jeffrey et al., 2001)               mm
    et_morton_point_SILO    Morton's (1983) Point (potential) evapotranspiration from Scientific Information for Land Owners (Jeffrey et al., 2001)         mm
    et_morton_wet_SILO      Morton's (1983) wet-environment potential evapotranspiration from Scientific Information for Land Owners (Jeffrey et al., 2001) mm
    et_morton_actual_SILO   Morton's (1983) areal actual  evapotranspiration from Scientific Information for Land Owners (Jeffrey et al., 2001)             mm
    tmax_AGCD               Daily maximum temperature from Australian Gridded Climate Data v1.0.1 (Evans et al., 2020)                                      °C
    tmin_AGCD               Daily minimum temperature from Australian Gridded Climate Data v1.0.1 (Evans et al., 2020)                                      °C
    tmax_SILO               Daily maximum temperature from Scientific Information for Land Owners (Jeffrey et al., 2001)                                    °C
    tmin_SILO               Daily minimum temperature from Scientific Information for Land Owners (Jeffrey et al., 2001)                                    °C
    radiation_SILO          Solar radiation from  Scientific Information for Land Owners (Jeffrey et al., 2001)                                             MJ m-2
    mslp_SILO               Mean sea-level pressure from  Scientific Information for Land Owners (Jeffrey et al., 2001)                                     hPa
    vp_SILO                 Vapour pressure from Scientific Information for Land Owners (Jeffrey et al., 2001)                                              hPa
    vp_deficit_SILO         Vapour pressure deficit from Scientific Information for Land Owners (Jeffrey et al., 2001)                                      hPa
---------------------
CAMELS-BR
    Variable        Long_Name                                                                              Units
    p_brdwgd        Daily precipitation from Brazilian Daily Weather Gridded Data(BR-DWGD) v3.2.3          mm
    p_chirps        Daily precipitation from CHIRPS v2.0                                                   mm
    p_cpc           Daily precipitation from CPC                                                           mm
    p_era5land      Daily precipitation from ERA5-Land                                                     mm
    p_mswep         Daily precipitation from MSWEP v2.8                                                    mm    
    eto_brdwgd      Reference evapotranspiration from Brazilian Daily Weather Gridded Data(BR-DWGD) v3.2.3 mm
    pet_gleam       Potential evapotranspiration from GLEAM v4.2a                                          mm
    tmax_cpc        Daily maximum temperature from CPC                                                     °C
    tmax_era5land   Daily maximum temperature from ERA5LAND                                                °C
    tmax_brdwgd     Daily maximum temperature from Brazilian Daily Weather Gridded Data(BR-DWGD) v3.2.3    °C
    tmean_era5land  Daily mean temperature from ERA5LAND                                                   °C
    tmin_cpc        Daily minimum temperature from CPC                                                     °C
    tmin_era5land   Daily minimum temperature from ERA5LAND                                                °C
    tmin_brdwgd     Daily minimum temperature from Brazilian Daily Weather Gridded Data(BR-DWGD) v3.2.3    °C
---------------------
CAMELS-CH
    Variable                Long_Name                                                Units
    precipitation.mm.d.     Observed daily summed precipitiation                    mm
    temperature_mean.degC.  Observed daily averaged temperature                     °C
    precipitation_sim.mm.d. Simulated daily averaged precipitation                  mm
    temperature_sim.degC.   Simulated daily averaged temperature                    °C
    radiation_sim.W.m2.     Simulated daily averaged global radiation               W m-2
    wind_sim.m.s.           Simulated daily averaged wind speed                     m s-1
    rel_humidity_sim...     Simulated daily averaged relative humidity              []
    pet_sim.mm.d.           Simulated daily averaged potential evapotranspiration   mm
    temperature_min.degC.   Observed daily minimum temperature                      °C
    temperature_max.degC.   Observed daily maximum temperature                      °C
---------------------    
CAMELS-CL
    Variable                Long_Name                                                                Units
    precip_chirps_mm_day    Daily precipitation from CHIRPS version 2                                mm
    precip_cr2met_mm_day    Daily precipitation from CR2METv1.3                                      mm
    precip_mswep_mm_day     Daily precipitation from MSWEP v1.1                                      mm
    tmean_cr2met_C_day      Daily mean temperature from CR2METv1.3                                   °C
    pet_hargreaves_mm_day   Potential evapotranspiration calculated using Hargreaves (1985) formula  mm
    tmin_cr2met_C_day       Daily minimum temperature from CR2METv1.3                                °C
    tmax_cr2met_C_day       Daily maximum temperature from CR2METv1.3                                °C
---------------------
CAMELS-COL
    Variable    Long_Name                                       Units
    pr          Daily precipitation of catchment                mm
    t_mean      Daily maximum temperature of catchment          °C
    poten_evapo Daily potential evapotranspiration of catchment mm
    t_min       Daily minimum temperature of catchment          °C
    t_max       Daily maximum temperature of catchment          °C
---------------------    
CAMELS-DE
    Variable               Long_Name                                                                            Units
    pet_hargreaves         Daily mean of potential evapotranspiration calculated using the Hargreaves equation  mm d-1
    precipitation_mean     Observed interpolated spatial mean precipitation                                     mm d-1
    temperature_min        Observed interpolated spatial mean daily minimum temperatures                        °C
    temperature_mean       Observed interpolated spatial mean daily mean temperatures                           °C
    temperature_max        Observed interpolated spatial mean daily maximum temperatures                        °C
    humidity_mean          Observed interpolated spatial mean of the daily humidity                             %
    radiation_global_mean  Observed interpolated spatial mean of the global radiation                           W m-2
---------------------
CAMELS-GB-v2
    Variable                 Long_Name                                                 Units
    precipitation_cehgear    Daily total precipitation from CEHGEAR dataset            mm
    precipitation_haduk      Daily total precipitation from HadUK-Grid dataset         mm
    pet_chess                Potential Evapotranspiration from the CHESS dataset       mm
    pet_hydrope    Potential Evapotranspiration from the Hydro-PE HadUK-grid dataset   mm
    temperature_chess        Daily mean temperature from CHESS datasest                °C
    temperature_haduk        Daily mean temperature from the HadUK-Grid dataset        °C
---------------------     
CAMELS-IND    
    Variable            Long_Name                                   Units
    prcp.mm.day.        precipitation                               mm
    tmin.C.             minimum temperature                         °C
    tmax.C.             maximum temperature                         °C
    tavg.C.             averaged temperature                        °C
    srad_lw.w.m2.       surface downward long-wave radiation flux   W m-2
    srad_sw.w.m2.       surface downward short-wave radiation flux  W m-2
    wind.m.s.           averaged wind speed (10 m)                  m s-1
    rel_hum...          relative humidity (2 m)                     %
    pet.mm.day.         potential evapotranspiration (Singer)       mm d-1
    pet_gleam.mm.day.   potential evapotranspiration (GLEAM)        mm d-1 
---------------------           

---------------------------
METHODOLOGICAL INFORMATION
---------------------------
Please see the forthcoming journal preprint for methodological details. Brief descriptions are provided below.

1. Description of methods used for collection/generation of data: 
    CMIP6 model was downloaded from the Earth System Grid Fundation (ESGF; https://esgf.github.io/nodes.html)
    The observed meteorological data and catchment shapefiles were downloaded from each of the LSH datasets

2. Methods for processing the data: 
    First, basin-average raw climate data were extracted from the climate model rasters using the terra::extract function in R with catchment shapefiles.
	
    Second, several variables that are not routinely reported in the climate models were calculated for each catchment. These include:
        surface air pressure: calculated from sea level pressure and air temperature
        dewpoint temperature: calculated from relative humidity and temperature
        vapour pressure: calculated from relative humidity and temperature
        wind speed: calculated from eastward and northward compoents of wind speed
        net radiation: net total radiation and net longwave and shortwave radiation are calculated from the upwelling and downwelling shortwave and longwave radiation
        evapotranspiration: Penman-Monteith, Hargreaves, Priestly-Taylor, and Morton algorithms provide different estimates of potential and actual evapotranspiration
        diel temperature ranges: the difference between maximum, minimum, and mean temperatures are calculated because it is preferable to bias-correct these variables than the raw maximum and minimum temperature
		
    Third, we bias-correct climate model output to match meteorological observations from 1981-2010 using Quantile Delta Mapping (QDM) from the MBC R package (Cannon, 2024; Cannon et al., 2015). We use sliding windows of 1.5 months across the year and 30 years across decades, always replacing the central half-month and the central decade, to preserve the seasonal cycle and to avoid conflating variability associated with the non-stationarity with natural interannual variability. More details will be provided in the forthcoming journal publication.
    
    Fourth, the corrected maximum and minimum temperatures are calculated from the corrected mean temperature and the corrected diel ranges. For CAMELS-AUS, the corrected vapour pressure deficit is calculated from the corrected vapour pressure and the corrected temperature.

    Lastly, some reasonable and theoretical limits are applied to the data to ensure bias correction does not introduce physically unrealistic or impossible values. These limits, and the number of affected data points, are provided in the "number_clamped" attribute of each variable.

3. Instrument- or software-specific information needed to interpret the data: 
    Note that the time dimension uses Climate and Forecast (CF) Metadata Conventions. Special handling of dates is required to account for different calendars (proleptic_gregorian, no_leap, and 360_day)


----------
References
----------
Addor, N., Newman, A. J., Mizukami, N., and Clark, M. P.: The CAMELS data set: catchment attributes and meteorology for large-sample studies, Hydrology and Earth System Sciences, 21, 5293–5313, https://doi.org/10.5194/hess-21-5293-2017, 2017.

Alvarez-Garreton, C., Mendoza, P. A., Boisier, J. P., Addor, N., Galleguillos, M., Zambrano-Bigiarini, M., Lara, A., Puelma, C., Cortes, G., Garreaud, R., McPhee, J., and Ayala, A.: The CAMELS-CL dataset: catchment attributes and meteorology for large sample studies – Chile dataset, Hydrology and Earth System Sciences, 22, 5817–5846, https://doi.org/10.5194/hess-22-5817-2018, 2018.

Arsenault, R., Brissette, F., Martel, J.-L., Troin, M., Lévesque, G., Davidson-Chaput, J., Gonzalez, M. C., Ameli, A., and Poulin, A.: A comprehensive, multisource database for hydrometeorological modeling of 14,425 North American watersheds, Sci Data, 7, 243, https://doi.org/10.1038/s41597-020-00583-2, 2020.

Boucher, O., Servonnat, J., Albright, A. L., Aumont, O., Balkanski, Y., Bastrikov, V., Bekki, S., Bonnet, R., Bony, S., Bopp, L., Braconnot, P., Brockmann, P., Cadule, P., Caubel, A., Cheruy, F., Codron, F., Cozic, A., Cugnet, D., D’Andrea, F., Davini, P., de Lavergne, C., Denvil, S., Deshayes, J., Devilliers, M., Ducharne, A., Dufresne, J.-L., Dupont, E., Éthé, C., Fairhead, L., Falletti, L., Flavoni, S., Foujols, M.-A., Gardoll, S., Gastineau, G., Ghattas, J., Grandpeix, J.-Y., Guenet, B., Guez, E., Lionel, Guilyardi, E., Guimberteau, M., Hauglustaine, D., Hourdin, F., Idelkadi, A., Joussaume, S., Kageyama, M., Khodri, M., Krinner, G., Lebas, N., Levavasseur, G., Lévy, C., Li, L., Lott, F., Lurton, T., Luyssaert, S., Madec, G., Madeleine, J.-B., Maignan, F., Marchand, M., Marti, O., Mellul, L., Meurdesoif, Y., Mignot, J., Musat, I., Ottlé, C., Peylin, P., Planton, Y., Polcher, J., Rio, C., Rochetin, N., Rousset, C., Sepulchre, P., Sima, A., Swingedouw, D., Thiéblemont, R., Traore, A. K., Vancoppenolle, M., Vial, J., Vialard, J., Viovy, N., and Vuichard, N.: Presentation and Evaluation of the IPSL-CM6A-LR Climate Model, Journal of Advances in Modeling Earth Systems, 12, e2019MS002010, https://doi.org/10.1029/2019MS002010, 2020.

Cannon, A. J., Sobie, S. R., and Murdock, T. Q.: Bias Correction of GCM Precipitation by Quantile Mapping: How Well Do Methods Preserve Changes in Quantiles and Extremes?, Journal of Climate, 28, 6938–6959, https://doi.org/10.1175/JCLI-D-14-00754.1, 2015.

Cannon, A. J.: MBC: Multivariate Bias Correction of Climate Model Outputs, CRAN [code], https://doi.org/10.32614/CRAN.package.MBC, 2024a.

Casado Rodríguez, J.: CAMELS-ES: Catchment Attributes and Meteorology for Large-Sample Studies – Spain, https://doi.org/10.5281/zenodo.15040948, 2025.

Chagas, V. B. P., Chaffe, P. L. B., Addor, N., Fan, F. M., Fleischmann, A. S., Paiva, R. C. D., and Siqueira, V. A.: CAMELS-BR: hydrometeorological time series and landscape attributes for 897 catchments in Brazil, Earth System Science Data, 12, 2075–2096, https://doi.org/10.5194/essd-12-2075-2020, 2020.

Coxon, G., Zheng, Y., Barbedo, R., Cooper, H., Fileni, F., Fowler, H. J., Fry, M., Green, A., Gribbin, T., Harfoot, H., Lewis, E., Neto, G. G. R., Qiu, X., Salwey, S., and Wendt, D. E.: CAMELS-GB v2: hydrometeorological time series and landscape attributes for 671 catchments in Great Britain, Earth System Science Data Discussions, 1–44, https://doi.org/10.5194/essd-2025-608, 2025.

Döscher, R., Acosta, M., Alessandri, A., Anthoni, P., Arsouze, T., Bergman, T., Bernardello, R., Boussetta, S., Caron, L.-P., Carver, G., Castrillo, M., Catalano, F., Cvijanovic, I., Davini, P., Dekker, E., Doblas-Reyes, F. J., Docquier, D., Echevarria, P., Fladrich, U., Fuentes-Franco, R., Gröger, M., v. Hardenberg, J., Hieronymus, J., Karami, M. P., Keskinen, J.-P., Koenigk, T., Makkonen, R., Massonnet, F., Ménégoz, M., Miller, P. A., Moreno-Chamarro, E., Nieradzik, L., van Noije, T., Nolan, P., O’Donnell, D., Ollinaho, P., van den Oord, G., Ortega, P., Prims, O. T., Ramos, A., Reerink, T., Rousset, C., Ruprich-Robert, Y., Le Sager, P., Schmith, T., Schrödner, R., Serva, F., Sicardi, V., Sloth Madsen, M., Smith, B., Tian, T., Tourigny, E., Uotila, P., Vancoppenolle, M., Wang, S., Wårlind, D., Willén, U., Wyser, K., Yang, S., Yepes-Arbós, X., and Zhang, Q.: The EC-Earth3 Earth system model for the Coupled Model Intercomparison Project 6, Geoscientific Model Development, 15, 2973–3020, https://doi.org/10.5194/gmd-15-2973-2022, 2022.

Efrat, M.: Caravan extension Israel - Israel dataset for large-sample hydrology, https://doi.org/10.5281/zenodo.15003600, 2025.

Färber, C., Plessow, H., Mischel, S., Kratzert, F., Addor, N., Shalev, G., and Looser, U.: GRDC-Caravan: extending the original dataset with data from the Global Runoff Data Centre (0.5), https://doi.org/10.5281/zenodo.15124865, 2025.

Fowler, K. J. A., Zhang, Z., and Hou, X.: CAMELS-AUS v2: updated hydrometeorological time series and landscape attributes for an enlarged set of catchments in Australia, Earth System Science Data, 17, 4079–4095, https://doi.org/10.5194/essd-17-4079-2025, 2025.

Held, I. M., Guo, H., Adcroft, A., Dunne, J. P., Horowitz, L. W., Krasting, J., Shevliakova, E., Winton, M., Zhao, M., Bushuk, M., Wittenberg, A. T., Wyman, B., Xiang, B., Zhang, R., Anderson, W., Balaji, V., Donner, L., Dunne, K., Durachta, J., Gauthier, P. P. G., Ginoux, P., Golaz, J.-C., Griffies, S. M., Hallberg, R., Harris, L., Harrison, M., Hurlin, W., John, J., Lin, P., Lin, S.-J., Malyshev, S., Menzel, R., Milly, P. C. D., Ming, Y., Naik, V., Paynter, D., Paulot, F., Ramaswamy, V., Reichl, B., Robinson, T., Rosati, A., Seman, C., Silvers, L. G., Underwood, S., and Zadeh, N.: Structure and Performance of GFDL’s CM4.0 Climate Model, Journal of Advances in Modeling Earth Systems, 11, 3691–3727, https://doi.org/10.1029/2019MS001829, 2019.

Helgason, H. B. and Nijssen, B.: LamaH-Ice: LArge-SaMple DAta for Hydrology and Environmental Sciences for Iceland, Earth System Science Data, 16, 2741–2771, https://doi.org/10.5194/essd-16-2741-2024, 2024.

Höge, M., Kauzlaric, M., Siber, R., Schönenberger, U., Horton, P., Schwanbeck, J., Floriancic, M. G., Viviroli, D., Wilhelm, S., Sikorska-Senoner, A. E., Addor, N., Brunner, M., Pool, S., Zappa, M., and Fenicia, F.: CAMELS-CH: hydro-meteorological time series and landscape attributes for 331 catchments in hydrologic Switzerland, Earth System Science Data, 15, 5755–5784, https://doi.org/10.5194/essd-15-5755-2023, 2023.

Jimenez, D. A., Meneses, J. E., Solha, P. H. B., Avila-Diaz, A., Quesada, B., Melo Brentan, B., and Ferreira Rodrigues, A.: CAMELS-COL: A Large-Sample Hydrometeorological Dataset for Colombia, Earth System Science Data Discussions, 1–38, https://doi.org/10.5194/essd-2025-200, 2025.

Klingler, C., Schulz, K., and Herrnegger, M.: LamaH-CE: LArge-SaMple DAta for Hydrology and Environmental Sciences for Central Europe, Earth System Science Data, 13, 4529–4565, https://doi.org/10.5194/essd-13-4529-2021, 2021.

Kratzert, F., Nearing, G., Addor, N., Erickson, T., Gauch, M., Gilon, O., Gudmundsson, L., Hassidim, A., Klotz, D., Nevo, S., Shalev, G., and Matias, Y.: Caravan - A global community dataset for large-sample hydrology, Sci Data, 10, 61, https://doi.org/10.1038/s41597-023-01975-w, 2023.

Lee, W.-L., Wang, Y.-C., Shiu, C.-J., Tsai, I. -chun, Tu, C.-Y., Lan, Y.-Y., Chen, J.-P., Pan, H.-L., and Hsu, H.-H.: Taiwan Earth System Model Version 1: description and evaluation of mean state, Geoscientific Model Development, 13, 3887–3904, https://doi.org/10.5194/gmd-13-3887-2020, 2020.

Liu, J., Koch, J., Stisen, S., Troldborg, L., Højberg, A. L., Thodsen, H., Hansen, M. F. T., and Schneider, R. J. M.: CAMELS-DK: Hydrometeorological Time Series and Landscape Attributes for 3330 Catchments in Denmark, Earth System Science Data Discussions, 1–30, https://doi.org/10.5194/essd-2024-292, 2024.

Loritz, R., Dolich, A., Acuña Espinoza, E., Ebeling, P., Guse, B., Götte, J., Hassler, S. K., Hauffe, C., Heidbüchel, I., Kiesel, J., Mälicke, M., Müller-Thomy, H., Stölzle, M., and Tarasova, L.: CAMELS-DE: hydro-meteorological time series and attributes for 1582 catchments in Germany, Earth System Science Data, 16, 5625–5642, https://doi.org/10.5194/essd-16-5625-2024, 2024.

Mangukiya, N. K., Kumar, K. B., Dey, P., Sharma, S., Bejagam, V., Mujumdar, P. P., and Sharma, A.: CAMELS-IND: hydrometeorological time series and catchment attributes for 228 catchments in Peninsular India, Earth System Science Data, 17, 461–491, https://doi.org/10.5194/essd-17-461-2025, 2025.

Mauritsen, T., Bader, J., Becker, T., Behrens, J., Bittner, M., Brokopf, R., Brovkin, V., Claussen, M., Crueger, T., Esch, M., Fast, I., Fiedler, S., Fläschner, D., Gayler, V., Giorgetta, M., Goll, D. S., Haak, H., Hagemann, S., Hedemann, C., Hohenegger, C., Ilyina, T., Jahns, T., Jimenéz-de-la-Cuesta, D., Jungclaus, J., Kleinen, T., Kloster, S., Kracher, D., Kinne, S., Kleberg, D., Lasslop, G., Kornblueh, L., Marotzke, J., Matei, D., Meraner, K., Mikolajewicz, U., Modali, K., Möbis, B., Müller, W. A., Nabel, J. E. M. S., Nam, C. C. W., Notz, D., Nyawira, S.-S., Paulsen, H., Peters, K., Pincus, R., Pohlmann, H., Pongratz, J., Popp, M., Raddatz, T. J., Rast, S., Redler, R., Reick, C. H., Rohrschneider, T., Schemann, V., Schmidt, H., Schnur, R., Schulzweida, U., Six, K. D., Stein, L., Stemmler, I., Stevens, B., von Storch, J.-S., Tian, F., Voigt, A., Vrese, P., Wieners, K.-H., Wilkenskjeld, S., Winkler, A., and Roeckner, E.: Developments in the MPI-M Earth System Model version 1.2 (MPI-ESM1.2) and Its Response to Increasing CO2, Journal of Advances in Modeling Earth Systems, 11, 998–1038, https://doi.org/10.1029/2018MS001400, 2019.

Newman, A. J., Clark, M. P., Sampson, K., Wood, A., Hay, L. E., Bock, A., Viger, R. J., Blodgett, D., Brekke, L., Arnold, J. R., Hopson, T., and Duan, Q.: Development of a large-sample watershed-scale hydrometeorological data set for the contiguous USA: data set characteristics and assessment of regional variability in hydrologic model performance, Hydrology and Earth System Sciences, 19, 209–223, https://doi.org/10.5194/hess-19-209-2015, 2015.

Sellar, A. A., Jones, C. G., Mulcahy, J. P., Tang, Y., Yool, A., Wiltshire, A., O’Connor, F. M., Stringer, M., Hill, R., Palmieri, J., Woodward, S., de Mora, L., Kuhlbrodt, T., Rumbold, S. T., Kelley, D. I., Ellis, R., Johnson, C. E., Walton, J., Abraham, N. L., Andrews, M. B., Andrews, T., Archibald, A. T., Berthou, S., Burke, E., Blockley, E., Carslaw, K., Dalvi, M., Edwards, J., Folberth, G. A., Gedney, N., Griffiths, P. T., Harper, A. B., Hendry, M. A., Hewitt, A. J., Johnson, B., Jones, A., Jones, C. D., Keeble, J., Liddicoat, S., Morgenstern, O., Parker, R. J., Predoi, V., Robertson, E., Siahaan, A., Smith, R. S., Swaminathan, R., Woodhouse, M. T., Zeng, G., and Zerroukat, M.: UKESM1: Description and Evaluation of the U.K. Earth System Model, Journal of Advances in Modeling Earth Systems, 11, 4513–4558, https://doi.org/10.1029/2019MS001739, 2019.

Swart, N. C., Cole, J. N. S., Kharin, V. V., Lazare, M., Scinocca, J. F., Gillett, N. P., Anstey, J., Arora, V., Christian, J. R., Hanna, S., Jiao, Y., Lee, W. G., Majaess, F., Saenko, O. A., Seiler, C., Seinen, C., Shao, A., Sigmond, M., Solheim, L., von Salzen, K., Yang, D., and Winter, B.: The Canadian Earth System Model version 5 (CanESM5.0.3), Geoscientific Model Development, 12, 4823–4873, https://doi.org/10.5194/gmd-12-4823-2019, 2019.

Tatebe, H., Ogura, T., Nitta, T., Komuro, Y., Ogochi, K., Takemura, T., Sudo, K., Sekiguchi, M., Abe, M., Saito, F., Chikira, M., Watanabe, S., Mori, M., Hirota, N., Kawatani, Y., Mochizuki, T., Yoshimura, K., Takata, K., O’ishi, R., Yamazaki, D., Suzuki, T., Kurogi, M., Kataoka, T., Watanabe, M., and Kimoto, M.: Description and basic evaluation of simulated mean state, internal variability, and climate sensitivity in MIROC6, Geoscientific Model Development, 12, 2727–2765, https://doi.org/10.5194/gmd-12-2727-2019, 2019.

Voldoire, A., Saint-Martin, D., Sénési, S., Decharme, B., Alias, A., Chevallier, M., Colin, J., Guérémy, J.-F., Michou, M., Moine, M.-P., Nabat, P., Roehrig, R., Salas y Mélia, D., Séférian, R., Valcke, S., Beau, I., Belamari, S., Berthet, S., Cassou, C., Cattiaux, J., Deshayes, J., Douville, H., Ethé, C., Franchistéguy, L., Geoffroy, O., Lévy, C., Madec, G., Meurdesoif, Y., Msadek, R., Ribes, A., Sanchez-Gomez, E., Terray, L., and Waldman, R.: Evaluation of CMIP6 DECK Experiments With CNRM-CM6-1, Journal of Advances in Modeling Earth Systems, 11, 2177–2213, https://doi.org/10.1029/2019MS001683, 2019.

Volodin, E. and Gritsun, A.: Simulation of observed climate changes in 1850–2014 with climate model INM-CM5, Earth System Dynamics, 9, 1235–1242, https://doi.org/10.5194/esd-9-1235-2018, 2018.

Yukimoto, S., Kawai, H., Koshiro, T., Oshima, N., Yoshida, K., Urakawa, S., Tsujino, H., Deushi, M., Tanaka, T., Hosaka, M., Yabu, S., Yoshimura, H., Shindo, E., Mizuta, R., Obata, A., Adachi, Y., and Ishii, M.: The Meteorological Research Institute Earth System Model Version 2.0, MRI-ESM2.0: Description and Basic Evaluation of the Physical Component, Journal of the Meteorological Society of Japan. Ser. II, 97, 931–965, https://doi.org/10.2151/jmsj.2019-051, 2019.

Ziehn, T., Chamberlain, M. A., Law, R. M., Lenton, A., Bodman, R. W., Dix, M., Stevens, L., Wang, Y.-P., and Srbinovsky, J.: The Australian Earth System Model: ACCESS-ESM1.5, JSHESS, 70, 193–214, https://doi.org/10.1071/ES19035, 2020.

