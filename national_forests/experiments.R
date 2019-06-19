library(rgdal)
library(rvest)
library(dplyr)
library(ggplot2)

# layers are:
# Administrative_Forest_Boundaries
# FSTopo_Quadrangle
# National_Forest_System_Trails
wm_trails <- readOGR("/Users/kholub/snippets/national_forests/white_mountains.gdb", "National_Forest_System_Trails")
summary(wm_trails)
plot(wm_trails)

wm_topo <- readOGR("/Users/kholub/snippets/national_forests/white_mountains.gdb", "FSTopo_Quadrangle")
plot(wm_topo)

bw_trails <- readOGR("/Users/kholub/snippets/national_forests/boundary_waters.gdb", "National_Forest_System_Trails")
plot(bw_trails)

w_trails <- readOGR("/Users/kholub/snippets/national_forests/williamette.gdb", "National_Forest_System_Trails")
plot(w_trails, axes=TRUE)
sort(as.character(w_trails$TRAIL_NAME))
south_sister_trail <- w_trails[w_trails$TRAIL_NAME == 'SOUTH SISTER CLIMBER',]
plot(south_sister_trail, axes=T)

######################
## push all of the white mountains trails into a simple, long dataframe format
## probably better to use the object & its API, but I'm obstinate, lazy, and the data is little - dataframe it is!
wm_trails_df <- lapply(1:length(wm_trails@lines), function(ix) {
  trail_coords <- wm_trails@lines[[ix]]@Lines[[1]]@coords
  trail_name <- wm_trails@data$TRAIL_NAME[ix]
  
  coords_df <- data.frame(lon = trail_coords[,1], lat = trail_coords[,2])
  coords_df$trail_name <- trail_name
  coords_df
}) %>% 
  bind_rows()
