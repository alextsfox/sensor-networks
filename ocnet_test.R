library(OCNet)

# Set the random seed to 1 and create an OCN in a 30x20 lattice with default options:
set.seed(1)
OCN <- create_OCN(30,20)
draw_simple_OCN(OCN)

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

