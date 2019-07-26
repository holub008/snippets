library(rgdal)
library(raster)
library(dplyr)
library(tidyr)
library(ggplot2)
library(rgeos)

preliminary_work <- function() {
  # osm data include trails and lakes
  # it is sourced by exporting a tile from the ui on openstreetmap.org
  osm_path <- '/Users/kholub/Downloads/map.osm'
  ogrListLayers(osm_path)
  lakes <- readOGR(osm_path, 'multipolygons')
  lines <- readOGR(osm_path, 'lines')
  contours <- readOGR(osm_path, 'multilinestrings')
  
  plot(lakes)
  
  #shp data for contours
  # i downloaded from https://opendem.info/opendem_client.html
  shp_path <- '/Users/kholub/Downloads/N47W092/N47W092.shp'
  ogrListLayers(shp_path)
  temp <- readOGR(shp_path, 'N47W092')
  plot(temp, xlim=c(-90.5796, -90.5385), ylim=c(47.8873, 47.9116))
  # doesn't work
  # either I suck, or these libraries are really hard to work with
  #anyways, the resolution sucks. can't use this 
  high <- temp[temp$elevation>650,]
  plot(high)
  # contours lack precision
  
  # hgt data from http://viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
  hgt_path <- '/Users/kholub/Downloads/L15/N47W091.hgt'
  elevation <- raster(hgt_path) 
  image(elevation, xlim=c(-90.5796, -90.5385), ylim=c(47.8873, 47.9116))
  
  temp <- sampleRegular(elevation, 1e4, xy=TRUE)
  hist(temp[,3], breaks = 50)
  # cool! contrary to the appearance of the raster image, we have granular elevation data (accurate to 1 meter)
  
  # only 1.5 m points, so just read it all off of disk
  all_points <- as.data.frame(elevation, xy=TRUE)
}

##############################################
# actual project work
##############################################
extent <- list(xmin=-90.6043,
               xmax=-90.5383,
               ymin=47.8871,
               ymax=47.9180)
# sourced from openstreetmap.org export UI
osm_path <- '/Users/kholub/snippets/national_forests/contours/eagle_mountain_tile.osm'
# sourced from from http://viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
hgt_path <- '/Users/kholub/snippets/national_forests/contours/N47W091.hgt'

em_lakes <- readOGR(osm_path, 'multipolygons')
em_lines <- readOGR(osm_path , 'lines')
em_trail <- em_lines[em_lines$name %in% c("Eagle Mountain Hiking Trail"), ] 
em_elevation_raster <- raster(hgt_path) %>%
  crop(unlist(extent))
em_contours <- rasterToContour(em_elevation_raster, nlevels=15)

# making sure the data looks healthy
plot(em_contours)
plot(em_trail, add=TRUE, col='green')
plot(em_lakes, add=TRUE, col='blue')

plot_level <- function(elevation, contours, lakes, trail, plot_extent = extent, min_elevation='560') {
  relevant_contours <- contours[contours$level == elevation,]
  
  plot(relevant_contours,
       xlim=c(plot_extent$xmin, plot_extent$xmax),
       ylim=c(plot_extent$ymin, plot_extent$ymax),
       axes=TRUE,
       lwd=5,
       main=elevation)
  
  # TODO this is not geopgrahically accurate, since some lakes are at elevation
  # could derive the heights and include in contours... but there are clearly
  # some accuracy errors in contour line placement and lake position. so
  # probably best to artistically eyeball
  if (elevation == min_elevation) {
    plot(lakes, col = 'blue',
         xlim=c(plot_extent$xmin, plot_extent$xmax),
         ylim=c(plot_extent$ymin, plot_extent$ymax),
         add=TRUE)
    plot(trail,
         col = 'green',
         xlim=c(plot_extent$xmin, plot_extent$xmax),
         ylim=c(plot_extent$ymin, plot_extent$ymax),
         add=TRUE)
  }
  
  trail_intersections <- gIntersection(trail, relevant_contours)
  
  if (!is.null(trail_intersections)) {
    plot(trail_intersections, 
         col='red',
         lwd=5,
         add=TRUE)
  }
  
  axis(side = 1, lwd = 5)
  axis(side = 2, lwd = 5)
  box(lwd=5)
}

for (ele in levels(em_contours$level)) {
  jpeg(paste0("~/eagle_mountain_layers/", ele, ".jpg"), width=1500, height=1500)
  plot_level(ele, em_contours, em_lakes, em_trail)
  dev.off()
}
