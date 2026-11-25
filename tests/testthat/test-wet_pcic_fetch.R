test_that("NetCDF signatures are recognised and HTML is not", {
  nc <- withr::local_tempfile()
  writeBin(c(charToRaw("CDF"), as.raw(2), as.raw(rep(0, 8))), nc)
  expect_true(wet:::wet_is_netcdf(nc))

  h5 <- withr::local_tempfile()
  writeBin(as.raw(c(0x89, 0x48, 0x44, 0x46, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0)), h5)
  expect_true(wet:::wet_is_netcdf(h5))

  html <- withr::local_tempfile()
  writeLines("<html><body>301 Moved Permanently</body></html>", html)
  expect_false(wet:::wet_is_netcdf(html))

  expect_false(wet:::wet_is_netcdf(withr::local_tempfile()))
})

test_that("a cached subset is returned without downloading", {
  dir <- withr::local_tempdir()
  ix <- wet_pcic_index(c(-123, 54, -122.9, 54.1), "1981-01-01", "1981-01-02")
  f <- file.path(dir, sprintf("TPS_gridded_obs_init_RUNOFF_t%d-%d_y%d-%d_x%d-%d.nc",
                              ix$time[1], ix$time[2], ix$lat[1], ix$lat[2],
                              ix$lon[1], ix$lon[2]))
  file.create(f)
  # base points nowhere: reaching the network would error
  withr::local_options(wet.pcic_base = "http://127.0.0.1:9")
  expect_equal(wet_pcic_fetch("RUNOFF", c(-123, 54, -122.9, 54.1),
                              "1981-01-01", "1981-01-02", dir = dir), f)
})

# A NetCDF on the PCIC grid holding the given days, written as a download would land.
nc_days <- function(path, days) {
  r <- terra::rast(nrows = 1, ncols = 1, nlyrs = length(days), xmin = -123.03125,
                   xmax = -122.96875, ymin = 53.96875, ymax = 54.03125, crs = "EPSG:4326")
  terra::values(r) <- seq_along(days)
  terra::time(r) <- days
  terra::writeCDF(r, path, varname = "RUNOFF", overwrite = TRUE)
}

fetch_one <- function(dir) {
  wet_pcic_fetch("RUNOFF", c(-123, 54, -122.99, 54.01), "1981-01-01", "1981-01-03",
                 dir = dir)
}
days_asked <- seq(as.Date("1981-01-01"), as.Date("1981-01-03"), by = "day")

test_that("a 429 waits and tries again, and the 200 that follows is kept", {
  skip_if_not_installed("ncdf4")
  dir <- withr::local_tempdir()
  calls <- 0L
  waits <- numeric()
  local_mocked_bindings(
    wet_http_disk = function(url, path, timeout) {
      calls <<- calls + 1L
      if (calls == 1L) {
        writeLines("Too Many Requests", path)
        return(list(status = 429L, retry_after = 7))
      }
      nc_days(path, days_asked)
      list(status = 200L, retry_after = NA_real_)
    },
    wet_wait = function(seconds) waits <<- c(waits, seconds)
  )
  f <- fetch_one(dir)
  expect_equal(calls, 2L)
  expect_equal(waits, 7)
  expect_true(file.exists(f))
  expect_equal(as.Date(terra::time(terra::rast(f))), days_asked)
  expect_identical(list.files(dir), basename(f))
})

test_that("without Retry-After the waits start at 60 s and double, and five refusals stop", {
  dir <- withr::local_tempdir()
  waits <- numeric()
  local_mocked_bindings(
    wet_http_disk = function(url, path, timeout) {
      writeLines("busy", path)
      list(status = 503L, retry_after = NA_real_)
    },
    wet_wait = function(seconds) waits <<- c(waits, seconds)
  )
  expect_error(fetch_one(dir), "503 on 5 tries")
  expect_equal(waits, c(60, 120, 240, 480))
  expect_length(list.files(dir), 0L)
})

test_that("any other status stops, naming it", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(
    wet_http_disk = function(url, path, timeout) {
      writeLines("<html>Not Found</html>", path)
      list(status = 404L, retry_after = NA_real_)
    },
    wet_wait = function(seconds) stop("should not wait")
  )
  expect_error(fetch_one(dir), "HTTP 404")
  expect_length(list.files(dir), 0L)
})

test_that("a 200 that is an HTML page is refused", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(wet_http_disk = function(url, path, timeout) {
    writeLines("<html><body>301 Moved Permanently</body></html>", path)
    list(status = 200L, retry_after = NA_real_)
  })
  expect_error(fetch_one(dir), "is not NetCDF")
  expect_length(list.files(dir), 0L)
})

test_that("a NetCDF holding other days is refused and not cached", {
  skip_if_not_installed("ncdf4")
  dir <- withr::local_tempdir()
  local_mocked_bindings(wet_http_disk = function(url, path, timeout) {
    nc_days(path, days_asked + 30)   # a 360-day axis or a wrong offset lands like this
    list(status = 200L, retry_after = NA_real_)
  })
  expect_error(fetch_one(dir), "holds other days")
  expect_length(list.files(dir), 0L)
})
