library(OCNet)
library(tidyverse)

source(paste(getwd(), "create_OCN_series.R", sep="/"))

dimX <- 250
dimY <- 250
frames <- as.integer(seq(1, dimX*dimY*40, length.out=10))

frames <- sort(frames[!duplicated(frames)])



hot_kwargs <- list(
  outletSide="S",
  outletPos=dimX,
  cellsize=100,
  initialNoCoolingPhase=OCN_250_hot$initialNoCoolingPhase,
  coolingRate=OCN_250_hot$coolingRate,
  typeInitialState="V",
  saveEnergy=TRUE
)

cold_kwargs <- list(
  outletSide="S",
  outletPos=dimX,
  cellsize=100,
  initialNoCoolingPhase=OCN_250_cold$initialNoCoolingPhase,
  coolingRate=OCN_250_cold$coolingRate,
  typeInitialState="V",
  saveEnergy=TRUE
)

lw_kwargs <- list(
  outletSide="S",
  outletPos=dimX,
  cellsize=100,
  initialNoCoolingPhase=OCN_250$initialNoCoolingPhase,
  coolingRate=OCN_250$coolingRate,
  typeInitialState="V",
  saveEnergy=TRUE
)

cold <- create_OCN_series(
  dimX, 
  dimY, 
  frames, 
  cores=parallel::detectCores(), 
  return_OCNs=TRUE, 
  out_dir=paste0(getwd(), "/dems/cold"),
  progress=TRUE,
  create_OCN_kwargs=cold_kwargs,
)

lw <- create_OCN_series(
  dimX, 
  dimY, 
  frames, 
  cores=parallel::detectCores(), 
  return_OCNs=TRUE, 
  out_dir=paste0(getwd(), "/dems/lw"),
  progress=TRUE,
  create_OCN_kwargs=lw_kwargs
)

hot <- create_OCN_series(
  dimX, 
  dimY, 
  frames, 
  cores=parallel::detectCores(), 
  return_OCNs=TRUE, 
  out_dir=paste0(getwd(), "/dems/hot"),
  progress=TRUE,
  create_OCN_kwargs=hot_kwargs
)

# OCN <- create_OCN(
#   dimX, dimY,
#   outletSide="S",
#   outletPos=dimX,
#   cellsize=100,
#   initialNoCoolingPhase=OCN_250_hot$initialNoCoolingPhase,
#   coolingRate=OCN_250_hot$coolingRate,
#   typeInitialState="V",
#   saveEnergy=TRUE
# ) %>% 
#   landscape_OCN() %>% 
#   aggregate_OCN() 
# draw_simple_OCN(OCN)

# plot(log(OCN$energy))

# 500x500, 100m resolution
# 10 DEMs for each hot, lukewarm, cold
# dems, energy profile



# hot


