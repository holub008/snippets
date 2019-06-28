library(rgdal)
library(sp)
library(rvest)
library(dplyr)
library(ggplot2)
library(stringr)
library(pracma)

# layers are:
# Administrative_Forest_Boundaries
# FSTopo_Quadrangle
# National_Forest_System_Trails
wm_trails <- readOGR("~/snippets/national_forests/white_mountains.gdb", "National_Forest_System_Trails")
summary(wm_trails)
plot(wm_trails)

wm_topo <- readOGR("~/snippets/national_forests/white_mountains.gdb", "FSTopo_Quadrangle")
plot(wm_topo)

bw_trails <- readOGR("~/snippets/national_forests/boundary_waters.gdb", "National_Forest_System_Trails")
plot(bw_trails)

w_trails <- readOGR("~/snippets/national_forests/williamette.gdb", "National_Forest_System_Trails")
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
  bind_rows() %>%
  mutate(
    imputed=FALSE
  )

#######################
## get coordinates of white mountain 4000 footers
parse_dms <- function(coordinates) {
  matches <- str_match(coordinates, 'Coordinates: ([0-9]+)°([0-9]+)\' ?([0-9\\.]+)\" North\\s+([0-9]+)°([0-9]+)\' ?([0-9\\.]+)\" W')
  if (is.na(matches[1])) {
    matches <- str_match(coordinates, 'Coordinates: ([0-9]+)°([0-9\\.]+)(\'|′) ?North\\s+([0-9]+)°([0-9\\.]+)(\'|′) ?W')
    
    if (is.na(matches[1])) {
      # pretty sure this one is just a labelling bug
      matches <- str_match(coordinates, 'Coordinates: ([0-9]+)°([0-9]+)\' ?([0-9\\.]+)\" North\\s+([0-9]+)°([0-9\\.]+)\" W')
      
      coord_parts <- matches[2:7] %>% as.numeric()
      lat <- coord_parts[1] + coord_parts[2] / 60  + coord_parts[3] / 3600
      lon <- -1 * (coord_parts[4] + coord_parts[5] / 60)
      return(list(lat=lat, lon=lon))
    }
    
    coord_parts <- matches[c(2,3,5,6)] %>% as.numeric()
    lat <- coord_parts[1] + coord_parts[2] / 60 
    lon <- -1 * (coord_parts[3] + coord_parts[4] / 60)
    return(list(lat=lat, lon=lon))
  }
  
  coord_parts <- matches[2:ncol(matches)] %>% as.numeric()
  lat <- coord_parts[1] + coord_parts[2] / 60 + coord_parts[3] / 3600
  lon <- -1 * (coord_parts[4] + coord_parts[5] / 60 + coord_parts[6] / 3600)
  
  list(lat=lat, lon=lon)
}

get_wm_peaks <- function(base_url="http://4000footers.com/") {
  list_page <- read_html(paste0(base_url, 'nh.shtml'))
  page_tables <- list_page %>% 
    html_nodes("table table")
  matching_table_mask <- sapply(page_tables, function(table){
    table_description <- table %>%
      html_node("tr td span") %>%
      html_text()
    return(!is.na(table_description) && table_description == 'New Hampshire  4,000 Footers ↓')
  })
  peak_table <- page_tables[matching_table_mask]
  
  peak_anchors <- peak_table %>%
    html_nodes('tr td a')
   
  peak_names <- peak_anchors %>%
    html_text()
  
  peaks <- peak_anchors %>%
    html_attrs() %>% 
    sapply(function(attrs){attrs[['href']]}) %>%
    lapply(function(link){
      peak_page <- read_html(paste0(base_url, link))
      Sys.sleep(.1)
      candidate_spans <- peak_page %>%
        html_nodes('table tr td span')
      span_mask <- sapply(candidate_spans, function(span) {
        label <- span %>%
          html_node('strong')
        
        return (!is.na(label) && label %>% html_text() %>% startsWith('Coordinates:'))
      })
      coord_span <- candidate_spans[span_mask]
      coordinates <- coord_span %>% 
        html_text() %>%
        parse_dms()
    }) %>%
    bind_rows()
  
  peaks$name <- peak_names
  
  # fixing an apparent error on their site
  peaks <- peaks %>%
    mutate(
      lat = ifelse(name == 'Carter Dome', 44 + 16 / 60 + 1 / 3600, lat)
    )
  
  peaks
}

