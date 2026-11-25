fake_pcic_year <- function(dir, y, fill, xmax = 2) {
  d <- seq(as.Date(sprintf("%d-01-01", y)), as.Date(sprintf("%d-12-31", y)), by = "day")
  r <- terra::rast(nrows = 2, ncols = 2, nlyrs = length(d), xmin = 0, xmax = xmax,
                   ymin = 0, ymax = 2, crs = "EPSG:4326")
  v <- rep(fill, length.out = 4)
  terra::values(r) <- rep(v, times = length(d))
  terra::time(r) <- d
  f <- file.path(dir, sprintf("y%d_%s.nc", y, xmax))
  terra::writeCDF(r, f, varname = "RUNOFF", overwrite = TRUE)
  f
}

test_that("per-year months average to the whole period's months", {
  skip_if_not_installed("ncdf4")   # terra::writeCDF() builds the fixtures with it
  dir <- withr::local_tempdir()
  files <- c(`1983` = fake_pcic_year(dir, 1983, c(1, 2, 3, NA)),
             `1984` = fake_pcic_year(dir, 1984, c(3, 2, 1, NA)))
  calls <- list()
  mock <- function(variable, bbox, start, end, run, dir, overwrite, timeout) {
    calls[[length(calls) + 1L]] <<- list(start = start, end = end, run = run)
    files[[substr(start, 1, 4)]]
  }
  # the mock's arguments are the real fetch's, so a renamed argument fails here
  expect_identical(names(formals(mock)), names(formals(wet_pcic_fetch)))
  local_mocked_bindings(wet_pcic_fetch = mock)
  got <- wet_pcic_monthly("RUNOFF", c(0, 0, 2, 2), 1983:1984, run = "CanESM2_rcp45_r1i1p1")
  whole <- wet_runoff_monthly(terra::rast(unname(files)))
  expect_equal(names(got), sprintf("m%02d", 1:12))
  expect_equal(terra::values(got), terra::values(whole), ignore_attr = TRUE)
  expect_equal(as.numeric(terra::values(got)[2, 2]), 2 * (28 + 29) / 2)
  expect_true(all(is.na(terra::values(got)[4, ])))
  expect_equal(vapply(calls, `[[`, "", "start"), c("1983-01-01", "1984-01-01"))
  expect_equal(vapply(calls, `[[`, "", "end"), c("1983-12-31", "1984-12-31"))
  expect_true(all(vapply(calls, `[[`, "", "run") == "CanESM2_rcp45_r1i1p1"))
})

test_that("a year on another grid is refused", {
  skip_if_not_installed("ncdf4")
  dir <- withr::local_tempdir()
  files <- c(`1983` = fake_pcic_year(dir, 1983, 1),
             `1984` = fake_pcic_year(dir, 1984, 1, xmax = 3))
  local_mocked_bindings(wet_pcic_fetch = function(variable, bbox, start, end, run, dir,
                                                  overwrite, timeout) {
    files[[substr(start, 1, 4)]]
  })
  expect_error(wet_pcic_monthly("RUNOFF", c(0, 0, 2, 2), 1983:1984), "different grid")
})

test_that("years must be distinct and present", {
  expect_error(wet_pcic_monthly("RUNOFF", c(0, 0, 1, 1), integer()))
  expect_error(wet_pcic_monthly("RUNOFF", c(0, 0, 1, 1), c(1981, 1981)))
})
