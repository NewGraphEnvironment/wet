# Six donors in a 2-D predictor space with one-column values, and a target
# sitting on donor 3.
donor_space <- function() {
  list(x = matrix(c(0, 1, 2, 3, 5, 8, 0, 2, 1, 4, 3, 7), ncol = 2), y = matrix(c(10, 20, 30, 40, 50, 60)))
}

test_that("a donor at the target's own place takes the whole weight", {
  d <- donor_space()
  expect_equal(wet:::wet_donor_mean(d$x[3, , drop = FALSE], d$x, d$y, 5), matrix(30))
})

test_that("a donor moved by its last bits still takes the whole weight (#158)", {
  d <- donor_space()
  x <- d$x[3, , drop = FALSE] * (1 + 1e-15)
  expect_false(isTRUE(all(x == d$x[3, ])))
  expect_identical(wet:::wet_donor_mean(x, d$x, d$y, 5), matrix(30))
})

test_that("donors within the tolerance share the weight equally", {
  d <- donor_space()
  d$x[4, ] <- d$x[3, ] * (1 + 1e-14)
  expect_equal(wet:::wet_donor_mean(d$x[3, , drop = FALSE], d$x, d$y, 5), matrix(35))
})

test_that("a donor beyond the tolerance is weighted by inverse distance", {
  d <- donor_space()
  x <- d$x[3, , drop = FALSE] + c(1e-3, 0)
  dist <- sqrt(colSums((t(d$x) - drop(x))^2))
  o <- order(dist)[1:5]
  w <- 1 / (dist[o] + 1e-6 * stats::median(dist))
  got <- wet:::wet_donor_mean(x, d$x, d$y, 5)
  expect_equal(got, matrix(sum(d$y[o] * w) / sum(w)))
  expect_lt(abs(got[1] - 30), 1)
  expect_gt(abs(got[1] - 30), 1e-9)
})

test_that("a target with a missing predictor gets NA", {
  d <- donor_space()
  expect_true(is.na(wet:::wet_donor_mean(matrix(c(NA, 1), 1), d$x, d$y, 5)[1, 1]))
})
