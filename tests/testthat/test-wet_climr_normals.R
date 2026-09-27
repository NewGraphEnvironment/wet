local_ts <- function(years) {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = -128, xmax = -126, ymin = 54, ymax = 56,
                   crs = "EPSG:4326")
  lyr <- list()
  for (y in years) for (v in c("PPT_01", "Tmax_01")) {
    x <- r
    terra::values(x) <- if (v == "PPT_01") y - 1980 else 2 * (y - 1980)
    names(x) <- sprintf("climatena_%s_%d", v, y)
    lyr[[length(lyr) + 1]] <- x
  }
  terra::rast(lyr)
}

test_that("anomalies are averaged per variable over the requested years only", {
  ts <- local_ts(1979:1983)
  m <- wet:::wet_climr_anomaly_mean(ts, "climatena", 1981:1983)
  expect_equal(names(m), c("PPT_01", "Tmax_01"))
  # PPT anomalies 1, 2, 3 -> 2; Tmax anomalies 2, 4, 6 -> 4
  expect_equal(unname(unlist(terra::global(m, "mean"))), c(2, 4))
})

test_that("a year missing from the series is an error, not a shorter mean", {
  ts <- local_ts(1981:1982)
  expect_error(wet:::wet_climr_anomaly_mean(ts, "climatena", 1981:1983), "1983")
})

test_that("a cached normal is returned without calling climr, keyed on its variables", {
  skip_if_not_installed("climr")
  dir <- withr::local_tempdir()
  dem <- terra::rast(xmin = -128, xmax = -127, ymin = 54, ymax = 55, res = 1 / 120,
                     crs = "EPSG:4326")
  terra::values(dem) <- 600
  key <- function(v, y = 1981:2010, d = dem) {
    substr(wet:::wet_md5_text(paste(c(paste(y, collapse = ","), v, wet:::wet_raster_md5(d)),
                                    collapse = "|")), 1, 8)
  }
  f <- file.path(dir, sprintf("climr_mswx.blend_1981-2010_%s_%s.tif",
                              substr(wet:::wet_grid_key(dem), 1, 8), key(c("PPT_07", "Tave_07"))))
  file.create(f)
  expect_equal(wet_climr_normals(dem, vars = c("PPT_07", "Tave_07"), dir = dir), f)
  # a different variable set is a different file, never the cached one
  expect_false(key(c("PPT_07", "Tave_07")) == key(c(sprintf("PPT_%02d", 1:12), sprintf("Tave_%02d", 1:12))))
  # and so is a different set of years with the same first and last year
  expect_false(key("PPT_07") == key("PPT_07", c(1981, 2010)))
  # and so are other elevations on the same grid
  dem2 <- dem
  terra::values(dem2) <- 900
  expect_false(key("PPT_07") == key("PPT_07", d = dem2))
})

test_that("variables that are not linear in the anomalies are refused", {
  expect_error(wet_climr_normals(terra::rast(), vars = c("PPT_07", "DD5")), "DD5")
  expect_error(wet_climr_normals(terra::rast(), vars = "PAS"), "PAS")
})

test_that("the gridded normal matches climr's per-year point average", {
  # Live: climr's remote database. Averaging anomalies before downscaling is
  # exact in principle; this pins it against climr's own route.
  skip_on_ci()
  skip_on_cran()
  skip_if_not_installed("climr")
  skip_if_offline()
  dem <- terra::rast(xmin = -127.3, xmax = -127.1, ymin = 54.7, ymax = 54.9, res = 1 / 120,
                     crs = "EPSG:4326")
  terra::values(dem) <- 600
  f <- wet_climr_normals(dem, vars = c("PPT_07", "Tave_07"), dir = withr::local_tempdir())
  x <- terra::rast(f)
  p <- terra::xyFromCell(x, terra::cellFromXY(x, cbind(-127.2, 54.8)))
  g <- terra::extract(x, p)
  pt <- suppressMessages(climr::downscale(
    data.frame(id = 1, lon = p[1], lat = p[2], elev = 600), which_refmap = "refmap_climr",
    obs_ts_dataset = "mswx.blend", obs_years = 1981:2010, vars = c("PPT_07", "Tave_07"),
    return_refperiod = FALSE
  ))
  pt <- as.data.frame(pt)
  expect_equal(g$PPT_07, mean(pt$PPT_07), tolerance = 0.005)
  expect_lt(abs(g$Tave_07 - mean(pt$Tave_07)), 0.05)
})

test_that("the value hash is the same for NA from memory and NaN from a file", {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 1, ymin = 0, ymax = 1, crs = "EPSG:4326")
  terra::values(r) <- c(1, NA, 3, 4)
  f <- withr::local_tempfile(fileext = ".tif")
  terra::writeRaster(r, f, datatype = "FLT4S")
  expect_equal(wet:::wet_raster_md5(r), wet:::wet_raster_md5(terra::rast(f)))
})
