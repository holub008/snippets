library(rgdal)
library(sp)
library(rvest)
library(dplyr)
library(ggplot2)
library(stringr)

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
