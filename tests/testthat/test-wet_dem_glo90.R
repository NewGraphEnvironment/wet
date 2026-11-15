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

# The DEM's cache name for a template grid and its tiles' ETags.
glo90_name <- function(tmpl, tiles, etag, method = wet:::wet_dem_method) {
  key <- wet:::wet_md5_text(paste(c(wet:::wet_grid_key(tmpl), method,
                                    sort(paste(tiles, etag), method = "radix")), collapse = "|"))
  sprintf("glo90_%s.tif", substr(key, 1, 10))
}

glo90_tmpl <- function() {
  terra::rast(xmin = -128, xmax = -127, ymin = 54, ymax = 55, res = 1 / 120, crs = "EPSG:4326")
}

# The bucket stands in by mocks (an unreachable host behind them), and the
# build itself by an error at its first step, so a test can tell a cache hit
# from a rebuild with no network.
local_glo90_bucket <- function(etag, env = parent.frame()) {
  withr::local_options(wet.glo90_base = "http://127.0.0.1:9", .local_envir = env)
  testthat::local_mocked_bindings(
    wet_glo90_tiles = function(base, bbox) "Copernicus_DSM_COG_30_N54_00_W128_00_DEM",
    wet_glo90_etags = function(base, tiles) etag,
    wet_gdal_config_set = function(x) stop("rebuilding the DEM"),
    .env = env
  )
}

test_that("a cached DEM whose tiles' ETags match is returned", {
  dir <- withr::local_tempdir()
  tmpl <- glo90_tmpl()
  local_glo90_bucket("\"aaa\"")
  f <- file.path(dir, glo90_name(tmpl, "Copernicus_DSM_COG_30_N54_00_W128_00_DEM", "\"aaa\""))
  file.create(f)
  expect_equal(wet_dem_glo90(tmpl, dir = dir), f)
})

test_that("a tile with another ETag gives another DEM path, so the DEM is rebuilt", {
  dir <- withr::local_tempdir()
  tmpl <- glo90_tmpl()
  file.create(file.path(dir, glo90_name(tmpl, "Copernicus_DSM_COG_30_N54_00_W128_00_DEM", "\"aaa\"")))
  local_glo90_bucket("\"bbb\"")
  expect_error(wet_dem_glo90(tmpl, dir = dir), "rebuilding the DEM")
})

test_that("a cached DEM still reads the tiles' ETags, so an unreachable bucket stops the call", {
  dir <- withr::local_tempdir()
  tmpl <- glo90_tmpl()
  # every name the DEM has had, the current one under any ETag included
  file.create(file.path(dir, glo90_name(tmpl, "Copernicus_DSM_COG_30_N54_00_W128_00_DEM", "\"aaa\"")))
  key <- wet:::wet_md5_text(paste(c(wet:::wet_grid_key(tmpl), wet:::wet_dem_method), collapse = "|"))
  file.create(file.path(dir, sprintf("glo90_%s.tif", substr(key, 1, 10))))  # before #23
  withr::local_options(wet.glo90_base = "http://127.0.0.1:9")
  expect_error(wet_dem_glo90(tmpl, dir = dir), "127.0.0.1")
})

test_that("a DEM cached under another builder method is rebuilt, not returned", {
  dir <- withr::local_tempdir()
  tmpl <- glo90_tmpl()
  # the name the DEM had before its builder's method was in the key (#19)
  file.create(file.path(dir, sprintf("glo90v3_%s.tif", substr(wet:::wet_grid_key(tmpl), 1, 12))))
  file.create(file.path(dir, glo90_name(tmpl, "Copernicus_DSM_COG_30_N54_00_W128_00_DEM", "\"aaa\"",
                                        method = "superseded")))
  local_glo90_bucket("\"aaa\"")
  expect_error(wet_dem_glo90(tmpl, dir = dir), "rebuilding the DEM")
})

test_that("ETags enter the key in a fixed order, whatever order the tiles come in", {
  dir <- withr::local_tempdir()
  tmpl <- glo90_tmpl()
  tiles <- c("Copernicus_DSM_COG_30_N54_00_W128_00_DEM", "Copernicus_DSM_COG_30_N55_00_W128_00_DEM")
  f <- file.path(dir, glo90_name(tmpl, tiles, c("\"a\"", "\"b\"")))
  file.create(f)
  withr::local_options(wet.glo90_base = "http://127.0.0.1:9")
  local_mocked_bindings(wet_glo90_tiles = function(base, bbox) rev(tiles),
                        wet_glo90_etags = function(base, tiles) c("\"b\"", "\"a\""))
  expect_equal(wet_dem_glo90(tmpl, dir = dir), f)
})

test_that("a tile that gives no ETag stops the call, naming the tile", {
  expect_error(wet:::wet_glo90_etags("http://127.0.0.1:9", "Copernicus_DSM_COG_30_N54_00_W128_00_DEM"),
               "1 GLO-90 tile\\(s\\) gave no ETag, first Copernicus_DSM_COG_30_N54_00_W128_00_DEM")
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
