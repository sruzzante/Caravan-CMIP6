

datasets = read.csv("../low-flows-WNA/2.data/1.original/CMIP6_ESGF/Sensitivity/ModelSensitivity.csv")%>%
  filter(Model.Name %in% c(
    "ACCESS-ESM1-5",
    "CanESM5",
    "CNRM-CM6-1-HR",
    "EC-Earth3",
    "GFDL-CM4",
    "INM-CM5-0",
    "IPSL-CM6A-LR",
    "MIROC6",
    "MPI-ESM1-2-HR",
    "MRI-ESM2-0",
    "TaiESM1",
    "UKESM1-0-LL"
  ))

# ECS_dist<-read.csv("2.data/1.original/CMIP6_ESGF/Sensitivity/Sherwood_ecs_dist.csv")
# 
# ggplot(ECS_dist,aes(x = percentile,y = ECS))+geom_line()
#  plot(ECS_dist$percentile,ECS_dist$ECS)
#  
#  ggplot(ECS_dist,aes(x = percentile,y=ECS))+geom_point()+
#    geom_smooth()
# ECS_dist2<-data.frame(
#   percentile = seq(0,100,0.01),
#   ECS = spline(x = ECS_dist$percentile,y = ECS_dist$ECS,xout = seq(0,100,0.01),method = "hyman")$y
# )
# ggplot(ECS_dist2,aes(x = percentile,y=ECS))+geom_point()

x<-read.csv("../low-flows-WNA/2.data/1.original/CMIP6_ESGF/Sensitivity/ULI_MEDIUM_SAMPLE.csv",header = F)
df<-data.frame(x = x)
df$cumx<-cumsum(df$V1)
which(df$cumx>17.0000)[1]

which(df$cumx>83)[1]

df$ECS<- seq(-100,99.99,0.01)

ggplot(df,aes(x = ECS))+
  scale_x_continuous(limits = c(0,6))+
  geom_histogram(data = datasets,aes(x = ECS150))+
  geom_line(aes(y= V1*10))
# install.packages("fitdistrplus")

library(fitdistrplus)
ECS_fun =  approxfun(df$ECS,y = df$V1,method = "linear")

fitdistrplus::fitdist(data = df$ECS,method = "QME",distr = ECS_fun)

library(nlsr)

nlsr::nlsr(formula = V1~)


library(dplyr)
library(stats)

# repeat datasets 10 times

datasets= rbind(
  datasets,datasets,
  datasets,datasets,
  datasets
)

# df should have: ECS (model ECS values)
ecs_vals <- datasets$ECS150

# Theoretical quantile function for the assessed ECS distribution
# For example, Sherwood et al. (2020) fit a lognormal distribution
# Replace this with the correct quantile function, e.g. qlnorm, qgamma, etc.
q_assessed <-  approxfun(x = df$cumx/100,y = df$ECS,method = "linear")

# q_assessed <-  approxfun(y = df$cumx/100,x = df$ECS,method = "linear")

# Quantile levels
taus <- seq(0, 1, length.out = (nrow(datasets))+2)[2:(nrow(datasets)+1)]


softmax <- function(x) {
  z <- x - max(x)
  exp(z) / sum(exp(z))
}
# Define the cost function

cost_fun <- function(w, ecs_vals, taus, q_assessed, lambda = 1e-6) {
  if (any(!is.finite(w))) return(Inf)
  w <- softmax(w)
  q_weighted <- tryCatch(
    AkinshinWeightedQuantile(ecs_vals, w, taus),
    error = function(e) rep(NA, length(taus))
  )
  if (any(!is.finite(q_weighted))) return(Inf)
  q_target <- q_assessed(taus)
  mean((q_target - q_weighted)^2) + lambda * sum(w^2)
}

# Weighted quantile function (type 7, consistent estimator)
AkinshinWeightedQuantile <- function(x, w, probs) {
  ord <- order(x)
  x <- x[ord]; w <- w[ord]
  w <- w / sum(w)
  cum_w <- cumsum(w)
  sapply(probs, function(p) {
    approx(cum_w, x, xout = p, ties = "ordered",rule = 2)$y
  })
}

# Initial weights (equal)
set.seed(50)
model_weight<-list()
tictoc::tic()
Ndone = 0
# for(it in 1:50){
it=0
while(Ndone<50){
  
  it = it+1
  
  tictoc::tic(it)
  w0<-rnorm(length(ecs_vals), sd = 0.01, mean = 0) # in log-space before softmax
  # Minimize using quasi-Newton
  
  
  opt <-  
    tryCatch(
      optim(w0, 
            cost_fun,
            ecs_vals = ecs_vals+rnorm(length(ecs_vals),sd = 0.1)  ,
            taus = taus, 
            q_assessed = q_assessed,
            method = "BFGS", 
            control = list(maxit = 1000)),
      error = function(e){
        warning(e)
        NULL
      } 
    )
  
  if(!is.null(opt)){
    
    # Extract final normalized weights
    weights <- exp(opt$par) / sum(exp(opt$par))
    
    model_weight[[it]]<-datasets%>%
      dplyr::select(Model.Name,ECS150)%>%
      dplyr::mutate(wght = weights)
    
    print(opt$value)
    print(opt$convergence)
    
  }
  
  Ndone = 
    lapply(model_weight,function(x){!is.null(x)})%>%unlist()%>%sum()
  tictoc::toc()
}

model_weight_2<-bind_rows(model_weight)%>%
  group_by(Model.Name,ECS150)%>%
  mutate(wght = wght*5)%>%
  dplyr::summarize(
    wght.max = max(wght),
    wght.sd = sd(wght),
    wght = mean(wght))

saveRDS(model_weight_2,
        "2.data/2.working/CMIP6_ESGF/model_weights.RDS")

bind_rows(model_weight)%>%
  ggplot(aes(x= Model.Name,y = wght))+geom_boxplot()+scale_y_log10()
ggplot(model_weight_2,aes(x =ECS150,y = wght,ymin = wght-2*wght.sd,ymax = wght+2*wght.sd))+geom_point()+
  geom_errorbar()
ggplot() + 
  geom_histogram(data = model_weight_2, aes(x = ECS150, y = ..density.., weight = wght))+
  
  scale_x_continuous(limits = c(0,6))+
  geom_line(data = df,aes(x = ECS,y= V1))

xdf<-datasets2%>%arrange(ECS150)

xdf$wq<-cumsum(xdf$wght)-xdf$wght/2
xdf$theo_q<-ECS_assessed(xdf$ECS150)

ggplot(xdf,aes(x = theo_q,y = wq))+geom_line()+
  geom_abline()
