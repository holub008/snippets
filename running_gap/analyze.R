library(dplyr)
library(ggplot2)

records <- read.csv('./records.csv', stringsAsFactors = FALSE)

name_to_distance <- data.frame(
  name = c('100 m', '200 m', '400 m', '800 m', '1000 m', '1500 m',
           'Mile', '2000 m', '3000 m', '5000 m', '10,000 m (track)',
           '20,000 m (track)', 'Half marathon', '25,000 m (track)', '30,000 m (track)',
           'Marathon[b]', '100 km (road)'),
  distance_meters = c(100, 200, 400, 800, 1000, 1500, 1609.34, 2000, 3000, 5000, 10000, 20000,
                      21097.5, 25000, 30000, 42195, 100000),
  stringsAsFactors = FALSE
)

# note we inner join to drop races we don't care about
records_with_distance <- records %>%
  inner_join(name_to_distance, by = c('Event' = 'name')) %>%
  # remove some dupes, in favor of legitimate, fastest times
  filter(is.na(N) | (N != 'Wo[k]' & N != '[c]'))

             
records_with_distance %>%
  ggplot() +
    geom_point(aes(log(distance_meters), log(duration), color = gender)) +
    xlab('Log(Distance)') +
    ylab('Log(Duration)')

records_with_distance %>% filter(gender == 'male') %>%
  inner_join((records_with_distance %>% filter(gender == 'female')), by = 'distance_meters') %>%
  mutate(time_ratio = duration.x / duration.y)  %>%
  ggplot() +
    geom_line(aes(distance_meters, time_ratio)) +
    xlab('Distance (m)') +
    ylab('Time Ratio (men/women)')
