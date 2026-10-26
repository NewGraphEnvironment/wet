# Synthetic stand-in for one of cd's annual snow layers on a 0.1-degree lattice
# (10 rows, 20 columns, x -121..-119, y 49..50): the band for year y holds
# scale * (y - 1980 + column), so values vary across cells and years.
# `na_cols` are 'sea' in every year; `na_cell` is list(year, row, col) cells
# missing in one year only.
local_snow_cells <- function(dir, var, years = 1975:2012, scale = 1, na_cols = integer(), na_cell = list()) {
  r <- terra::rast(nrows = 10, ncols = 20, xmin = -121, xmax = -119, ymin = 49, ymax = 50,
                   crs = "EPSG:4326", nlyrs = length(years))
  col <- (seq_len(terra::ncell(r)) - 1) %% 20 + 1
  row <- (seq_len(terra::ncell(r)) - 1) %/% 20 + 1
  for (i in seq_along(years)) {
    v <- scale * (years[i] - 1980 + col)
    v[col %in% na_cols] <- NA
    for (k in na_cell) if (k[[1]] == years[i]) v[row == k[[2]] & col == k[[3]]] <- NA
    terra::values(r[[i]]) <- v
  }
  names(r) <- years
  f <- file.path(dir, sprintf("%s_annual.tif", var))
  terra::writeRaster(r, f)
  f
}
snow_cat <- function(files) data.frame(variable = names(files), period = "annual", href = unname(files))
# a polygon over whole cells: columns c1..c2, rows r1..r2 (row 1 at the top)
cells_poly <- function(c1, c2, r1, r2) {
  x0 <- -121 + (c1 - 1) * 0.1
  x1 <- -121 + c2 * 0.1
  y0 <- 50 - r2 * 0.1
  y1 <- 50 - (r1 - 1) * 0.1
  terra::vect(sprintf("POLYGON ((%.10f %.10f, %.10f %.10f, %.10f %.10f, %.10f %.10f, %.10f %.10f))",
                      x0, y0, x1, y0, x1, y1, x0, y1, x0, y0), crs = "EPSG:4326")
}

test_that("one row per band year, each the exact area-weighted value", {
  dir <- withr::local_tempdir()
  cat <- snow_cat(c(snowmelt_doy_50 = local_snow_cells(dir, "snowmelt_doy_50"),
                    swe_max = local_snow_cells(dir, "swe_max", scale = 10)))
  s <- wet_snow_annual(cells_poly(3, 4, 2, 3), catalog = cat, cap = NULL)
  expect_equal(names(s), c("year", "snowmelt_doy_50", "swe_max", "cover"))
  expect_identical(s$year, 1975:2012)
  # columns 3 and 4 in equal parts: mean column 3.5
  expect_equal(s$snowmelt_doy_50, 1975:2012 - 1980 + 3.5)
  expect_equal(s$swe_max, 10 * (1975:2012 - 1980 + 3.5))
  expect_equal(s$cover, rep(1, 38))
  # a polygon over three quarters of column 3 (x -120.775..-120.7) and all of column 4
  p <- terra::vect("POLYGON ((-120.775 49.7, -120.6 49.7, -120.6 49.8, -120.775 49.8, -120.775 49.7))",
                   crs = "EPSG:4326")
  s2 <- wet_snow_annual(p, "snowmelt_doy_50", catalog = cat)
  expect_equal(s2$snowmelt_doy_50, 1975:2012 - 1980 + (0.75 * 3 + 1 * 4) / 1.75)
})

