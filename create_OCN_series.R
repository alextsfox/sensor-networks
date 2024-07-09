library(dplyr)

OCN_to_TIF <- function(OCN, filename, crs="EPSG:26916"){
  if()
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
#' @param frames integer vector. values of nIter at which to save the OCN state. Defaults to 25 frames between nIter=1 and nIter=40*dimX*dimY. Can also be an integer, indicating the number of frames to use.
#' @param seed integer. random seed
#' @param cores integer. number of cores to use in parallel processing
#' @param return_OCNs bool. Whether to return generated OCNs
#' @param out_dir string. Output directory for DEM rasters. If NULL (default), do not save rasters.
#' @param progress bool. If TRUE (default), print progress.
#' @param create_OCN_kwargs named list of additional arguments supplied to OCNet::create_OCN other than dimX, dimY, and nIter. Can be NULL.
#' @param landscape_OCN_kwargs named list of additional arguments supplied to OCNet::landscape_OCN.
#' @param aggregate_OCN_kwargs named list of additional arguments supplied to OCNet::aggregate_OCN.
create_OCN_series <- function(
  dimX, dimY, frames=NULL,
  seed=0,
  cores=1,
  return_OCNs=FALSE,
  out_dir=NULL,
  progress=TRUE,
  create_OCN_kwargs=list(displayUpdates=0),
  landscape_OCN_kwargs=NULL,
  aggregate_OCN_kwargs=NULL
){
  if(is.null(create_OCN_kwargs)) create_OCN_kwargs=list()
  if(is.null(landscape_OCN_kwargs)) landscape_OCN_kwargs=list()
  if(is.null(aggregate_OCN_kwargs)) aggregate_OCN_kwargs=list()

  if(!is.null(create_OCN_kwargs$dimX)) stop("dimX should be passed using the dimX argument, not using create_OCN_kwargs")
  if(!is.null(create_OCN_kwargs$dimY)) stop("dimY should be passed using the dimY argument, not using create_OCN_kwargs")
  if(!is.null(create_OCN_kwargs$nIter)) stop("nIter should be passed using the frames argument, not using create_OCN_kwargs")

  if(!is.null(out_dir)) if(!dir.exists(out_dir)) stop(paste("Provided output directory", out_dir, "does not exist."))

  if(is.null(frames)){
    frames <- as.integer(seq(1, 40*dimX*dimY, length.out=25))
    frames <- sort(frames[!duplicated(frames)])
  }else if(length(frames) == 1) {
    frames <- as.integer(seq(1, 40*dimX*dimY, length.out=frames))
    frames <- sort(frames[!duplicated(frames)])
  }

  fun <- function(nIter){
    set.seed(seed)
    OCN <- do.call(OCNet::create_OCN, c(dimX, dimY, list(nIter=nIter), create_OCN_kwargs)) 
    OCN <- do.call(OCNet::landscape_OCN, c(OCN, landscape_OCN_kwargs))
    OCN <- do.call(OCNet::aggregate_OCN, c(OCN, aggregate_OCN_kwargs))
    if(!is.null(out_dir)) OCN_to_TIF(OCN, paste(out_dir, paste0(nIter, ".tif"), sep="/"))
    if(progress) print(paste0("Completed Frame ", nIter , "/", frames[length(frames)]))
    if(return_OCNs) return(OCN)
    else return(NULL)
  }

  if(cores == 1) out <- lapply(X=frames, FUN=fun)
  else out <- parallel::mclapply(X=frames, FUN=fun, mc.cores=cores)

  return(unlist(out))
}