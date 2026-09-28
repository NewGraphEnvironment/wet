# Synthetic stand-ins for MOD16A3GF granules: a real sinusoidal tile's extent
# at a coarse resolution (600 x 600 pixels, about 1.85 km), carrying ET as
# terra reads the real HDF (already scaled, mm/yr), with fill codes as their
# scaled values (65530-65534 -> 6553.0-6553.4). GeoTIFFs at the granule's
# file name; the HDF reader is mocked to read them.
sinu <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs"
tile_ext <- function(h, v) {
  t <- 1111950.5197665233
  terra::ext(-20015109.354 + h * t, -20015109.354 + (h + 1) * t,
             10007554.677 - (v + 1) * t, 10007554.677 - v * t)
}
local_granule <- function(dir, tile, year, fun, ext = NULL, res = NULL) {
  hv <- as.integer(regmatches(tile, gregexpr("[0-9]+", tile))[[1]])
  r <- if (is.null(ext)) terra::rast(tile_ext(hv[1], hv[2]), nrows = 600, ncols = 600, crs = sinu) else
    terra::rast(ext, res = res, crs = sinu)
  x <- terra::crds(r, na.rm = FALSE)
  terra::values(r) <- fun(x[, 1], x[, 2])
  f <- file.path(dir, sprintf("MOD16A3GF.A%d001.%s.061.2021189012930.hdf", year, tile))
  terra::writeRaster(r, f, filetype = "GTiff", datatype = "FLT4S")
  f
}
# a 0.1-degree grid well inside h10v03 (50-60 N, about -140 to -109 at 50 N)
test_grid <- function() {
  terra::rast(xmin = -120, xmax = -119, ymin = 50.5, ymax = 51, res = 0.1, crs = "EPSG:4326")
}
# Reads the stand-ins, and makes any search or download an error: a tile the
# fixture forgot must fail the test, not fetch the real granule. Tests that
# exercise the download path mock both again afterwards.
fake_search <- function(grid, years) {
  data.frame(tile = "h10v03", year = years,
             url = sprintf("https://x/MOD16A3GF.A%d001.h10v03.061.2021189012930.hdf", years))
}
mock_read <- function() {
  testthat::local_mocked_bindings(wet_mod16_read = function(f) terra::rast(f),
                                  wet_mod16_search = function(...) stop("network search in a test"),
                                  wet_download = function(...) stop("network download in a test"),
                                  .env = parent.frame())
}

test_that("the tiles are the sinusoidal tiles the grid touches, not CMR's loose bbox match", {
  bc <- terra::rast(xmin = -139.1, xmax = -114, ymin = 48.2, ymax = 60.1, res = 0.1, crs = "EPSG:4326")
  # CMR also returns h08v03, h20v01 and h23v02 for this bbox; none touches it
  expect_equal(wet:::wet_modis_tiles(bc),
               c("h08v04", "h09v03", "h09v04", "h10v03", "h10v04", "h11v02", "h11v03", "h12v02", "h12v03"))
  expect_equal(wet:::wet_modis_tiles(test_grid()), "h10v03")
  # an edge on 60 or 50 N (a tile-row edge) does not pull in the row beyond it
  n60 <- terra::rast(xmin = -125, xmax = -115, ymin = 58, ymax = 60, res = 0.1, crs = "EPSG:4326")
  expect_equal(wet:::wet_modis_tiles(n60), c("h11v03", "h12v03"))
  n50 <- terra::rast(xmin = -120, xmax = -119, ymin = 49, ymax = 50, res = 0.1, crs = "EPSG:4326")
  expect_equal(wet:::wet_modis_tiles(n50), "h10v04")
})

# independent oracle: the tiles of a dense sample of points inside the extent
tiles_oracle <- function(g) {
  e <- as.vector(terra::ext(g))
  xy <- as.matrix(expand.grid(seq(e[1], e[2], length.out = 300), seq(e[3], e[4], length.out = 300)))
  s <- terra::crds(terra::project(terra::vect(xy, crs = "EPSG:4326"), sinu))
  sort(unique(sprintf("h%02dv%02d", floor((s[, 1] + 20015109.354) / 1111950.5197665233),
                      floor((10007554.677 - s[, 2]) / 1111950.5197665233))))
}

