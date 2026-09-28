# A source 10x finer than a 4 x 4 target grid in the same CRS, so each target
# cell holds exactly 100 source pixels and the fractions are exact counts.
local_lc_src <- function(m) {
  dir <- withr::local_tempdir(.local_envir = parent.frame())
  src <- terra::rast(nrows = 40, ncols = 40, xmin = 0, xmax = 4, ymin = 0, ymax = 4, crs = "EPSG:4326")
  terra::values(src) <- as.vector(t(m))  # row-major, top row first
  f <- file.path(dir, "lc.tif")
  terra::writeRaster(src, f, datatype = "INT1U", NAflag = 0)
  grid <- terra::rast(nrows = 4, ncols = 4, xmin = 0, xmax = 4, ymin = 0, ymax = 4, crs = "EPSG:4326")
  list(src = f, grid = grid, dir = dir)
}
tbl <- data.frame(class = c("coniferous", "grass", "water"), aet_mm = c(276, 275, 425),
                  nrcan_2020_codes = c("1;2", "10", "18"))
# independent oracle: the share of each 10 x 10 block whose code is in `codes`
block_share <- function(m, codes) {
  x <- terra::rast(nrows = 40, ncols = 40, xmin = 0, xmax = 4, ymin = 0, ymax = 4)
  terra::values(x) <- as.vector(t(m)) %in% codes
  terra::values(terra::aggregate(x, 10, mean), mat = FALSE)
}

test_that("each class layer is the share of source pixels whose code maps to it", {
  m <- matrix(1L, 40, 40)
  m[1:20, 21:40] <- 10L   # top-right quadrant: grass
  m[21:40, 1:10] <- 2L    # bottom-left quadrant: codes 2 and 1, both conifer
  m[21:30, 21:40] <- 18L  # bottom-right quadrant: water on top ...
  m[31:40, 21:40] <- 0L   # ... no data (outside Canada) below
  m[1:5, 1:10] <- 10L     # a half-grass cell inside the conifer quadrant
  x <- local_lc_src(m)
  fr <- terra::rast(wet:::wet_landcover_fractions(x$src, x$grid, tbl, file.path(x$dir, "out.tif")))
  expect_equal(names(fr), tbl$class)
  v <- terra::values(fr)
  expect_equal(unname(v[, "coniferous"]), block_share(m, c(1, 2)), tolerance = 1e-6)
  expect_equal(unname(v[, "grass"]), block_share(m, 10), tolerance = 1e-6)
  expect_equal(unname(v[, "water"]), block_share(m, 18), tolerance = 1e-6)
  # spot checks by hand: the half-grass cell, a grass cell, a no-data cell
  expect_equal(unname(v[1, c("coniferous", "grass")]), c(0.5, 0.5), tolerance = 1e-6)
  expect_equal(unname(v[4, "grass"]), 1, tolerance = 1e-6)
  expect_equal(unname(rowSums(v)[16]), 0, tolerance = 1e-6)
  # the no-data part counts as uncovered, not as a class and not as NA
  expect_false(anyNA(v))
})

test_that("a code no class claims counts as uncovered", {
  m <- matrix(1L, 40, 40)
  m[1:10, 1:10] <- 3L  # not in the table
  x <- local_lc_src(m)
  fr <- terra::rast(wet:::wet_landcover_fractions(x$src, x$grid, tbl, file.path(x$dir, "out.tif")))
  expect_equal(unname(terra::values(sum(fr), mat = FALSE)), c(0, rep(1, 15)), tolerance = 1e-6)
})

test_that("fractions follow the true cell footprint when the source CRS is rotated against the grid", {
  # NRCan's Lambert conformal (EPSG:3979, centred on -95) is rotated about 20
  # degrees against lon/lat at -125: a single average warp from there takes
  # each cell's footprint as an axis-aligned box in the source CRS and was off
  # by up to 0.3 on the real grid. Diagonal stripes make that error large.
  dir <- withr::local_tempdir()
  grid <- terra::rast(xmin = -125.05, xmax = -125, ymin = 58.5, ymax = 58.55, res = 1 / 120, crs = "EPSG:4326")
  bb <- terra::ext(terra::project(terra::as.polygons(terra::ext(grid) + 0.01, crs = "EPSG:4326"), "EPSG:3979"))
  src <- terra::rast(bb, res = 30, crs = "EPSG:3979")
  xy <- terra::crds(src, na.rm = FALSE)
  terra::values(src) <- ifelse(((xy[, 1] + xy[, 2]) %/% 240) %% 2 == 0, 1L, 10L)
  f <- file.path(dir, "lc.tif")
  terra::writeRaster(src, f, datatype = "INT1U", NAflag = 0)
  fr <- terra::rast(wet:::wet_landcover_fractions(f, grid, tbl, file.path(dir, "out.tif")))
  # oracle: exact-overlap share of conifer pixels in each cell's true footprint
  exact <- vapply(seq_len(terra::ncell(grid)), function(k) {
    x <- terra::xFromCell(grid, k)
    y <- terra::yFromCell(grid, k)
    p <- terra::as.polygons(terra::ext(x - 1 / 240, x + 1 / 240, y - 1 / 240, y + 1 / 240), crs = "EPSG:4326")
    v <- terra::extract(src, terra::project(terra::densify(p, 20), "EPSG:3979"), exact = TRUE)
    sum(v$fraction[v[[2]] == 1]) / sum(v$fraction)
  }, 1)
  expect_lt(max(abs(terra::values(fr[["coniferous"]], mat = FALSE) - exact)), 0.03)
})

test_that("a code claimed by two classes is refused", {
  bad <- tbl
  bad$nrcan_2020_codes[2] <- "2;10"
  x <- local_lc_src(matrix(1L, 40, 40))
  expect_error(wet:::wet_landcover_fractions(x$src, x$grid, bad, file.path(x$dir, "out.tif")), "2")
})

test_that("a cached fraction grid is returned without rebuilding, and a new source is not served old fractions", {
  dir <- withr::local_tempdir()
  m <- matrix(1L, 40, 40)
  x <- local_lc_src(m)
  src <- file.path(dir, "lc.tif")
  file.copy(x$src, src)
  withr::local_options(wet.nrcan_landcover_url = "https://example.invalid/lc.tif")
  local_mocked_bindings(wet_download = function(...) stop("downloaded"))
  f1 <- wet_landcover_nrcan(x$grid, tbl, dir = dir)
  expect_equal(unname(terra::values(terra::rast(f1)[["grass"]], mat = FALSE)), rep(0, 16), tolerance = 1e-6)
  local_mocked_bindings(wet_landcover_fractions = function(...) stop("rebuilt"))
  expect_equal(wet_landcover_nrcan(x$grid, tbl, dir = dir), f1)
  # a revised source file at the same path: new key, rebuilt, new content
  m[] <- 10L
  y <- local_lc_src(m)
  file.copy(y$src, src, overwrite = TRUE)
  expect_error(wet_landcover_nrcan(x$grid, tbl, dir = dir), "rebuilt")
})
