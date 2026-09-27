test_that("tile names follow the south-west corner convention", {
  n <- wet:::wet_glo90_names(c(-128.4, 54.2, -127.1, 55.9))
  expect_setequal(n, c(
    "Copernicus_DSM_COG_30_N54_00_W129_00_DEM", "Copernicus_DSM_COG_30_N55_00_W129_00_DEM",
    "Copernicus_DSM_COG_30_N54_00_W128_00_DEM", "Copernicus_DSM_COG_30_N55_00_W128_00_DEM"
  ))
})

test_that("a bbox on whole degrees does not add an empty row or column of tiles", {
  expect_length(wet:::wet_glo90_names(c(-128, 54, -127, 55)), 1)
  expect_equal(wet:::wet_glo90_names(c(-128, 54, -127, 55)),
               "Copernicus_DSM_COG_30_N54_00_W128_00_DEM")
})

test_that("a cached DEM is returned without reaching the network", {
  dir <- withr::local_tempdir()
  tmpl <- terra::rast(xmin = -128, xmax = -127, ymin = 54, ymax = 55, res = 1 / 120,
                      crs = "EPSG:4326")
  f <- file.path(dir, sprintf("glo90v3_%s.tif", substr(wet:::wet_grid_key(tmpl), 1, 12)))
  file.create(f)
  withr::local_options(wet.glo90_base = "http://127.0.0.1:9")
  expect_equal(wet_dem_glo90(tmpl, dir = dir), f)
})

test_that("GDAL options set for a read are restored to unset, not to \"NA\"", {
  k <- "WET_TEST_OPTION"
  terra::setGDALconfig(k, "")
  old <- wet:::wet_gdal_config_set(stats::setNames("on", k))
  expect_equal(unname(terra::getGDALconfig(k)), "on")
  wet:::wet_gdal_config_set(old)
  expect_equal(unname(terra::getGDALconfig(k)), "")
})

test_that("a projected template is refused, since the cache key assumes lon/lat", {
  tmpl <- terra::rast(xmin = 1e6, xmax = 1.1e6, ymin = 1e6, ymax = 1.1e6, res = 1000, crs = "EPSG:3005")
  expect_error(wet_dem_glo90(tmpl, dir = withr::local_tempdir()), "lon/lat")
})

test_that("grids a fraction of a cell apart get different keys", {
  a <- terra::rast(xmin = -128, xmax = -127, ymin = 54, ymax = 55, res = 1 / 120, crs = "EPSG:4326")
  b <- terra::shift(a, dx = 0.0004)
  expect_false(wet:::wet_grid_key(a) == wet:::wet_grid_key(b))
})
