daily <- function(start, end, fill = 1) {
  d <- seq(as.Date(start), as.Date(end), by = "day")
  r <- terra::rast(nrows = 1, ncols = 2, nlyrs = length(d),
                   xmin = 0, xmax = 2, ymin = 0, ymax = 1)
  terra::values(r) <- fill
  terra::time(r) <- d
  r
}

test_that("annual total is sum per year then mean over years, leap years included", {
  r <- daily("1983-01-01", "1984-12-31")   # 365 + 366 days of 1 mm
  out <- wet_runoff_annual(r)
  expect_equal(terra::nlyr(out), 1L)
  expect_equal(as.numeric(terra::values(out)), rep(365.5, 2))
})

test_that("different daily values per year average correctly", {
  d1 <- seq(as.Date("1981-01-01"), as.Date("1981-12-31"), by = "day")
  d2 <- seq(as.Date("1982-01-01"), as.Date("1982-12-31"), by = "day")
  r <- terra::rast(nrows = 1, ncols = 1, nlyrs = 730)
  terra::values(r) <- matrix(c(rep(1, 365), rep(3, 365)), nrow = 1)
  terra::time(r) <- c(d1, d2)
  expect_equal(as.numeric(terra::values(wet_runoff_annual(r))), (365 + 1095) / 2)
})

test_that("NA cells stay NA", {
  r <- daily("1981-01-01", "1981-12-31")
  r[1] <- NA
  expect_equal(is.na(as.numeric(terra::values(wet_runoff_annual(r)))), c(TRUE, FALSE))
})

test_that("partial years and missing time are refused", {
  expect_error(wet_runoff_annual(daily("1981-01-01", "1981-12-30")), "incomplete years: 1981")
  r <- terra::rast(nrows = 1, ncols = 1, nlyrs = 2)
  expect_error(wet_runoff_annual(r), "time axis")
})
