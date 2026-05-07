# utils
fctrs = c("vas" = 100,
          "uas" = 100,
          "hurs" = 100,
          "pr" = 86400*10,
          "tas" = 100,
          "tasmin" = 100,
          "tasmax" = 100,
          "rsds" = 10,
          "rsus" = 10,
          "rss" = 10,
          "rlds" = 10,
          "rlus" = 10,
          "rls" = 10,
          "snw" = 10, # might need to set to 1 for some datasets
          "psl" = 0.1,
          "ps" = 0.1,
          "huss" = 10^5,
          "sfcWind" = 100,
          "tasmaxD" = 100,
          "tasminD" = 100,
          "tasminDtasmax" = 100,
          'vp' = 1,
          "tdps" = 100,
          "petfao56" = 100,
          "petpriestly" = 100
          
          
          
)

offsets = c("vas" = 0,
            "uas" = 0,
            "hurs" = 0,
            "pr" = 0,
            "tas" = 273.15,
            "tasmin" = 273.15,
            "tasmax" = 273.15,
            "rsds" = 0,
            "rsus" = 0,
            "rss" = 0,
            "rlds" = 0,
            "rlus" = 0,
            "rls" = 0,
            "snw" = 0,
            "psl" = 100000,
            "ps" = 100000,
            "huss" = 0,
            "sfcWind" = 0,
            "tasmaxD" = 0,
            "tasminD" = 0,
            "tasminDtasmax" = 0,
            "vp" = 0,
            "tdps" = 273.15,
            "petfao56" = 0,
            "petpriestly" = 0
)





tdp_func = function(hur,ta){
  # from https://bmcnoldy.earth.miami.edu/Humidity.html
  B1 = 243.04
  A1 = 17.625
  hur = pmax(hur,0.01)
  taC = ta-273.15
  tdp = B1*(log(hur/100)+(A1*taC)/(B1+taC))/(A1-log(hur/100)-A1*taC/(B1+taC))+273.15
  
  
  return(tdp)
}


vp_func = function(hur,ta){
  # from https://doi.org/10.1175/1520-0450(1996)035%3C0601:IMFAOS%3E2.0.CO;2
  B1 = 243.04
  A1 = 17.625
  
  taC = ta-273.15
  Psat = 610.94*exp(A1*taC/(B1+taC))
  
  vp = Psat*hur/100
  
  return(vp)
}



ps_func = function(psl,ta,h){
  # eq [33a] from US standard atmosphere (1976): https://www.ngdc.noaa.gov/stp/space-weather/online-publications/miscellaneous/us-standard-atmosphere-1976/us-standard-atmosphere_st76-1562_noaa.pdf
  
  g = 9.80665 # m/s2
  M0 = 28.9644 #kg/kml
  L = -0.0065 #K/m
  R = 8.31432*10^3 #N·m/(kmol·K)
  
  
  tasl = ta - h*L
  ps = psl*(tasl / ta)^(g*M0/(R*L))
  
  
  
  return(ps)
}

pet_fao_func = function(p,ta,hur,sfcWind,rs,rl){
  
  # p: pressure in Pa
  # ta: 2m temperature in K
  # hur: relative humidity (%)
  # sfcWind: wind speed at 10 m, m/s
  # rs: net shortwave radiation, W/m2
  # rl: net longwave radiation, W/m2
  
  
  # code adapted from  https://github.com/Dagmawi-TA/hPET/blob/main/pet_calc_v3.3.py, which is the published code for 
  #Singer et al. (2021), see https://www.nature.com/articles/s41597-021-01003-9. 
  
  #This is the function that calculate the PET based on the PM method.
  
  
  # Constants.
  lmbda = 2.45  # Latent heat of vaporization [MJ kg -1] (simplification in the FAO PenMon (latent heat of about 20°C)
  cp = 1.013e-3 # Specific heat at constant pressure [MJ kg-1 °C-1]
  eps = 0.622   # Ratio molecular weight of water vapour/dry air
  
  # Soil heat flux density [MJ m-2 day-1] - set to 0 following eq 42 in FAO
  G = 0    
  
  # Atmospheric pressure [kPa] 
  P_kPa = p/1000  
  
  # ensure hur is <= 100; supersaturation is allowed in some climate models
  
  hur = pmin(hur,100)
  
  # 2m temperature in C
  temperature2m_C = ta-273.15 
  
  
  # Psychrometric constant (gamma symbol in FAO) eq 8 in FAO.
  psychometric_kPa_c = cp*P_kPa / (eps*lmbda)
  
  # Saturation vapour pressure, eq 11 in FAO.
  svp_kPa = 0.6108*exp((17.27*temperature2m_C) / (temperature2m_C+237.3))
  
  # Delta (slope of saturation vapour pressure curve) eq 13 in FAO.
  delta_kPa_C = 4098.0*svp_kPa / (temperature2m_C+237.3)^2
  
  # Actual vapour pressure is saturation vp times relative humidity
  avp_kPa = svp_kPa*hur/100
  
  # Saturation vapour pressure deficit.
  svpdeficit_kPa = svp_kPa - avp_kPa
  
  # convert 10 m to 2m wind speed
  windspeed2m_m_s = sfcWind* 4.87 / (log(67.8 * 10 - 5.42)) 
  
  # net radiation in MJ/m2
  net_radiation_MJ_m2  = (rs+rl)*86400/10^6
  
  # ensure net radiation is non-negative
  net_radiation_MJ_m2 = pmax(net_radiation_MJ_m2,0)
  
  
  
  
  numerator = 0.408*delta_kPa_C*(net_radiation_MJ_m2 - G) + 
    psychometric_kPa_c*(900/(temperature2m_C+273))*windspeed2m_m_s*svpdeficit_kPa
  denominator = delta_kPa_C + psychometric_kPa_c*(1 + 0.34*windspeed2m_m_s)
  
  ET0_mm_day = numerator / denominator
  
  
  # ensure positive ET; sometimes floating point error creates a negative number
  ET0_mm_day = pmax(ET0_mm_day,0)
  
  
  return(ET0_mm_day)
}


