library(rgdal)
library(raster)
library(dplyr)
library(tidyr)
library(ggplot2)
library(rgeos)

#the sisters
extent <- list(xmin=-121.85,
               xmax=-121.65,
               ymin=44.05,
               ymax=44.19)
# sourced from from http://viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
hgt_path <- '/Users/kholub/snippets/national_forests/contours/N44W122.hgt'

sis_elevation_raster <- raster(hgt_path) %>%
  crop(unlist(extent))
sis_contours <- rasterToContour(sis_elevation_raster, nlevels=65)

plot(sis_contours[as.integer(as.character(sis_contours$level)) > 2300,])



## truuli
extent <- list(xmin=-150.48,
               xmax=-150.31,
               ymin=59.888,
               ymax=59.93)
# sourced from from http://viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
hgt_path <- '/Users/kholub/snippets/national_forests/contours/N59W151.hgt'

tru_elevation_raster <- raster(hgt_path) %>%
  crop(unlist(extent))
tru_contours <- rasterToContour(tru_elevation_raster, nlevels=70)

plot(tru_contours[as.integer(as.character(tru_contours$level)) > 1500,])
