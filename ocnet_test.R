library(OCNet)
library(tidyverse)
library(ggplot2)

source(paste(getwd(), "create_OCN_series.R", sep="/"))

dimX <- 500
dimY <- 500
cellsize <- 100
frames <- as.integer(seq(1, dimX*dimY*40, length.out=16))

frames <- sort(frames[!duplicated(frames)])



hot_kwargs <- list(
  outletSide="S",
  outletPos=dimX,
  cellsize=cellsize,
  initialNoCoolingPhase=OCN_250_hot$initialNoCoolingPhase,
  coolingRate=OCN_250_hot$coolingRate,
  typeInitialState="V",
  saveEnergy=TRUE
)

cold_kwargs <- list(
  outletSide="S",
  outletPos=dimX,
  cellsize=cellsize,
  initialNoCoolingPhase=OCN_250_cold$initialNoCoolingPhase,
  coolingRate=OCN_250_cold$coolingRate,
  typeInitialState="V",
  saveEnergy=TRUE
)

lw_kwargs <- list(
  outletSide="S",
  outletPos=dimX,
  cellsize=cellsize,
  initialNoCoolingPhase=OCN_250$initialNoCoolingPhase,
  coolingRate=OCN_250$coolingRate,
  typeInitialState="V",
  saveEnergy=TRUE
)

cold <- create_OCN_series(
  dimX, 
  dimY, 
  frames, 
  cores=8, 
  return_OCNs="last", 
  out_dir=paste0(getwd(), "/dems/500/cold"),
  # progress=TRUE,
  create_OCN_kwargs=cold_kwargs,
)

hot <- create_OCN_series(
  dimX, 
  dimY, 
  frames, 
  cores=8, 
  return_OCNs="last", 
  out_dir=paste0(getwd(), "/dems/500/hot"),
  # progress=TRUE,
  create_OCN_kwargs=hot_kwargs
)

lw <- create_OCN_series(
  dimX, 
  dimY, 
  frames, 
  cores=8, 
  return_OCNs="last", 
  out_dir=paste0(getwd(), "/dems/500/lw"),
  # progress=TRUE,
  create_OCN_kwargs=lw_kwargs
)


frame_energy <- data.frame(iter=frames, cold=cold$energy[frames], lw=lw$energy[frames], hot=hot$energy[frames])
write_csv(frame_energy, paste0(getwd(), "/dems/500/frame_energy.csv"))

energy <- data.frame(iter=1:frames[length(frames)], cold=cold$energy, lw=lw$energy, hot=hot$energy)
write_csv(energy, paste0(getwd(), "/dems/500/energy.csv"))

ggplot(energy[1:frames[length(frames)]:100]) +
  geom_line(aes(x=iter, y=cold), color="blue") +
  geom_line(aes(x=iter, y=lw), color="orange") +
  geom_line(aes(x=iter, y=hot), color="red")