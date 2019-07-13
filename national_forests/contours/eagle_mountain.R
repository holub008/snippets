library(rgdal)
library(raster)
library(dplyr)

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
em_trails <- readOGR(osm_path , 'lines')
em_elevation_disk <- raster(hgt_path)
em_elevation <- as.data.frame(em_elevation_disk, xy=TRUE) %>%
  filter(x >= extent$xmin & x <= extent$xmax
         & y >= extent$ymin & y <= extent$ymax) %>%
  mutate(
    elevation_meters = N47W091
  ) %>%
  dplyr::select(-N47W091)

hist(em_elevation$elevation_meters)



