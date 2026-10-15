# Synthetic stand-in for one of cd's annual snow layers: one band per year,
# named for the year, on a 0.1-degree lattice. Band for year y holds y - 1980
# everywhere (so the 1981-2010 mean is 15.5), except `na_cols`, which are
# 'sea' in every year.
local_snow <- function(dir, var, years = 1975:2012, na_cols = integer(), scale = 1) {
  r <- terra::rast(nrows = 10, ncols = 20, xmin = -121, xmax = -119, ymin = 49, ymax = 50,
                   crs = "EPSG:4326", nlyrs = length(years))
  for (i in seq_along(years)) {
    v <- rep(scale * (years[i] - 1980), terra::ncell(r))
    v[((seq_len(terra::ncell(r)) - 1) %% 20 + 1) %in% na_cols] <- NA
    terra::values(r[[i]]) <- v
  }
  names(r) <- years
  f <- file.path(dir, sprintf("%s_annual.tif", var))
  terra::writeRaster(r, f)
  f
}
snow_catalog <- function(files) {
  data.frame(variable = names(files), period = "annual", href = unname(files))
}
snow_grid <- function() {
  terra::rast(xmin = -120.5, xmax = -119.5, ymin = 49.2, ymax = 49.8, res = 1 / 120, crs = "EPSG:4326")
}

test_that("each variable is its mean over exactly `years`, resampled onto the grid", {
  dir <- withr::local_tempdir()
  cat <- snow_catalog(c(snowmelt_doy_50 = local_snow(dir, "snowmelt_doy_50"),
                        swe_max = local_snow(dir, "swe_max", scale = 10)))
  f <- wet_snow_normals(snow_grid(), dir = dir, catalog = cat)
  r <- terra::rast(f)
  expect_equal(names(r), c("snowmelt_doy_50", "swe_max"))
  expect_true(terra::compareGeom(r, snow_grid()))
  # 1981:2010 -> mean(1:30) = 15.5; 1975-1980, 2011 and 2012 (mean 13.5 with them) are left out
  expect_equal(unname(unlist(terra::global(r, "min"))), c(15.5, 155), tolerance = 1e-6)
  expect_equal(unname(unlist(terra::global(r, "max"))), c(15.5, 155), tolerance = 1e-6)
  r2 <- terra::rast(wet_snow_normals(snow_grid(), years = 1991:2000, dir = dir, catalog = cat))
  expect_equal(unname(unlist(terra::global(r2, "max"))), c(15.5, 155), tolerance = 1e-6)
  r3 <- terra::rast(wet_snow_normals(snow_grid(), "swe_max", years = 2001:2010, dir = dir, catalog = cat))
  expect_equal(names(r3), "swe_max")
  expect_equal(unname(unlist(terra::global(r3, "max"))), 255, tolerance = 1e-6)
})

test_that("a year with no band stops, and so does a variable the catalog lacks", {
  dir <- withr::local_tempdir()
  cat <- snow_catalog(c(swe_max = local_snow(dir, "swe_max", years = c(1981:1990, 1992:2010))))
  expect_error(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat), "no band for 1 of the years: 1991")
  expect_error(wet_snow_normals(snow_grid(), "snowmelt_doy_50", dir = dir, catalog = cat),
               "0 annual rows for snowmelt_doy_50")
  cat2 <- rbind(cat, cat)
  expect_error(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat2), "2 annual rows")
  expect_error(wet_snow_normals(snow_grid(), "swe_max", years = c(1981, 1981), dir = dir, catalog = cat),
               "distinct years")
})

test_that("cells over source 'sea' are NA, and their neighbours are reweighted", {
  dir <- withr::local_tempdir()
  # source columns 1-8 (west of -120.2) are sea
  cat <- snow_catalog(c(swe_max = local_snow(dir, "swe_max", na_cols = 1:8)))
  r <- terra::rast(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat))
  x <- terra::xFromCol(r, seq_len(terra::ncol(r)))
  v <- terra::values(r, mat = FALSE)
  col <- rep(seq_len(terra::ncol(r)), terra::nrow(r))
  expect_true(all(is.na(v[x[col] < -120.2])))
  expect_true(all(abs(v[x[col] > -120.2] - 15.5) < 1e-6))
})

