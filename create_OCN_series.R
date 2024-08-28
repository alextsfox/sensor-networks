library(dplyr)

#' Write an OCN object to a TIF representing a DEM.
#' 
#' @param OCN the OCN object
#' @param filename the file path to save to
#' @param crs a CRS accepted by raster::rasterFromXYZ
OCN_to_TIF <- function(OCN, filename, crs="EPSG:26916"){
  dem <- raster::rasterFromXYZ(
    xyz=cbind(OCN$FD$X, OCN$FD$Y, OCN$FD$Z),
    res=c(OCN$cellsize, OCN$cellsize),
    crs=crs  # choose this one because it puts our dems in the galapagos by pure coincidence, which is sort of neat.
  ) %>% 
    raster::writeRaster(filename, overwrite=TRUE)
}

#' Create an OCN, saving any requested intermediate steps
#' 
#' @param dimX integer. Longitudinal dimension of the lattice (in number of pixels).
#' @param dimY integer. Latitudinal dimension of the lattice (in number of pixels).
#' @param nIter integer. Number of iterations to run for. Defaults to 40*dimX*dimY
#' @param frames integer vector or integer. If integer, OCN is saved 25 times between iteration 1 and iteration nIter. If integer vector, OCN is saved as specified iterations.
#' @param seed integer. random seed
#' @param cores integer. number of cores to use in parallel processing. Set to 1 for no parallel processing.
#' @param return_OCNs string, one of "none", "all", or "last". If "last" (default), return the only the final OCN. If "none", return NULL. If "all", return a list of OCN objects for each frame.
#' @param out_dir string. Output directory for DEM rasters. If NULL (default), do not save rasters.
#' @param create_OCN_kwargs named list of additional arguments supplied to OCNet::create_OCN other than dimX, dimY, and nIter. Can be NULL.
#' @param landscape_OCN_kwargs named list of additional arguments supplied to OCNet::landscape_OCN.
#' @param aggregate_OCN_kwargs named list of additional arguments supplied to OCNet::aggregate_OCN.
create_OCN_series <- function(
  dimX, 
  dimY, 
  nIter=40*dimX*dimY, 
  frames=25,
  seed=0,
  cores=1,
  return_OCNs="last",
  out_dir=NULL,
  create_OCN_kwargs=list(displayUpdates=0),
  landscape_OCN_kwargs=NULL,
  aggregate_OCN_kwargs=NULL
){
  if(is.null(create_OCN_kwargs)) create_OCN_kwargs=list()
  if(is.null(landscape_OCN_kwargs)) landscape_OCN_kwargs=list()
  if(is.null(aggregate_OCN_kwargs)) aggregate_OCN_kwargs=list()

  if(!is.null(create_OCN_kwargs$dimX)) stop("dimX should be passed using the dimX argument, not using create_OCN_kwargs")
  if(!is.null(create_OCN_kwargs$dimY)) stop("dimY should be passed using the dimY argument, not using create_OCN_kwargs")
  if(!is.null(create_OCN_kwargs$nIter)) stop("nIter should be passed using the nIter argument, not using create_OCN_kwargs")

  if(!is.null(out_dir)) if(!dir.exists(out_dir)) stop(paste("Provided output directory", out_dir, "does not exist."))

  if(length(frames) == 1) {
    frames <- as.integer(seq(1, nIter, length.out=frames))
  }
  frames <- sort(frames[!duplicated(frames)])

  if(frames[length(frames)] > nIter) stop(paste("You have requested a frame to be at an iteration beyond nIter. If frames is provided as an integer vector, please ensure that max(frames) <= nIter. I was provided frames=", frames, " and nIter=", nIter, sep=""))

  fun <- function(nIter){
    set.seed(seed)
    OCN <- do.call(OCNet::create_OCN, c(dimX, dimY, list(nIter=nIter), create_OCN_kwargs)) 
    OCN <- do.call(OCNet::landscape_OCN, c(OCN, landscape_OCN_kwargs))
    OCN <- do.call(OCNet::aggregate_OCN, c(OCN, aggregate_OCN_kwargs))
    
    if(!is.null(out_dir)) OCN_to_TIF(OCN, paste(out_dir, paste0(nIter, ".tif"), sep="/"))
    
    if(return_OCNs == "all") return(OCN)
    if(return_OCNs == "last" && nIter == frames[length(frames)]) return(OCN)
    return(NULL)
  }

  if(cores == 1) out <- lapply(X=frames, FUN=fun)
  else out <- parallel::mclapply(X=frames, FUN=fun, mc.cores=cores)

  if(return_OCNs == "last"){
    return(out[[length(out)]])
  }
  return(unlist(out))
}

#' Convert an OCN object to a dataframe
#' 
#' @param OCN an OCN object.
network_to_df <- function(OCN){
  return(data_frame(
    X=OCN$FD$X,
    Y=OCN$FD$Y,
    Z=OCN$FD$Z,
    A=OCN$FD$A,
    slope=OCN$FD$slope,
    toCM=OCN$FD$toCM,
    toRN=OCN$FD$toRN,
    leng=OCN$FD$leng,
    DownNode=OCN$FD$DownNode,
    Node=OCN$FD$Node	
  ))
}