#wm_peaks <- get_wm_peaks()
#write.table(wm_peaks, '~/snippets/national_forests/wm_peaks.csv', sep=',', col.names = TRUE, row.names = FALSE)
wm_peaks <- read.csv('~/snippets/national_forests/wm_peaks.csv')

ggplot(wm_peaks) + 
  geom_point(aes(lon, lat), data=wm_trails_df, size=.2, color='grey', alpha=.2) +
  geom_point(aes(lon, lat), colour='red', shape=24, size=2) +
  #geom_text(aes(lon, lat, label=name)) +
  theme(plot.title = element_text(size=30),
        axis.text=element_text(size=20),
        axis.title=element_text(size=20),
        axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),plot.background=element_blank())

# TODO:
# - fill in necessary, missing data (e.g. the owl's head spur and paths to cabot)
# - impute trail segments that aren't labelled as touching 
#   - e.g. every trail terminus is connected to the nearest other trail, if present within x miles
# - associate peaks with on-trail coordindates
# - infer trail intersection points
# - build a graph where nodes are peaks and intersections, and edges are paths with weight equal to distance (or a mixture of distance and elevation)
# - run travelling salesman on the peaks

impute_line <- function(lat1, lon1, lat2, lon2, points=500) {
  data.frame(
    lat = seq(lat1, lat2, length.out = points),
    lon = seq(lon1, lon2, length.out = points)
  )
}

haversine_distance <- function(lat1, lon1, lat2, lon2) {
  haversine(c(lat1, lon1), c(lat2, lon2))
}

#########################
# fill in missing trails
#########################
# first, add a spur (exists in reality) for Owl's Head
oh_coords <- wm_peaks %>% filter(name == "Owl's Head")
oh_closest_point <- (wm_trails_df %>%
  mutate(
    distance = sapply(1:nrow(.), function(ix){ haversine_distance(oh_coords$lat, oh_coords$lon, lat[ix], lon[ix])})
  ) %>%
  arrange(distance) %>%
  select(-distance))[1,]
# of course OWLS HEAD PATH is not perfectly straight in reality
oh_path <- impute_line(oh_closest_point$lat, oh_closest_point$lon,
                       oh_coords$lat, oh_coords$lon) %>%
  mutate(
    trail_name='OWLS HEAD PATH',
    imputed=TRUE
  )
wm_trails_df <- wm_trails_df %>%
  rbind(oh_path, stringsAsFactors=FALSE)

# now we join the northern system to the southern system
# in reality, it looks like there is no trail directly joining the two - there is a east-west highway (2) cutting them off
# it looks like there are a couple possible routes between, the simplest of which is using the highway itself
# it is unfortunate because this will certainly influence the direttissima, since we are constraining where the two join up.
# in reality, there are more possible routes using other roads or bushwacking
# but, here we'll join Castle Trail and Starr King, which is possible using the "Presidential Highway"
# https://www.alltrails.com/explore?b_tl_lat=44.37285823261243&b_tl_lng=-71.41559600830078&b_br_lat=44.346869844887586&b_br_lng=-71.37160778045654
castle <- wm_trails_df %>% filter(trail_name == "CASTLE")
castle_terminus <- castle %>% filter(lat == max(castle$lat))

starr <- wm_trails_df %>% filter(trail_name == 'STARR KING')
starrt <- starr %>% filter(lon == min(starr$lon))
presidential_hwy_path <- impute_line(castle_terminus$lat, castle_terminus$lon,
                                     starrt$lat, starrt$lon) %>%
  mutate(
    trail_name = "PRESIDENTIAL HWY",
    imputed=TRUE
  )

