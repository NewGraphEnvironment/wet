# Synthetic stand-in for a TerraClimate monthly climatology: 12 layers on the
# 1/24-degree lattice. GDAL identifies files by content, so a GeoTIFF at the
# .nc path reads the same way.
local_tc <- function(dir, var, month_value, na_cols = integer()) {
  r <- terra::rast(nrows = 24, ncols = 48, xmin = -121, xmax = -119, ymin = 49, ymax = 50,
                   crs = "EPSG:4326", nlyrs = 12)
  for (m in 1:12) {
    v <- rep(month_value * m, terra::ncell(r))
    v[((seq_len(terra::ncell(r)) - 1) %% 48 + 1) %in% na_cols] <- NA
    terra::values(r[[m]]) <- v
  }
  f <- file.path(dir, sprintf("TerraClimate_19812010_%s.nc", var))
  terra::writeRaster(r, f, filetype = "GTiff")
  f
}

test_that("months are summed and resampled onto the grid, named <var>_tc", {
  dir <- withr::local_tempdir()
  local_tc(dir, "aet", 1)
  local_tc(dir, "ppt", 2)
  grid <- terra::rast(xmin = -120.5, xmax = -119.5, ymin = 49.2, ymax = 49.8, res = 1 / 120,
                      crs = "EPSG:4326")
  f <- wet_terraclimate_aet(grid, dir = dir)
  r <- terra::rast(f)
  expect_equal(names(r), c("aet_tc", "ppt_tc"))
  expect_true(terra::compareGeom(r, grid))
  # constant fields: the annual total everywhere, sum(1:12) = 78
  expect_equal(unname(unlist(terra::global(r, "min"))), c(78, 156), tolerance = 1e-5)
  expect_equal(unname(unlist(terra::global(r, "max"))), c(78, 156), tolerance = 1e-5)
})

test_that("next to a gap, bilinear reweights instead of leaving a band of NA", {
  dir <- withr::local_tempdir()
  local_tc(dir, "aet", 1, na_cols = 1:24)  # the western half is 'ocean'
  grid <- terra::rast(xmin = -120.5, xmax = -119.5, ymin = 49.2, ymax = 49.8, res = 1 / 120,
                      crs = "EPSG:4326")
  r <- terra::rast(wet_terraclimate_aet(grid, vars = "aet", dir = dir))
  v <- terra::values(r, mat = FALSE)
  # west of -120 there is no source data within reach: NA, left for the caller
  x <- terra::xFromCell(r, seq_len(terra::ncell(r)))
  expect_true(all(is.na(v[x < -120 - 1 / 24])))
  # east of the edge every cell has a value, including those whose bilinear
  # neighbourhood reaches into the gap
  expect_false(anyNA(v[x > -120]))
  expect_equal(range(v[x > -120]), c(78, 78), tolerance = 1e-5)
})

test_that("a file without 12 layers is refused, and a cached grid is returned as is", {
  dir <- withr::local_tempdir()
  r <- terra::rast(nrows = 24, ncols = 48, xmin = -121, xmax = -119, ymin = 49, ymax = 50,
                   crs = "EPSG:4326", vals = 1)
  terra::writeRaster(r, file.path(dir, "TerraClimate_19812010_aet.nc"), filetype = "GTiff")
  grid <- terra::rast(xmin = -120.5, xmax = -119.5, ymin = 49.2, ymax = 49.8, res = 1 / 120,
                      crs = "EPSG:4326")
  expect_error(wet_terraclimate_aet(grid, vars = "aet", dir = dir), "12")
  unlink(file.path(dir, "TerraClimate_19812010_aet.nc"))
  local_tc(dir, "aet", 1)
  f <- wet_terraclimate_aet(grid, vars = "aet", dir = dir)
  local_mocked_bindings(wet_download = function(...) stop("downloaded"),
                        wet_terraclimate_grid = function(...) stop("rebuilt"))
  expect_equal(wet_terraclimate_aet(grid, vars = "aet", dir = dir), f)
})