assignHalfMonth<-function(dts_tstamp){
  yr = substr(dts_tstamp,1,4)%>%as.numeric()
  mnth = substr(dts_tstamp,6,7)%>%as.numeric()
  dy = substr(dts_tstamp,9,10)%>%as.numeric()
  
  hm = (mnth-1)*2+as.numeric(dy>15)
  return(hm)
}



pet_hargreaves_func = function(ta,tamax,tamin,lat,dts,cal){
  # based on Hargreaves and Samani (1985)
  taC = ta-273.15
  TD = pmax(tamax-tamin,0)
  
  # calculate julian day differently based on calendar
  if(cal=="360_day"){
    mnths = substr(dts,6,7)%>%as.numeric()
    dys = substr(dts,9,10)%>%as.numeric()
    D = (mnths-1)*30+dys
    D = D*365/360
  }else{
    D = lubridate::yday(dts)
  }
  
  #   Program I in Hargreaves (1985) to calculate RA is a bit buggy - breaks near lat = +/-60
  #   Y = cos(0.0172142*(D+192))
  #   DEC = 0.40876*Y
  #   ES = 1.00028+0.03269*Y
  #   XLR= lat/57.2958
  #   Z = - tan(XLR)*tan(DEC)
  #   OM = -atan(Z/sqrt(-Z*Z+1))+pi/2
  #   DL = OM/0.1309
  #   RAL = 120*(DL*sin(XLR)*sin(DEC)+7.639*cos(XLR)*cos(DEC)*sin(OM))/ES
  #   RA = RAL * 10/(595.9-0.55*taC)
  
  # from FAO56
  Gsc = 0.082 #MJ m-2 min-2
  phi = lat*pi/180
  d_r = 1+0.033*cos(2*pi/365*D)
  delta = 0.409*sin(2*pi/365*D-1.39)
  omega_s =acos(pmax(pmin(-tan(phi)*tan(delta),1),-1))
  RA =  0.408*24*60/pi*Gsc*d_r * (omega_s*sin(phi)*sin(delta)+cos(phi)*cos(delta)*sin(omega_s)) # extraterrestrial rad in mm/day
  
  ETP = 0.0023*RA*TD^0.5*(taC+17.8)
  
  ETP = pmax(ETP,0)
  return(ETP)
}



pet_priestly_func = function(p,ta,rs,rl){
  
   # From Miralles et al. (2011) https://doi.org/10.5194/hess-15-453-2011
  # p: pressure in Pa
  # ta: 2m temperature in K
  # rs: net shortwave radiation, W/m2
  # rl: net longwave radiation, W/m2
  
  # Constants.
  lmbda = 2.45  # Latent heat of vaporization [MJ kg -1] (simplification in the FAO PenMon (latent heat of about 20°C)
  cp = 1.013e-3 # Specific heat at constant pressure [MJ kg-1 °C-1]
  eps = 0.622   # Ratio molecular weight of water vapour/dry air
  alpha = 1 # set to 1, bias-correction will take care of scaling
  
  # Atmospheric pressure [kPa] 
  P_kPa = p/1000  
  
  
  
  # 2m temperature in C
  temperature2m_C = ta-273.15 
  
  
  # Psychrometric constant (gamma symbol in FAO) eq 8 in FAO.
  psychometric_kPa_c = cp*P_kPa / (eps*lmbda)
  
  # Saturation vapour pressure, eq 11 in FAO.
  svp_kPa = 0.6108*exp((17.27*temperature2m_C) / (temperature2m_C+237.3))
  
  # Delta (slope of saturation vapour pressure curve) eq 13 in FAO.
  delta_kPa_C = 4098.0*svp_kPa / (temperature2m_C+237.3)^2
  
  # net radiation in MJ/m2
  net_radiation_MJ_m2  = (rs+rl)*86400/10^6
  
  # ensure net radiation is non-negative
  net_radiation_MJ_m2 = pmax(net_radiation_MJ_m2,0)
  
  
  
  ETP = alpha*delta_kPa_C/(delta_kPa_C+psychometric_kPa_c)*(net_radiation_MJ_m2)/lmbda
 
  
  ETP = pmax(ETP,0)
  return(ETP)
}
