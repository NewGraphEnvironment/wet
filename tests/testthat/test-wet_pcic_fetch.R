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
