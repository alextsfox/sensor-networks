library(OCNet)
library(tidyverse)

source(paste(getwd(), "create_OCN_series.R", sep="/"))

dimX <- 10
dimY <- 10
frames <- as.integer(seq(1, dimX*dimY*40, length.out=100))
frames <- sort(frames[!duplicated(frames)])
out_dir <- paste0(getwd(), "/test")
res <- create_OCN_series(
  dimX, 
  dimY, 
  100, 
  cores=parallel::detectCores(), 
  return_OCNs=FALSE, 
  out_dir=NULL,
  progress=TRUE
)
