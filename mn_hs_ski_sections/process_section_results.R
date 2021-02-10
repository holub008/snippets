
parse_time <- function(t) {
  x <- strsplit(t, ':')
  m <- as.numeric(x[[1]][1])
  s <- as.numeric(x[[1]][2])
  return(m * 60 + s)
}

process_mtec <- function(filename) {
  raw <- read.csv(filename)
  parts <- strsplit(filename, '_')
  raw %>%
    mutate(
      time = sapply(Both, parse_time),
      individual_qualifier = State == 'IND',
      team_qualifier = State == 'TEA',
      gender = strsplit(parts[[1]][3], '\\.')[[1]][1],
      section = parts[[1]][2]
    ) %>%
    rename(
      place = Place,
      name = Name,
      team = Team
    ) %>%
    select(place, name, gender, team, time, section, individual_qualifier, team_qualifier)
}

process_caps <- function(filename, winning_teams) {
  raw <- read.csv(filename)
  parts <- strsplit(filename, '_')
  raw %>%
    mutate(
      team_qualifier = sapply(SCHOOL, function(s) {s %in% winning_teams})
    ) %>%
    group_by(team_qualifier) %>%
    mutate(
      class_place = rank(OVERALLPUR)
    ) %>%
    ungroup() %>%
    mutate(
      time = sapply(PUR_TIME, parse_time),
      individual_qualifier = !team_qualifier & class_place < 7,
      gender = strsplit(parts[[1]][3], '\\.')[[1]][1],
      section = parts[[1]][2],
      name = paste(FIRST.NAME, LAST.NAME)
    ) %>%
    rename(
      place = OVERALLPUR,
      team = SCHOOL
    ) %>%
    select(place, name, gender, team, time, section, individual_qualifier, team_qualifier)
}

process_sec7 <- function(filename, winnng_teams) {
  raw <- read.csv(filename)
  parts <- strsplit(filename, '_')
  raw %>%
    mutate(
      team_qualifier = sapply(Team, function(s) {s %in% winning_teams})
    ) %>%
    group_by(team_qualifier) %>%
    mutate(
      class_place = rank(Place)
    ) %>%
    ungroup() %>%
    mutate(
      time = sapply(Pursuit, parse_time),
      individual_qualifier = !team_qualifier & class_place < 7,
      gender = strsplit(parts[[1]][3], '\\.')[[1]][1],
      section = parts[[1]][2],
    ) %>%
    rename(
      place = Place,
      name = Name,
      team = 
    ) %>%
    select(place, name, gender, team, time, section, individual_qualifier, team_qualifier)
}

process_sec8 <- function(filename, winning_teams) {
  raw <- read.csv(filename)
  parts <- strsplit(filename, '_')
  raw %>%
    mutate(
      team_qualifier = sapply(Team, function(s) {s %in% winning_teams})
    ) %>%
    group_by(team_qualifier) %>%
    mutate(
      class_place = rank(Place)
    ) %>%
    ungroup() %>%
    mutate(
      time = sapply(Pursuit, parse_time),
      individual_qualifier = !team_qualifier & class_place < 7,
      gender = strsplit(parts[[1]][3], '\\.')[[1]][1],
      section = parts[[1]][2],
    ) %>%
    rename(
      place = Place,
      name = Name,
      team = Team
    ) %>%
    select(place, name, gender, team, time, section, individual_qualifier, team_qualifier)
}

all_data <- rbind(
  process_mtec('sec_1_boys.csv'),
  process_mtec('sec_1_girls.csv'),
  process_mtec('sec_2_girls.csv'),
  process_mtec('sec_2_boys.csv'),
  process_caps('sec_3_girls.csv', c('SPHigh', 'SPCent')),
  process_caps('sec_3_boys.csv', c('SPHigh', 'MAcad')),
  process_caps('sec_4_girls.csv', c('Stlwtr', 'FrtLk')),
  process_caps('sec_4_boys.csv', c('Stlwtr', 'FrtLk')),
  process_mtec('sec_5_girls.csv'),
  process_mtec('sec_5_boys.csv'),
  process_mtec('sec_7_girls.csv'),
  process_mtec('sec_7_boys.csv'),
  process_sec8('sec_8_boys.csv', c('Sartell Cathedral', 'Little Falls')),
  process_sec8('sec_8_girls.csv', c('Moorhead', 'Brainerd'))
)

