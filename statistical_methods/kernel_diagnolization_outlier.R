library(MASS)
library(ggplot2)

######################################
## this example is pretty trivial- no dimensionality reduction is really required
## but it's an interesting way to test out the arbitrary similarity matrix approach
#######################################
set.seed(55414)
outlier_magnitude <- 4

temp <- matrix(runif(9), nrow = 3)
sig <- temp %*% t(temp)
dat <- data.frame(mvrnorm(n=100, mu = rep(0,3), Sigma = sig))
dat$outlier <- FALSE

dat <- rbind(dat, list(X1 = outlier_magnitude,
                       X2 = outlier_magnitude,
                       X3 = outlier_magnitude,
                       outlier = TRUE),
             # a mild, questionable outlier
             list(X1 = outlier_magnitude,
                  X2 = outlier_magnitude + 2,
                  X3 = outlier_magnitude - 2,
                  outlier = TRUE))

ggplot(dat) + geom_point(aes(X1, X2, color = X3))

D <- as.matrix(dat[,1:3])
sim <- D%*%t(D)
eigs <- eigen(sim)

EPSILON <- 1e-8

e_vals <- eigs$values
e_vecs <- eigs$vectors

keep_ix <- first(which(e_vals < EPSILON)) - 1
e_vals <- e_vals[1:keep_ix]
lambda <- diag(sqrt(e_vals))
Q <- e_vecs[,1:keep_ix]

embedding <- scale(Q %*% lambda)
colnames(embedding) <- c('Z1','Z2','Z3')
ggplot(data.frame(embedding)) + geom_point((aes(Z1,Z2,color=Z3)))

outlier_scores <- apply(embedding, 1, function(row){sum(row^2)})
hist(outlier_scores)
# we might perform a more formal statistic test, but here it is clearly not necessary
outliers <- which(outlier_scores > 20)


#######################################
## add in a bunch of noise columns so that our two outliers are only outliers within a subspace
#######################################
x4 <- runif(nrow(dat))*2
dat <- cbind(dat,
             X4 = x4,
             X5 = rnorm(nrow(dat), mean = x4),
             X6 = rchisq(nrow(dat), df = 3))
D <- as.matrix(dat[,-4])
sim <- D%*%t(D)
eigs <- eigen(sim)

EPSILON <- 1e-8

e_vals <- eigs$values
e_vecs <- eigs$vectors

keep_ix <- first(which(e_vals < EPSILON)) - 1
e_vals <- e_vals[1:keep_ix]
lambda <- diag(sqrt(e_vals))
Q <- e_vecs[,1:keep_ix]

embedding <- scale(Q %*% lambda)

outlier_scores <- apply(embedding, 1, function(row){sum(row^2)})
hist(outlier_scores)
# less convincing for our 2nd outlier, but that's not surprising
# let's see what this looks like with the original data where we compute outlier scores as the distance from the centroid
D_stand <- scale(D)
outlier_scores_original <- apply(D_stand, 1, function(row){sum(row^2)})
hist(outlier_scores_original)
# this looks more convincing... perhaps the proximity based approach can hang because our underlying distribution is more or less a single cluster

#######################################
## try out a dataset with two clusters
#######################################

kdo <- function(D) {
  sim <- D%*%t(D)
  eigs <- eigen(sim)
  
  EPSILON <- 1e-8
  
  e_vals <- eigs$values
  e_vecs <- eigs$vectors
  
  keep_ix <- first(which(e_vals < EPSILON)) - 1
  e_vals <- e_vals[1:keep_ix]
  lambda <- diag(sqrt(e_vals))
  Q <- e_vecs[,1:keep_ix]
  
  embedding <- scale(Q %*% lambda)
  
  outlier_scores <- apply(embedding, 1, function(row){sum(row^2)})
  outlier_scores
}

set.seed(55414)
temp <- matrix(runif(9), nrow = 3)
sig <- temp %*% t(temp)
clust1 <- data.frame(mvrnorm(n=100, mu = rep(0, 3), Sigma = sig))
clust2 <- data.frame(mvrnorm(n=100, mu = rep(-7, 3), Sigma = sig))
d_frame <- rbind(clust1, clust2)
colnames(d_frame) <- c('X1', 'X2', 'X3')

d_frame_outliers <- rbind(d_frame,
                 list(X1 = 5, X2 = 5, X3 = 5),
                 list(X1 = 1, X2 = -4, X3 = -1))

ggplot(d_frame_outliers) + geom_point(aes(X1,X2, color = X3))

scores <- kdo(as.matrix(d_frame_outliers))
hist(scores, breaks = 100)
which(scores > 20)
# so we only found the one off the main line (presumably because it extrapolates "well")
# we expect to see the opposite outlier determined in the original data
d_frame2 <- rbind(d_frame,
                  list(X1 = 5, X2 = 5, X3 = 0), # notice X3 is far from the line, so it's projection error will be large along X3
                  list(X1 = 1, X2 = -4, X3 = -1))
scores <- kdo(as.matrix(d_frame2))
hist(scores, breaks = 100)
which(scores > 20)
# so, we found both

# here's how we perform without kdo

D_o_stand <- scale(as.matrix(d_frame_outliers))
outlier_scores_original <- apply(D_o_stand, 1, function(row){sum(row^2)})
hist(outlier_scores_original)
which(outlier_scores_original > 10)
# yes, only found the expected one far from the centroid

D2_stand <- scale(as.matrix(d_frame2))
outlier_scores_original <- apply(D2_stand, 1, function(row){sum(row^2)})
hist(outlier_scores_original)
which(outlier_scores_original > 10)
# same story, plus our outlier scores are overall much less convincing

##########################
## test out with an arbitrary similarity function
#########################
cosine_sims <- function(X) {
  n <- nrow(X) 
  cmb <- expand.grid(i = 1:n, j = 1:n) 
  C <- matrix(apply(cmb,1,function(ix) {
    A = X[ix[1], ]
    B = X[ix[2], ]
    sum(A * B)/sqrt(sum(A^2)*sum(B^2))
  }), n, n)
}

sim <- cosine_sims(as.matrix(d_frame_outliers))
eigs <- eigen(sim)

EPSILON <- 1e-8

e_vals <- eigs$values
e_vecs <- eigs$vectors

keep_ix <- first(which(e_vals < EPSILON)) - 1
e_vals <- e_vals[1:keep_ix]
lambda <- diag(sqrt(e_vals))
Q <- e_vecs[,1:keep_ix]

embedding <- scale(Q %*% lambda)

outlier_scores_cos <- apply(embedding, 1, function(row){sum(row^2)})
hist(outlier_scores_cos)
which(outlier_scores_cos > 10)
outlier_scores_cos[201:202]
# so our intended outliers don't show up with cosine similarity
# this result isn't particularly surprising. however, it is cool to see that this gives some signal, & we can plug in arbtirary sim functions