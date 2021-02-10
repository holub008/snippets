library(rgdal)
library(raster)
library(dplyr)
library(tidyr)
library(ggplot2)
library(rgeos)

#the sisters
extent <- list(xmin=-121.85,
               xmax=-121.72,
               ymin=44.05,
               ymax=44.19)
# sourced from from http://viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
hgt_path <- '/Users/kholub/snippets/national_forests/contours/N44W122.hgt'

sis_elevation_raster <- raster(hgt_path) %>%
  crop(unlist(extent))
sis_contours <- rasterToContour(sis_elevation_raster, nlevels=65)

plot(sis_contours[as.integer(as.character(sis_contours$level)) > 1500,])
plot(sis_contours[as.integer(as.character(sis_contours$level)) == 2520,])


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




extent <- list(xmin=-107.14,
               xmax=-107.07,
               ymin=44.258,
               ymax=44.29)
hgt_path <- '/Users/kholub/Downloads/L13/N44W108.hgt'

darton_elevation_raster <- raster(hgt_path) %>%
  crop(unlist(extent))
darton_contours <- rasterToContour(darton_elevation_raster, nlevels=100)
plot(darton_contours[as.integer(as.character(darton_contours$level)) > 3200,])

darton_raster_df <- darton_elevation_raster %>% 
  as.data.frame(xy=TRUE) %>%
  rename(elevation = N44W108) %>%
  filter(elevation > 3200)

ggplot(darton_raster_df) +
  geom_point(aes(x,y, color=elevation))

