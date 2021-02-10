
parse_time <- function(t) {
  x <- strsplit(t, ':')
  m <- as.numeric(x[[1]][1])
  s <- as.numeric(x[[1]][2])
  return(m * 60 + s)
}

process_mtec <- function(filename) {
  raw <- read.csv(filename)
  parts <- strsplit(filename)
  raw %>%
    mutate() %>%
    rename(
      place = Place,
      name = Name,
      gender = parts[[1]][3],
      section = parts[[1]][2],
      team = Team,
      time = sapply(Both, parse_time),
      individual_qualifier = State == 'IND',
      team_qualifier = State == 'TEA'
    )
}

rbind(
  process_mtec('sec_boys_1.csv')
  stringsOnFactors=FALSE
)

