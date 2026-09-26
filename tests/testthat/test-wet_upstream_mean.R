# Three polygons in a line: 1 <- 2 <- 3 (3 is the headwater).
pairs <- data.frame(
  watershed_feature_id = c(1L, 1L, 1L, 2L, 2L, 3L),
  id_up                = c(1L, 2L, 3L, 2L, 3L, 3L),
  area_up_m2           = c(100, 200, 700, 200, 700, 700),
  upstream_area_m2     = c(1000, 1000, 1000, 900, 900, 700)
)

test_that("total denominator reproduces fwapg's area-weighted mean", {
  values <- data.frame(watershed_feature_id = 1:3, value = c(10, 20, 30), cover = 1)
  out <- wet_upstream_mean(pairs, values, "total")
  expect_equal(out$watershed_feature_id, 1:3)
  expect_equal(out$value, c((1000 + 4000 + 21000) / 1000, (4000 + 21000) / 900, 30))
  expect_equal(out$coverage, c(1, 1, 1))
  expect_equal(out$upstream_area_m2, c(1000, 900, 700))
})

test_that("a missing upstream value biases total low but not covered", {
  values <- data.frame(watershed_feature_id = 1:3, value = c(10, 20, NA),
                       cover = c(1, 1, 0))
  tot <- wet_upstream_mean(pairs, values, "total")
  cov <- wet_upstream_mean(pairs, values, "covered")
  expect_equal(tot$value[1], (1000 + 4000) / 1000)
  expect_equal(cov$value[1], (1000 + 4000) / 300)
  expect_equal(cov$coverage[1], 0.3)
  expect_true(is.na(cov$value[3]))
  # no upstream value at all is NA, not zero flow
  expect_true(is.na(tot$value[3]))
})

test_that("total mode counts a polygon's uncovered share as missing ground", {
  two <- data.frame(watershed_feature_id = c(1L, 1L), id_up = c(1L, 2L),
                    area_up_m2 = c(100, 100), upstream_area_m2 = 200)
  for (cv in c(1, 0.5, 0.01)) {
    values <- data.frame(watershed_feature_id = 1:2, value = c(10, 10), cover = c(1, cv))
    expect_equal(wet_upstream_mean(two, values, "total")$value, (1000 + 1000 * cv) / 200)
    expect_equal(wet_upstream_mean(two, values, "covered")$value, 10)
  }
})

test_that("partial cover weights the covered part of each polygon", {
  values <- data.frame(watershed_feature_id = 1:3, value = c(10, 20, 30),
                       cover = c(1, 0.5, 1))
  cov <- wet_upstream_mean(pairs, values, "covered")
  expect_equal(cov$value[2], (20 * 200 * 0.5 + 30 * 700) / (100 + 700))
  expect_equal(cov$coverage[2], 800 / 900)
})

test_that("no value anywhere upstream is NA in both modes", {
  values <- data.frame(watershed_feature_id = 1:3, value = NA_real_, cover = 0)
  for (d in c("total", "covered")) {
    out <- wet_upstream_mean(pairs, values, d)
    expect_true(all(is.na(out$value)))
    expect_equal(out$coverage, c(0, 0, 0))
  }
})

test_that("a value with zero or NA cover is no data in both modes", {
  two <- data.frame(watershed_feature_id = c(1L, 1L), id_up = c(1L, 2L),
                    area_up_m2 = c(100, 100), upstream_area_m2 = 200)
  for (cv in list(0, NA_real_)) {
    values <- data.frame(watershed_feature_id = 1:2, value = c(10, NA), cover = c(cv, 0))
    expect_true(is.na(wet_upstream_mean(two, values, "total")$value))
    expect_true(is.na(wet_upstream_mean(two, values, "covered")$value))
  }
})

test_that("upstream polygons absent from values count as uncovered", {
  values <- data.frame(watershed_feature_id = 1:2, value = c(10, 20), cover = 1)
  expect_equal(wet_upstream_mean(pairs, values, "covered")$coverage[1], 0.3)
})

test_that("bad inputs are refused", {
  values <- data.frame(watershed_feature_id = 1:3, value = 1, cover = 1)
  expect_error(wet_upstream_mean(pairs[, -3], values), "area_up_m2")
  expect_error(wet_upstream_mean(pairs, rbind(values, values)))
})
