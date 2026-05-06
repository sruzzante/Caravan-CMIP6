<img width="3050" height="1179" alt="logo3" src="https://github.com/user-attachments/assets/b96e9fa0-7866-4157-91c4-37faab45cd28" />

# Caravan-CMIP6
Caravan-CMIP6 is intended to make it easier for the large-sample hydrologic community to project streamflow under climate change. Many large-sample studies are built on large-sample hydrometeorological datasets (often called CAMELS) which provide streamflow measurements, historical meteorological data, and catchment attributes. With the addition of Caravan-CMIP6, these models can be used to project streamflow forward to the year 2100 under three emissions scenarios, or backward to 1850. We provide data from the same 12 CMIP6 models for each CAMELS dataset. We provide projections for all of the meteorological variables included in each CAMELS dataset, except for variables that cannot be calculated from CMIP6 data.

Climate model data is provided at coarse resolutions (50 km to 500 km), and is often biased with respect to the finer-resolution data used in the CAMELS datasets. Running a hydrologic model on the raw climate model data therefore produces erroneous results. We applied a bias-correction procedure (Quantile Delta Mapping) to match the distribution of climate model data to the distribution of historical observed data over a reference period (1981-2010). We expect hydrologic models to reproduce similar streamflow statistics whether run with historical observational meteorological data or the bias-corrected climate model data over the reference period. The bias correction algorithm preserves the changes in variables simulated by the climate models; either relative or absolute changes are preserved, depending on the variable.

The dataset provides CMIP6 climate model projections for catchments within ten large-sample hydrology datasets, including:
- 10 large-sample hydrology datasets: Caravan, CAMELS, CAMELS-AUS-v2, CAMELS-BR, CAMELS-CH CAMELS-CL, CAMELS-COL, CAMELS-DE, CAMELS-GB-v2, and CAMELS-IND
- 12 climate models
- both raw and bias-corrected data
- the historical experiment (1850-2014) and three scenarios (ssp 126, ssp 245, and ssp 585) from 2015-2100
- many meteorological variables, including precipitation, temperature, evapotranspiration, humidity, radiation, pressure, and wind speed.
