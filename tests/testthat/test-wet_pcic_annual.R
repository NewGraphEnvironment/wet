fake_year <- function(dir, y, fill) {
  d <- seq(as.Date(sprintf("%d-01-01", y)), as.Date(sprintf("%d-12-31", y)), by = "day")
  r <- terra::rast(nrows = 2, ncols = 2, nlyrs = length(d), xmin = 0, xmax = 2,
                   ymin = 0, ymax = 2, crs = "EPSG:4326")
  v <- rep(fill, length.out = 4)
  terra::values(r) <- rep(v, times = length(d))
  terra::time(r) <- d
  f <- file.path(dir, sprintf("y%d.nc", y))
  terra::writeCDF(r, f, varname = "RUNOFF", overwrite = TRUE)
  f
}

test_that("per-year reduction equals the whole-period annual mean", {
  dir <- withr::local_tempdir()
  files <- c(`1983` = fake_year(dir, 1983, c(1, 2, 3, NA)),
             `1984` = fake_year(dir, 1984, c(3, 2, 1, NA)))
  local_mocked_bindings(wet_pcic_fetch = function(variable, bbox, start, end, ...) {
    files[[substr(start, 1, 4)]]
  })
  got <- wet_pcic_annual("RUNOFF", c(0, 0, 2, 2), 1983:1984)
  whole <- wet_runoff_annual(terra::rast(unname(files)))
  expect_equal(as.numeric(terra::values(got)), as.numeric(terra::values(whole)))
  expect_equal(as.numeric(terra::values(got))[1:3],
               c((365 + 3 * 366) / 2, (2 * 365 + 2 * 366) / 2, (3 * 365 + 366) / 2))
  expect_true(is.na(terra::values(got)[4]))
})

test_that("years must be distinct and present", {
  expect_error(wet_pcic_annual("RUNOFF", c(0, 0, 1, 1), integer()))
  expect_error(wet_pcic_annual("RUNOFF", c(0, 0, 1, 1), c(1981, 1981)))
})