test_that("the extent's edges are parallels and meridians, not great circles", {
  # a raster's top edge is a parallel just under 50 N (the v03/v04 line); a
  # geodesic densify bows it about 0.03 degrees north and wrongly adds h10v03
  g <- terra::rast(xmin = -121.509837555, xmax = -116.059180047, ymin = 48.778168333, ymax = 50.011981482,
                   res = 0.1, crs = "EPSG:4326")
  expect_lt(terra::ymax(g), 50)
  expect_equal(wet:::wet_modis_tiles(g), c("h09v04", "h10v04"))
  expect_equal(wet:::wet_modis_tiles(g), tiles_oracle(g))
})

test_that("a constant field comes back exact, on the grid, with full cover", {
  dir <- withr::local_tempdir()
  for (y in 2001:2003) local_granule(dir, "h10v03", y, function(x, y) rep(500, length(x)))
  mock_read()
  g <- test_grid()
  r <- terra::rast(wet_mod16_aet(g, years = 2001:2003, dir = dir, min_years = 2))
  expect_equal(names(r), c("et_mod16", "frac_mod16"))
  expect_true(terra::compareGeom(r, g))
  v <- terra::values(r)
  expect_equal(range(v[, "et_mod16"]), c(500, 500), tolerance = 1e-6)
  expect_equal(range(v[, "frac_mod16"]), c(1, 1))
})

test_that("years are averaged per pixel, and a pixel needs min_years valid years", {
  dir <- withr::local_tempdir()
  # 400, 500, 600 by year; west of -119.5 only 2001 is valid (then snow/ice)
  lon <- function(x, y) terra::crds(terra::project(terra::vect(cbind(x, y), crs = sinu), "EPSG:4326"))[, 1]
  for (i in 1:3) {
    local_granule(dir, "h10v03", 2000 + i, function(x, y) {
      v <- rep(300 + 100 * i, length(x))
      if (i > 1) v[lon(x, y) < -119.5] <- 6553.2
      v
    })
  }
  mock_read()
  g <- test_grid()
  r <- terra::rast(wet_mod16_aet(g, years = 2001:2003, dir = dir, min_years = 2))
  x <- terra::xFromCell(g, seq_len(terra::ncell(g)))
  v <- terra::values(r)
  # cells next to -119.5 may take a sub-cell from across it (nearest): skip them
  east <- x > -119.4
  west <- x < -119.6
  expect_equal(range(v[east, "et_mod16"]), c(500, 500), tolerance = 1e-6)
  expect_true(all(is.na(v[west, "et_mod16"])))
  expect_equal(unique(v[west, "frac_mod16"]), 0)
  # with min_years = 1 the western pixels keep their one valid year
  r1 <- terra::rast(wet_mod16_aet(g, years = 2001:2003, dir = dir, min_years = 1))
  expect_equal(range(terra::values(r1)[west, "et_mod16"]), c(400, 400), tolerance = 1e-6)
})

test_that("every fill code is a gap, and a cell at a gap edge keeps the mean of its valid part", {
  dir <- withr::local_tempdir()
  codes <- c(6552.9, 6553.0, 6553.1, 6553.2, 6553.3, 6553.4)  # 65529-65534
  # fill codes in a north-south band; valid ET 450 elsewhere
  for (y in 2001:2002) {
    local_granule(dir, "h10v03", y, function(x, y) {
      v <- rep(450, length(x))
      band <- y > 5620000 & y < 5640000
      v[band] <- rep_len(codes, sum(band))
      v
    })
  }
  mock_read()
  g <- test_grid()
  r <- terra::rast(wet_mod16_aet(g, years = 2001:2002, dir = dir, min_years = 1))
  v <- terra::values(r)
  fr <- v[, "frac_mod16"]
  expect_true(all(fr >= 0 & fr <= 1))
  expect_true(any(fr > 0 & fr < 1))  # the band cuts through cells
  # valid ET is 450 wherever a cell has any cover: gaps never drag the mean
  expect_equal(range(v[fr > 0, "et_mod16"]), c(450, 450), tolerance = 1e-6)
  expect_true(all(is.na(v[fr == 0, "et_mod16"])))
})

