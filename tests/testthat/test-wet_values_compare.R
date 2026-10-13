fr <- function(id, month, q) data.frame(linear_feature_id = id, month = month, q_m3s = q)

test_that("identical tables compare equal, row by row", {
  a <- fr(c(1L, 1L, 2L), c(0L, 1L, 0L), c(1.5, 2, 0))
  expect_equal(wet_values_compare(a, a[3:1, ]), c(compared = 3, differing = 0, max_abs_diff = 0))
})

test_that("a value outside the tolerance differs, and is sized", {
  a <- fr(1:3, 0L, c(1, 2, 3))
  b <- fr(1:3, 0L, c(1, 2 + 1e-12, 3.5))
  r <- wet_values_compare(a, b)
  # 2 + 1e-12 is within the relative tolerance; 3.5 is not
  expect_equal(r[["differing"]], 1)
  expect_equal(r[["max_abs_diff"]], 0.5)
  expect_equal(wet_values_compare(a, b, tol = 1e-13)[["differing"]], 2)
})

test_that("a key on one side only differs, on either side", {
  a <- fr(1:3, 0L, 1)
  b <- fr(c(1L, 2L, 4L), 0L, 1)
  r <- wet_values_compare(a, b)
  expect_equal(r[["compared"]], 4)
  expect_equal(r[["differing"]], 2)
  # an empty side is all one-sided, never a pass
  expect_equal(wet_values_compare(a, a[0, ])[["differing"]], 3)
})

test_that("NA on one side differs; NA on both does not", {
  a <- fr(1:2, 0L, c(NA, NA))
  b <- fr(1:2, 0L, c(NA, 1))
  r <- wet_values_compare(a, b)
  expect_equal(r[["differing"]], 1)
  expect_equal(r[["max_abs_diff"]], 0)
})

test_that("the month is part of the key", {
  a <- fr(c(1L, 1L), c(1L, 2L), c(1, 2))
  b <- fr(c(1L, 1L), c(2L, 1L), c(1, 2))
  expect_equal(wet_values_compare(a, b)[["differing"]], 2)
})

test_that("a duplicated key or a bad month is refused", {
  expect_error(wet_values_compare(fr(c(1L, 1L), 0L, 1), fr(1L, 0L, 1)), "twice")
  expect_error(wet_values_compare(fr(1L, 13L, 1), fr(1L, 0L, 1)), "outside 0-12")
  expect_error(wet_values_compare(fr(1L, 0L, 1)[c("linear_feature_id", "month")], fr(1L, 0L, 1)), "needs columns")
})
