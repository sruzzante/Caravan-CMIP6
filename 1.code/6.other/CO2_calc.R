library(dplyr)
library(tidyr)
usage = data.frame(
  name = c("fir","narval","nibi","rorqual"),
  cpu.days =  c(1459,445,275,183),
  cpue.days = c(123140,25591,38136,29580),
  mem = NA
)

# https://dais.ca/wp-content/uploads/2024/03/Can-Canada-Compute.pdf
# https://uwaterloo.ca/computer-science/news/canadas-most-powerful-academic-supercomputer-launched
resources = data.frame(name = c("fir","narval","nibi","rorqual"),
                       cpu.total = c(872*192+160*48,
                               (1145+33+3)*64+159*48,
                               700*192+1920+36*112+6*96,
                               (670+16)*192+81*64),
                       cpu_old.total = c(67584,76320,33000,72480),
                       power_kW_old = c(792,311,650,240),
                       carbon_intensity = c(18,1.9, 59,1.9)
                       
                       
)%>%
  mutate(power_KW_per_cpu = power_kW_old/cpu_old.total,
  )



df = left_join(usage,resources,by = "name")

df = df%>%mutate(
  total_energy_kWh = power_KW_per_cpu*cpue.days*24,
  total_CO2_kg = total_energy_kWh*carbon_intensity/1000
)

sum(df$total_CO2_kg)


# JFK-LHR: 415 kg
# LHR-JFK 317 kg

x = (317 +415)/2

sum(df$total_CO2_kg)/x