test_that("two tiles meet without a seam", {
  dir <- withr::local_tempdir()
  local_granule(dir, "h10v03", 2001, function(x, y) rep(400, length(x)))
  local_granule(dir, "h11v03", 2001, function(x, y) rep(600, length(x)))
  mock_read()
  # the h10/h11 line runs from -122.04 at 55 N to -123.58 at 55.5 N
  g <- terra::rast(xmin = -125, xmax = -121, ymin = 55, ymax = 55.5, res = 0.1, crs = "EPSG:4326")
  expect_equal(wet:::wet_modis_tiles(g), c("h10v03", "h11v03"))
  r <- terra::rast(wet_mod16_aet(g, years = 2001, dir = dir, min_years = 1))
  v <- terra::values(r)
  x <- terra::xFromCell(g, seq_len(terra::ncell(g)))
  expect_equal(range(v[, "frac_mod16"]), c(1, 1))
  expect_equal(range(v[x < -123.7, "et_mod16"]), c(400, 400), tolerance = 1e-6)
  expect_equal(range(v[x > -121.9, "et_mod16"]), c(600, 600), tolerance = 1e-6)
  expect_true(any(v[, "et_mod16"] > 400 & v[, "et_mod16"] < 600))
})

test_that("cover follows the true footprint where sinusoidal is sheared against lon/lat", {
  # A gap stripe 10 km wide along a sinusoidal meridian (x constant) near -130.5,
  # 57 N, on a grid inside h10v03 (h11 starts at about -129.3 at 57.2 N). There
  # a lon/lat meridian slopes about 1.9 in x per y in sinusoidal,
  # so the stripe crosses the grid diagonally, and a one-step average warp
  # (each cell's footprint taken as a box in the source CRS) smears it.
  dir <- withr::local_tempdir()
  g <- terra::rast(xmin = -131.5, xmax = -129.5, ymin = 56.8, ymax = 57.2, res = 0.1, crs = "EPSG:4326")
  expect_equal(wet:::wet_modis_tiles(g), "h10v03")
  xc <- terra::crds(terra::project(terra::vect(cbind(-130.5, 57), crs = "EPSG:4326"), sinu))[1, 1]
  bb <- terra::ext(terra::project(terra::as.polygons(terra::ext(g), crs = "EPSG:4326"), sinu)) + 20000
  local_granule(dir, "h10v03", 2001, function(x, y) ifelse(abs(x - xc) < 5000, 6553.2, 450), ext = bb, res = 250)
  mock_read()
  r <- terra::rast(wet_mod16_aet(g, years = 2001, dir = dir, min_years = 1, fact = 20))
  # oracle: exact share of each cell outside the stripe, by polygon overlap
  stripe <- terra::as.polygons(terra::ext(xc - 5000, xc + 5000, bb$ymin, bb$ymax), crs = sinu)
  stripe <- terra::project(terra::densify(stripe, 100, flat = TRUE), "EPSG:4326")
  cells <- terra::as.polygons(terra::init(g, "cell"), aggregate = FALSE)
  names(cells) <- "cell"
  cut <- terra::intersect(cells, stripe)
  gap <- numeric(terra::ncell(g))
  gap[cut$cell] <- terra::expanse(cut) / terra::expanse(cells)[cut$cell]
  expect_gt(max(gap), 0.4)  # the stripe does cut cells deeply
  expect_lt(max(abs(terra::values(r)[, "frac_mod16"] - (1 - gap))), 0.05)
})

test_that("a download that is not a granule is deleted and refused", {
  dir <- withr::local_tempdir()
  netrc <- file.path(dir, "netrc")
  writeLines("machine urs.earthdata.nasa.gov login a password b", netrc)
  withr::local_options(wet.earthdata_netrc = netrc)
  mock_read()
  html <- function(url, dest, timeout, netrc = NULL) writeLines("<html>Earthdata Login</html>", dest)
  local_mocked_bindings(wet_mod16_search = fake_search, wet_download = html)
  expect_error(wet_mod16_aet(test_grid(), years = 2001, dir = dir, min_years = 1), "not a readable")
  expect_length(list.files(dir, "hdf$"), 0)
})