test_that("the cache is reused, and a changed source, period or grid makes a new file", {
  dir <- withr::local_tempdir()
  src <- withr::local_tempdir()
  cat <- snow_catalog(c(swe_max = local_snow(src, "swe_max")))
  f1 <- wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat)
  t1 <- file.mtime(f1)
  expect_identical(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat), f1)
  expect_identical(file.mtime(f1), t1)
  expect_false(identical(wet_snow_normals(snow_grid(), "swe_max", years = 1982:2010, dir = dir, catalog = cat), f1))
  g2 <- terra::rast(xmin = -120.5, xmax = -119.5, ymin = 49.2, ymax = 49.7, res = 1 / 120, crs = "EPSG:4326")
  expect_false(identical(wet_snow_normals(g2, "swe_max", dir = dir, catalog = cat), f1))
  unlink(cat$href)
  local_snow(src, "swe_max", scale = 2)
  f4 <- wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat)
  expect_false(identical(f4, f1))
  expect_equal(unname(unlist(terra::global(terra::rast(f4), "max"))), 31, tolerance = 1e-6)
})

test_that("a source in another CRS stops", {
  dir <- withr::local_tempdir()
  f <- local_snow(dir, "swe_max")
  r <- terra::rast(f)
  r <- terra::project(r, "EPSG:3005")
  f2 <- file.path(dir, "swe_max_3005.tif")
  terra::writeRaster(r, f2)
  cat <- snow_catalog(c(swe_max = f2))
  expect_error(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat), "not in the grid's CRS")
})

test_that("cap limits a variable's mean before resampling, and only the named variable", {
  dir <- withr::local_tempdir()
  cat <- snow_catalog(c(snowmelt_doy_50 = local_snow(dir, "snowmelt_doy_50"),
                        swe_max = local_snow(dir, "swe_max", scale = 1000)))
  # means: doy 15.5, swe_max 15,500 -> capped at 3,000 by default
  r <- terra::rast(wet_snow_normals(snow_grid(), dir = dir, catalog = cat))
  expect_equal(unname(unlist(terra::global(r, "max"))), c(15.5, 3000), tolerance = 1e-6)
  r2 <- terra::rast(wet_snow_normals(snow_grid(), dir = dir, catalog = cat, cap = c(swe_max = 20000)))
  expect_equal(unname(unlist(terra::global(r2, "max"))), c(15.5, 15500), tolerance = 1e-6)
  r3 <- terra::rast(wet_snow_normals(snow_grid(), dir = dir, catalog = cat, cap = c(snowmelt_doy_50 = 10)))
  expect_equal(unname(unlist(terra::global(r3, "max"))), c(10, 15500), tolerance = 1e-6)
  expect_error(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat, cap = c(snowmelt_doy_50 = 1)),
               "cap must name")
  expect_error(wet_snow_normals(snow_grid(), dir = dir, catalog = cat, cap = 3000), "cap must name")
})

test_that("the key follows the values read, not the file's bytes", {
  dir <- withr::local_tempdir()
  src <- withr::local_tempdir()
  cat <- snow_catalog(c(swe_max = local_snow(src, "swe_max")))
  f1 <- wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = cat)
  # the same values rewritten with other metadata (a cd rebuild): same file
  r <- terra::rast(cat$href)
  terra::metags(r) <- c(CD_RUN_TIME = "2099-01-01T00:00:00Z")
  f2 <- file.path(src, "swe_max_rebuilt.tif")
  terra::writeRaster(r, f2)
  expect_false(identical(unname(tools::md5sum(f2)), unname(tools::md5sum(cat$href))))
  expect_identical(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = snow_catalog(c(swe_max = f2))), f1)
  # a year appended outside `years` changes nothing either
  f3 <- local_snow(withr::local_tempdir(), "swe_max", years = 1975:2013)
  expect_identical(wet_snow_normals(snow_grid(), "swe_max", dir = dir, catalog = snow_catalog(c(swe_max = f3))), f1)
})
