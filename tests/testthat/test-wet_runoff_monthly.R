daily_raster <- function(years, value = function(d) as.integer(format(d, "%m"))) {
  d <- seq(as.Date(sprintf("%d-01-01", min(years))),
           as.Date(sprintf("%d-12-31", max(years))), by = "day")
  r <- terra::rast(nrows = 1, ncols = 2, nlyrs = length(d), xmin = 0, xmax = 2,
                   ymin = 0, ymax = 1, crs = "EPSG:4326")
  v <- value(d)
  terra::values(r) <- rbind(v, 2 * v + ifelse(format(d, "%Y") == "1984", 1, 0))
  terra::time(r) <- d
  r
}

test_that("twelve layers, each the mean over years of the month's total", {
  r <- daily_raster(1983:1984)   # 1984 is a leap year
  m <- wet_runoff_monthly(r)
  expect_equal(terra::nlyr(m), 12L)
  expect_equal(names(m), sprintf("m%02d", 1:12))
  days <- function(y) {
    d <- seq(as.Date(sprintf("%d-01-01", y)), as.Date(sprintf("%d-12-31", y)), by = "day")
    as.integer(table(format(d, "%m")))
  }
  n83 <- days(1983)
  n84 <- days(1984)
  # cell 1 holds the month number every day
  expect_equal(as.numeric(terra::values(m)[1, ]), (1:12) * (n83 + n84) / 2)
  # cell 2 adds 1 a day in 1984 only
  expect_equal(as.numeric(terra::values(m)[2, ]), (2 * (1:12) * (n83 + n84) + n84) / 2)
  expect_equal(n84[2], 29L)
})

test_that("the twelve months sum to the annual mean", {
  r <- daily_raster(1983:1985, function(d) sin(as.numeric(d)) + 2)
  m <- wet_runoff_monthly(r)
  a <- wet_runoff_annual(r)
  expect_equal(as.numeric(terra::values(sum(m))), as.numeric(terra::values(a)),
               tolerance = 1e-12)
})

test_that("an incomplete year, a duplicated date or no time axis is refused", {
  r <- daily_raster(1983:1984)
  expect_error(wet_runoff_monthly(r[[-10]]), "incomplete years: 1983")
  dup <- r
  t <- terra::time(dup)
  t[2] <- t[1]
  terra::time(dup) <- t
  expect_error(wet_runoff_monthly(dup), "duplicate dates")
  bare <- terra::rast(nrows = 1, ncols = 1, nlyrs = 3, vals = 1)
  expect_error(wet_runoff_monthly(bare), "time axis")
})