test_that("an implausible ET after masking stops the build", {
  dir <- withr::local_tempdir()
  local_granule(dir, "h10v03", 2001, function(x, y) rep(5000, length(x)))
  mock_read()
  expect_error(wet_mod16_aet(test_grid(), years = 2001, dir = dir, min_years = 1), "5000 mm/yr")
})

test_that("a projected grid is refused before any tile search", {
  mock_read()
  g <- terra::rast(xmin = 1.2e6, xmax = 1.25e6, ymin = 5e5, ymax = 5.5e5, res = 1000, crs = "EPSG:3005")
  expect_error(wet_mod16_aet(g, years = 2001, dir = withr::local_tempdir(), min_years = 1), "lon/lat")
})

test_that("a missing or duplicated tile-year is refused", {
  gr <- data.frame(tile = c("h10v03", "h10v03", "h10v04"), year = c(2001L, 2002L, 2001L), url = "u")
  expect_error(wet:::wet_mod16_check(gr, c("h10v03", "h10v04"), 2001:2002), "h10v04 2002")
  gr2 <- rbind(gr, data.frame(tile = "h10v04", year = 2002L, url = "u"), gr[1, ])
  expect_error(wet:::wet_mod16_check(gr2, c("h10v03", "h10v04"), 2001:2002), "more than one")
  expect_silent(wet:::wet_mod16_check(gr2[-5, ], c("h10v03", "h10v04"), 2001:2002))
})

test_that("a cached grid comes back without a search, a download or a rebuild", {
  dir <- withr::local_tempdir()
  for (y in 2001:2002) local_granule(dir, "h10v03", y, function(x, y) rep(500, length(x)))
  mock_read()
  g <- test_grid()
  f <- wet_mod16_aet(g, years = 2001:2002, dir = dir, min_years = 1)
  local_mocked_bindings(wet_mod16_search = function(...) stop("searched"),
                        wet_download = function(...) stop("downloaded"),
                        wet_mod16_grid = function(...) stop("rebuilt"))
  expect_equal(wet_mod16_aet(g, years = 2001:2002, dir = dir, min_years = 1), f)
  # a different min_years is a different grid, so it is not served from cache
  expect_error(wet_mod16_aet(g, years = 2001:2002, dir = dir, min_years = 2), "rebuilt")
})

test_that("a missing granule is searched for and downloaded with the netrc", {
  dir <- withr::local_tempdir()
  local_granule(dir, "h10v03", 2001, function(x, y) rep(500, length(x)))
  netrc <- file.path(dir, "netrc")
  writeLines("machine urs.earthdata.nasa.gov login a password b", netrc)
  withr::local_options(wet.earthdata_netrc = netrc)
  mock_read()
  src <- file.path(dir, "src.tif")
  local_granule(dir, "h10v03", 2002, function(x, y) rep(600, length(x)))
  file.rename(list.files(dir, "A2002001", full.names = TRUE), src)
  got <- character()
  fake_download <- function(url, dest, timeout, netrc = NULL) {
    got <<- c(got, netrc)
    file.copy(src, dest)
  }
  local_mocked_bindings(wet_mod16_search = fake_search, wet_download = fake_download)
  r <- terra::rast(wet_mod16_aet(test_grid(), years = 2001:2002, dir = dir, min_years = 1))
  expect_equal(got, netrc)  # one download, 2002 only, with the netrc
  expect_equal(range(terra::values(r)[, "et_mod16"]), c(550, 550), tolerance = 1e-6)
})

test_that("a netrc without an Earthdata entry is refused before any download", {
  dir <- withr::local_tempdir()
  netrc <- file.path(dir, "netrc")
  writeLines("machine example.org login a password b", netrc)
  withr::local_options(wet.earthdata_netrc = netrc)
  expect_error(wet:::wet_earthdata_netrc(), "urs.earthdata.nasa.gov")
  withr::local_options(wet.earthdata_netrc = file.path(dir, "absent"))
  expect_error(wet:::wet_earthdata_netrc(), "absent")
})