test_that("`years` subsets and orders; a year with no band stops", {
  dir <- withr::local_tempdir()
  cat <- snow_cat(c(swe_max = local_snow_cells(dir, "swe_max", years = c(1981:1990, 1992:2010)),
                    snowmelt_doy_50 = local_snow_cells(dir, "snowmelt_doy_50", years = 1981:2010)))
  s <- wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = c(1995, 1983), catalog = cat)
  expect_identical(s$year, c(1983L, 1995L))
  expect_equal(s$swe_max, c(3, 15) + 3.5)
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = 1990:1992, catalog = cat),
               "no band for 1 of the years: 1991")
  # NULL: the first variable's years, which every other variable must have
  expect_identical(wet_snow_annual(cells_poly(3, 4, 2, 3), c("swe_max", "snowmelt_doy_50"), catalog = cat)$year,
                   c(1981:1990, 1992:2010))
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), c("snowmelt_doy_50", "swe_max"), catalog = cat),
               "swe_max has no band for 1 of the years: 1991")
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = c(1983, 1983), catalog = cat),
               "distinct whole years")
  # years are checked after coercion, so nothing is dropped or truncated silently
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = c("1990", "x"), catalog = cat),
               "distinct whole years")
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = 1990.7, catalog = cat),
               "distinct whole years")
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = c("1990", "1990.0"), catalog = cat),
               "distinct whole years")
  expect_identical(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = "1990", catalog = cat)$year, 1990L)
})

test_that("cap limits each cell in each year, and only the named variable", {
  dir <- withr::local_tempdir()
  cat <- snow_cat(c(swe_max = local_snow_cells(dir, "swe_max", scale = 100),
                    snowmelt_doy_50 = local_snow_cells(dir, "snowmelt_doy_50", scale = 100)))
  s <- wet_snow_annual(cells_poly(3, 4, 2, 3), c("swe_max", "snowmelt_doy_50"), catalog = cat,
                       cap = c(swe_max = 3000))
  raw <- vapply(1975:2012, function(y) mean(100 * (y - 1980 + 3:4)), 0)
  capped <- vapply(1975:2012, function(y) mean(pmin(100 * (y - 1980 + 3:4), 3000)), 0)
  expect_equal(s$swe_max, capped)
  expect_equal(s$snowmelt_doy_50, raw)
  # 2007: one cell at the cap and one over it, so a cap on the mean (3,050) would not bind
  expect_equal(s$swe_max[s$year == 2007], 3000)
  expect_gt(sum(capped != raw), 0)
  expect_error(wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", catalog = cat, cap = c(snowmelt_doy_50 = 1)),
               "cap must name variables in vars")
})

test_that("a watershed half over the sea reports cover 0.5 and the land value", {
  dir <- withr::local_tempdir()
  cat <- snow_cat(c(swe_max = local_snow_cells(dir, "swe_max", na_cols = 1:2)))
  s <- wet_snow_annual(cells_poly(2, 3, 2, 3), "swe_max", catalog = cat)
  expect_equal(s$swe_max, 1975:2012 - 1980 + 3)
  expect_equal(s$cover, rep(0.5, 38))
  # wholly off the grid: no value, cover 0
  far <- terra::vect("POLYGON ((-100 40, -99 40, -99 41, -100 41, -100 40))", crs = "EPSG:4326")
  s0 <- wet_snow_annual(far, "swe_max", catalog = cat)
  expect_true(all(is.na(s0$swe_max)))
  expect_equal(s0$cover, rep(0, 38))
})

test_that("fundamental watersheds and their union give identical results, overlaps counted once", {
  dir <- withr::local_tempdir()
  cat <- snow_cat(c(snowmelt_doy_50 = local_snow_cells(dir, "snowmelt_doy_50"),
                    swe_max = local_snow_cells(dir, "swe_max", scale = 10)))
  # columns 3-5, rows 2-4, cut into a rectangle and two triangles with edges off the cell lines
  wkt <- c("POLYGON ((-120.8 49.6, -120.73 49.6, -120.73 49.9, -120.8 49.9, -120.8 49.6))",
           "POLYGON ((-120.73 49.6, -120.5 49.6, -120.73 49.9, -120.73 49.6))",
           "POLYGON ((-120.5 49.6, -120.5 49.9, -120.73 49.9, -120.5 49.6))")
  fund <- terra::vect(wkt, crs = "EPSG:4326")
  fund$watershed_feature_id <- 1:3
  union <- terra::aggregate(fund)
  a <- wet_snow_annual(fund, catalog = cat)
  b <- wet_snow_annual(union, catalog = cat)
  expect_identical(a, b)
  # terra's exact coverage fractions carry about 1e-6 on a diagonal edge
  expect_equal(a$snowmelt_doy_50, 1975:2012 - 1980 + 4, tolerance = 1e-5)
  # a nested polygon adds nothing
  expect_identical(wet_snow_annual(rbind(fund, fund[2]), catalog = cat), a)
})

