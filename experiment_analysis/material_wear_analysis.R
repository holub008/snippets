library(lubridate)
library(dplyr)
library(ggplot2)

library(nymph) # installable from https://github.com/holub008/nymph - not using for analytical purposes here, just testing for fun

wear_data <- rbind(
  # each binded frame is a material
  data.frame(
    ds = rep(sapply(c('2018-07-18','2018-07-19','2018-07-20','2018-07-23','2018-07-24'), ymd), 2),
    location = rep(c('1','2'), each = 5),
    volume_removed = c(.2117, .70004, .7402, .9249, .4272,
                       .07412, .1796, .19995, .287996, .2614),
    material = 'E55D'
  ),
  data.frame(
    ds = rep(sapply(c('2018-07-25','2018-07-26','2018-07-27','2018-07-27','2018-07-28'), ymd), 2),
    location = sapply(c('1', '2', rep(c('2', '1'), 4)), as.character), # the experimenter swapped the coupons
    volume_removed = c(.2183, .1117, .2246, .0721, .05919,
                       .1504, .522, .2892, .1746, .40904),
    material = 'AC Carbothane 55D'
  ),
  data.frame(
    ds = rep(sapply(c('2018-07-30','2018-07-30','2018-07-31','2018-07-31','2018-08-01'), ymd), 2),
    location = rep(c('2','1'), each = 5),
    volume_removed = c(.1086, .08361, .1135, .122, .1747,
                       .1241, .1302, .1534, .2644, .711), # experimenter emphasized .711 as a "point they were pissed about". not a known corrupt observation though
    material = 'HPB PU 50D'
  ),
  data.frame(
    ds = rep(sapply(c('2018-08-02','2018-08-03','2018-08-06','2018-08-07','2018-08-08'), ymd), 2),
    location = rep(c('2','1'), each = 5),
    volume_removed = c(.138, .0814, .133, .101, .181,
                       .22, .205, .255, .145, .139),
    material = 'PIB PU 85A'
  )
)

# manufactoring the time effect in days, relative to start of the experiment
wear_data$time <- as.integer(wear_data$ds - min(wear_data$ds))

# create a within material time effect
wear_data <- wear_data %>%
  group_by(material) %>%
  mutate(
    within_material_time = time - min(time)
  ) %>%
  ungroup()

# visually inspecting main effects
wear_data %>%
  group_by(location) %>%
  summarize(
    mean_volume = mean(volume_removed)
  )

wear_data %>%
  group_by(material) %>%
  summarize(
    mean_volume = mean(volume_removed)
  )

ggplot(wear_data) +
  geom_smooth(aes(time, volume_removed)) +
  geom_point(aes(time, volume_removed, color = material, shape = location))



# fitting a main effects model (considering location adjustment, ignoring any temporal correlation)
m <- lm(volume_removed ~ material + location + log(time + 1), wear_data)
summary(m) # can't pick out any single material as varying 
anova(m)
# so, time, location, & material are all significant predictors of wear volume

################################
## unfortunately the experiment was run with materials 
## so, if a time effect exists, it will be correlated with materials, leading to false inference
## we may be able to detect a time effect by looking at within material time effects
################################

wear_data %>%
  group_by(material) %>%
  mutate(
    material_avg = mean(volume_removed),
    volume_removed_residual = volume_removed - material_avg
  ) %>%
  ggplot() +
    geom_point(aes(within_material_time, volume_removed_residual)) +
    geom_smooth(aes(within_material_time, volume_removed_residual))
# cool! that actually looks pretty uniform, which suggests time isn't a big impact here  