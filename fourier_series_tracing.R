library(png)
library(dplyr)
library(ggplot2)

ollie_channels <- readPNG('./ollie.png')
ollie_mat <- ollie_channels[,,4] # greyscale image appears entirely in the 4th channel in this case
ollie_mat <- apply(ollie_mat, 1, function(x){ ifelse(x > .1, 1, 0) })

plot_mat <- function(mat) {
  heatmap(t(mat), Rowv = NA, Colv = NA) # weird ass function in stats - no lib required :)
}

# also returns the i,j point. fine for this usage
get_neighbors <- function(i, j, binmat) {
  i_min <- max(1, i - 1)
  i_max <- min(nrow(binmat), i + 1)
  j_min <- max(1, j - 1)
  j_max <- min(ncol(binmat), j + 1)
  
  as.matrix(expand.grid(i_min:i_max, j_min:j_max))
}

# edge density < 1 can be used to smooth out steps
edge_detection <- function(binmat, edge_density = 7/9) {
  edges_only <- matrix(0, nrow = nrow(binmat), ncol = ncol(binmat))
  for (i in seq(nrow(binmat))) {
    for (j in seq(ncol(binmat))) {
      if (binmat[i,j] == 1) {
        neighbor_ix <- get_neighbors(i,j, binmat)
        if(sum(binmat[neighbor_ix] == 1) / nrow(neighbor_ix) < edge_density) {
          edges_only[i,j] <- 1
        }
      }
    }
  }
  
  edges_only
}

plot_mat(ollie_mat)
ollie_edges <- edge_detection(ollie_mat)
plot_mat(ollie_edges)

ollie_points <- as.data.frame(which(ollie_edges == 1, arr.ind = TRUE))
colnames(ollie_points) <- c('x','y')
plot(ollie_points)

# for v1, we only want to do ollie's outline- manually scrub the inner cocentric circles
ollie_outline <- ollie_points %>%
  filter(sqrt((x -35)^2 + (y - 55)^2) > 31) %>% # clear left circle using eucliden distance from center :)
  filter(sqrt((x - 105)^2 + (y - 55)^2) > 31) %>% # right circle
  mutate( y = -y + 90) # orient correctly
plot(ollie_outline) # that's workable!

# order a component sequentially via nearest neighbor- there are corner cases where this doesn't work nicely
# input is a dataframe, output is a similar dataframe with an "order" column
order_component <- function(component) {
  ordered_component <- component
  ordered_component$uid <- seq(nrow(ordered_component)) # an identifier for making life with dplyr easier
  ordered_component$order <- NA
  ordered_component[1, 'order'] <- 1
  
  current_head_uid <- 1
  
  # nothing tricky, n^2 repeated lookups, even though there are certainly optimizations available
  for (trial in seq(2, nrow(component))) {
    nearest_neighbor <- ordered_component %>%
      filter(is.na(order)) %>%
      mutate(
        distance = (ordered_component[current_head_uid, 'x'] - x) ^ 2 + (ordered_component[current_head_uid, 'y'] - y) ^ 2
      ) %>%
      top_n(1, -distance)
    
    current_head_uid <- nearest_neighbor[['uid']]
    ordered_component[current_head_uid, 'order'] <- trial
  }
  
  ordered_component %>% 
    arrange(order) %>%
    select(-uid, -order)
}

ollie_ordered <- order_component(ollie_outline)

plot(ollie_ordered$x, ollie_ordered$y)
lines(ollie_ordered$x, ollie_ordered$y)

################
## build a fourier series
## following http://www.di.fc.ul.pt/~jpn/r/fourier/fourier.html
get_trajectory <- function(X.k,ts) {
  
  N   <- length(ts)
  i   <- complex(real = 0, imaginary = 1)
  x.n <- rep(0,N)           # create vector to keep the trajectory
  ks  <- 0:(length(X.k)-1)
  
  for(n in 0:(N-1)) {       # compute each time point x_n based on freqs X.k
    blah <- 2*pi*ks*n/N
    #x.n[n+1] <- sum(X.k * exp(i*2*pi*ks*n/N)) / N
    x.n[n+1] <- sum(X.k * (cos(blah) + i*sin(blah)))
  }
  
  x.n
}

ollie_transform <- fft(ollie_outline$y)
y <- get_trajectory(ollie_transform, ollie_outline$x)
plot(ollie_outline$x, y)

###### I'm too mathematically deficient to get a parameterzation out 
###### attempt to compute a fourier series using gradient descent
k <- 10 # the number of series to use
fs_coefs <- matrix(0, 2, 1 + 2 * k) # dc + k terms in series, x & y

eval_point <- function(coefs, point) {
  dc <- coefs[, 1]
  point_estimates <- dc
  for (col_ix in seq(2, ncol(coefs), 2)) {
    series_ix <- col_ix / 2
    even_coef <- coefs[, col_ix]
    odd_coef <- coefs[, col_ix]
    point_estimates <- dc + point_estimates + even_coef * cos(series_ix * point) + 
      odd_coef * sin(series_ix * point)
  }
  
  point_estimates
}

eval_series <- function(coefs, points) {
  t(sapply(points, function(point){ eval_point(coefs, point) }))
}

fs_loss <- function(estimators, t, xy) {
  # unflatten the estimators which optim requires to be a vector
  coefs <- matrix(estimators, nrow = 2)

  xy_est <- eval_series(coefs, t)
  # compute euclidean distance from the actual point
  sum(sqrt(apply((xy_est - xy)^2, 1, sum)))
}

ollie_outline_mat <- as.matrix(ollie_ordered)
gd_results <- optim(par = fs_coefs, t = 1:nrow(ollie_outline_mat), xy= ollie_outline_mat, fn = fs_loss,
              control = list(maxit = 2e2))

estimates <- eval_series(gd_results$par, 1:nrow(ollie_outline))

plot(estimates)
