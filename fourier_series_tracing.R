library(png)
library(dplyr)

ollie_channels <- readPNG('~/Downloads/ollie.png')
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