wm_trails_df <- wm_trails_df %>% rbind(presidential_hwy_path, stringsAsFactors=FALSE)

##########################
# join together trail terminuses to nearby trails
##########################
# it appears that trail points are in sorted order, so terminuses are the first and last rows within each trail group
# this may not be true, but it makes life so much easier, we assume it
JOIN_PROXIMITY_KM <- 1.5 # I eyeballed this parameter to capture trails mised by by usfs
trail_terminuses <- wm_trails_df %>%
  mutate(ix = 1:nrow(wm_trails_df)) %>%
  group_by(trail_name) %>%
  do(
    terminuses = (.) %>% filter(ix == min(.$ix) | ix == max(.$ix)) %>% select(-ix)
  ) %>%
  pull(terminuses) %>%
  bind_rows()

new_points <- data.frame()

for (ix in 1:nrow(trail_terminuses)) {
  # yeesh
  terminus <- trail_terminuses[ix, ]
  
  closest_terminus <- trail_terminuses %>%
    filter(trail_name != terminus$trail_name) %>%
    mutate(
      distance_km = sapply(1:nrow(.), function(rix) {haversine_distance(terminus$lat, terminus$lon,
                                                                     lat[rix], lon[rix])})
    ) %>%
    slice(which.min(distance_km))
  
  
  # if the points are exactly equal, no need to duplicate
  if (closest_terminus$distance_km > 0 && closest_terminus$distance_km < JOIN_PROXIMITY_KM) {
    imputed_extension <- impute_line(terminus$lat, terminus$lon, closest_terminus$lat, closest_terminus$lon, closest_terminus$distance_km * 50) %>%
      mutate(
        trail_name = terminus$trail_name,
        imputed = TRUE
      )
    
    new_points <- rbind(new_points, imputed_extension, stringsAsFactors = FALSE)
  }
}

imputed_wm <- wm_trails_df %>%
  rbind(new_points, stringsAsFactors=FALSE)

ggplot(wm_peaks) + 
  geom_point(aes(lon, lat, color=imputed), data=imputed_wm, size=.2, alpha=.2) +
  scale_color_manual(values = c("grey", "darkseagreen2")) +
  geom_point(aes(lon, lat), colour='red', shape=24, size=2) +
  geom_text(aes(lon, lat, label=name)) +
  theme(plot.title = element_text(size=30),
        axis.text=element_text(size=20),
        axis.title=element_text(size=20),
        axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),plot.background=element_blank())

#########################
# associate peaks with the trail
#########################
peak_trail_points <- data.frame()
for (ix in 1:nrow(wm_peaks)) {
  peak <- wm_peaks[ix, ]
  closest_trail_point <- imputed_wm %>%
    mutate(
      distance_km = sapply(1:nrow(.), function(rix) {haversine_distance(peak$lat, peak$lon,
                                                                        lat[rix], lon[rix])})
    ) %>%
    slice(which.min(distance_km)) %>%
    mutate(peak_name = peak$name)
  peak_trail_points <- rbind(peak_trail_points, closest_trail_point, stringsAsFactors=FALSE)
}


#########################
# build the trail graph.
#########################

# here's the approach:
# 1. find all trail intersections (including T intersections). Two approaches I am imagining:
#    a. Use a line sweep approach: https://www.geeksforgeeks.org/given-a-set-of-line-segments-find-if-any-two-segments-intersect/
#    b. Using the heuristic that all "lines" are actually really short, using a moving box approach, where all pairs of line segments within the box are considered. intersecting pairs are collected in a set
# 2. add a point to each trail representing the intersection
# 3. compute graph vertices as the union of peak points, trail terminuses, and trail intersections
# 4. compute graph edges by walking from trail terminus 1 to trail terminus 2 for all trails. when a traversed point belongs to a graph vertex:
#   a. compute the summed distance between all pairs of points along the trail, from the last vertex
#   b. add the distance as an edge weight to the graph

#########################
# compute the direttissima
#########################