test_that("a cell missing in one year moves every year's value, and cover is one number", {
  dir <- withr::local_tempdir()
  cat <- snow_cat(c(swe_max = local_snow_cells(dir, "swe_max", na_cell = list(list(1990, 2, 4)))))
  s <- wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", catalog = cat)
  # cells (2,3), (3,3), (3,4) in every year: mean column 10 / 3
  expect_equal(s$swe_max, 1975:2012 - 1980 + 10 / 3)
  expect_equal(s$cover, rep(0.75, 38))
  # without 1990, the cell counts again
  s2 <- wet_snow_annual(cells_poly(3, 4, 2, 3), "swe_max", years = 1991:2000, catalog = cat)
  expect_equal(s2$swe_max, 1991:2000 - 1980 + 3.5)
  expect_equal(s2$cover, rep(1, 10))
})

test_that("bad inputs stop", {
  dir <- withr::local_tempdir()
  f <- local_snow_cells(dir, "swe_max")
  cat <- snow_cat(c(swe_max = f))
  p <- cells_poly(3, 4, 2, 3)
  expect_error(wet_snow_annual(p, "snowmelt_doy_50", catalog = cat), "0 annual rows for snowmelt_doy_50")
  expect_error(wet_snow_annual(p, "swe_max", catalog = rbind(cat, cat)), "2 annual rows")
  expect_error(wet_snow_annual(p, c("swe_max", "swe_max"), catalog = cat), "distinct cd variable names")
  expect_error(wet_snow_annual(terra::centroids(p), "swe_max", catalog = cat), "SpatVector of one or more polygons")
  expect_error(wet_snow_annual(sf::st_as_sf(p), "swe_max", catalog = cat), "SpatVector of one or more polygons")
  no_crs <- p
  terra::crs(no_crs) <- ""
  expect_error(wet_snow_annual(no_crs, "swe_max", catalog = cat), "ws has no CRS")
  expect_error(wet_snow_annual(p, "swe_max", catalog = snow_cat(c(swe_max = file.path(dir, "nope.tif")))),
               "missing: ")
  # bands not named by year
  r <- terra::rast(f)
  names(r) <- paste0("b", seq_len(terra::nlyr(r)))
  g <- file.path(dir, "unnamed.tif")
  terra::writeRaster(r, g)
  expect_error(wet_snow_annual(p, "swe_max", catalog = snow_cat(c(swe_max = g))), "not named by year")
  # a second variable on another grid
  r2 <- terra::rast(f)
  r2 <- terra::aggregate(r2, 2)
  h <- file.path(dir, "coarse.tif")
  terra::writeRaster(r2, h)
  expect_error(wet_snow_annual(p, c("swe_max", "snowmelt_doy_50"),
                               catalog = snow_cat(c(swe_max = f, snowmelt_doy_50 = h))),
               "snowmelt_doy_50 is not on swe_max's grid")
})

test_that("the bundled pilot data give every year 1950-2025 at full cover, inside cd's ranges", {
  d <- system.file("extdata", "snow_pilot", package = "wet")
  skip_if(!nzchar(d), "bundled pilot data not installed")
  outline <- readRDS(file.path(d, "maxan_outline.rds"))
  expect_identical(outline$station_number, "08EE018")
  ws <- terra::vect(outline$wkt, crs = outline$crs)
  expect_equal(sum(terra::expanse(ws)) / 1e6, 364, tolerance = 1e-3)
  cat <- utils::read.csv(file.path(d, "catalog.csv"))
  cat$href <- file.path(d, cat$href)
  s <- wet_snow_annual(ws, c("swe_max", "snowmelt_doy_50", "snowmelt_rate_peak"), catalog = cat)
  expect_identical(s$year, 1950:2025)
  expect_true(all(s$cover == 1))
  expect_true(all(s$swe_max > 0 & s$swe_max <= 3000))
  expect_true(all(s$snowmelt_doy_50 >= 1 & s$snowmelt_doy_50 <= 366))
  expect_true(all(s$snowmelt_rate_peak > 0))
})
