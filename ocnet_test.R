library(OCNet)

# periodic boundary
data(OCN_250_PB)
draw_simple_OCN(OCN_250_PB)

# v-shaped initial condition
data(OCN_250_V)
draw_simple_OCN(OCN_250_V)

river_250_V <- landscape_OCN(OCN_250_V)
draw_elev2D_OCN(river_250_V)

catchments_250_V <- aggregate_OCN(river_250_V)
draw_subcatchments_OCN(catchments_250_V)

# multi-outlet, periodic boundary, hot
data(OCN_300_4out_PB_hot)
draw_simple_OCN(OCN_300_4out_PB_hot)

# all parametric pixels are outlets
data(OCN_400_Allout)
draw_simple_OCN(OCN_400_Allout)

# messing around
set.seed(1)
OCN <- create_OCN(
    dimX=100, dimY=100,
    nOutlet=6, 
    outletSide=c(rep("S", 5), "E"),
    outletPos=c(as.integer(seq(1, 50, length.out=5)), 25),
    typeInitialState="I", #T, V, H
    nIter=40*100*100,
    showIntermediatePlots=TRUE, nUpdates=20, easyDraw=TRUE,
    displayUpdates=2,
    # how long to keep the river network "hot"/plastic for
    initialNoCoolingPhase=0.5, 
    # how quickly to cool down/freeze the network once cooling starts.
    coolingRate=10^5,
)

draw_simple_OCN(OCN)

river <- landscape_OCN(OCN)
draw_elev2D_OCN(river)

catchments <- aggregate_OCN(river)
draw_subcatchments_OCN(catchments)
