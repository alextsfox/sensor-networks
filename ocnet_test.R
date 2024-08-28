library(OCNet)
library(tidyverse)
library(ggplot2)

source(paste(getwd(), "create_OCN_series.R", sep="/"))

dimX <- 10
dimY <- 10
cellsize <- 100
frames <- as.integer(seq(1, dimX*dimY*40, length.out=16))

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

hot <- create_OCN_series(
  dimX, 
  dimY, 
  frames=frames, 
  cores=8, 
  return_OCNs="last", 
  out_dir=file.path(getwd(), "dems", dimX, "hot"),
  create_OCN_kwargs=hot_kwargs
)

cold <- create_OCN_series(
  dimX, 
  dimY, 
  frames=frames, 
  cores=8, 
  return_OCNs="last", 
  out_dir=file.path(getwd(), "dems", dimX, "cold"),
  create_OCN_kwargs=cold_kwargs,
)


lw <- create_OCN_series(
  dimX, 
  dimY, 
  frames=frames, 
  cores=8, 
  return_OCNs="last", 
  out_dir=file.path(getwd(), "dems", dimX, "lw"),
  create_OCN_kwargs=lw_kwargs
)

# save frame energy
frame_energy <- data.frame(iter=frames, cold=cold$energy[frames], lw=lw$energy[frames], hot=hot$energy[frames])
write_csv(frame_energy, file.path(getwd(), "dems", dimX, "frame_energy.csv"))

# save the full energy series (HUGE)
energy <- data.frame(iter=1:frames[length(frames)], cold=cold$energy, lw=lw$energy, hot=hot$energy)
write_csv(energy, file.path(getwd(), "dems", dimX, "energy.csv"))

# plot the energy timeseries series
ggplot(energy[seq(1, nrow(energy), nrow(energy)%/%1000), ]) +
  geom_line(aes(x=iter, y=cold), color="blue") +
  geom_line(aes(x=iter, y=lw), color="orange") +
  geom_line(aes(x=iter, y=hot), color="red")
