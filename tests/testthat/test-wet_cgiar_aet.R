# Synthetic stand-ins for the CGIAR ArcInfo grids: GDAL identifies a GeoTIFF by
# content, so a GeoTIFF written at the grid's path reads the same way.
local_cgiar_src <- function() {
  src <- withr::local_tempdir(.local_envir = parent.frame())
  dir.create(file.path(src, "aet_monthly"))
  dir.create(file.path(src, "AET_YR"))
  r <- terra::rast(xmin = -130, xmax = -120, ymin = 50, ymax = 56, res = 1 / 120,
                   crs = "EPSG:4326")
  for (m in 1:12) {
    terra::values(r) <- m
    terra::writeRaster(r, file.path(src, "aet_monthly", sprintf("aet_%d", m)),
                       filetype = "GTiff", datatype = "INT2U")
  }
  terra::values(r) <- 78
  terra::writeRaster(r, file.path(src, "AET_YR", "aet_yr"), filetype = "GTiff",
                     datatype = "INT2U")
  src
}

test_that("the stack is cropped, ordered and named month by month", {
  src <- local_cgiar_src()
  r <- wet:::wet_cgiar_stack(src, wet:::wet_cgiar_cells(c(-127.2, 54.1, -126.8, 54.4)))
  expect_equal(names(r), c(sprintf("aet_%02d", 1:12), "aet_yr"))
  expect_equal(unname(unlist(terra::global(r, "mean"))), c(1:12, 78))
  # cropped on the source grid, not resampled
  expect_equal(terra::res(r), rep(1 / 120, 2))
  e <- as.vector(terra::ext(r))
  expect_true(e[1] <= -127.2 && e[2] >= -126.8 && e[3] <= 54.1 && e[4] >= 54.4)
})

test_that("a missing grid is named in the error", {
  src <- local_cgiar_src()
  unlink(file.path(src, "aet_monthly", "aet_7"))
  expect_error(wet:::wet_cgiar_stack(src, wet:::wet_cgiar_cells(c(-127, 54, -126, 55))), "aet_7")
})

test_that("a cached crop is returned without downloading", {
  dir <- withr::local_tempdir()
  bbox <- c(-139.1, 48.2, -114, 60.1)
  f <- file.path(dir, "cgiar_aet_c4908-7920_r3588-5016.tif")
  file.create(f)
  expect_equal(wet_cgiar_aet(bbox, dir = dir), f)
})

test_that("an invalid bbox is refused", {
  expect_error(wet_cgiar_aet(c(-114, 48, -139, 60)))
  expect_error(wet_cgiar_aet(c(-139, 48, -114)))
})

test_that("a failed download leaves no file at the destination", {
  dest <- file.path(withr::local_tempdir(), "x.bin")
  expect_error(wet:::wet_download("http://127.0.0.1:9/x", dest, 5))
  expect_false(file.exists(dest))
  expect_false(file.exists(paste0(dest, ".part")))
})

test_that("extracted directories without the completion marker are not trusted", {
  dir <- withr::local_tempdir()
  dir.create(file.path(dir, "src", "AET_YR", "aet_yr"), recursive = TRUE)
  dir.create(file.path(dir, "src", "aet_monthly", "aet_1"), recursive = TRUE)
  # no .extracted marker: the function must go back to the source (unreachable
  # here), not read the half-extracted tree
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9")
  expect_error(wet_cgiar_aet(c(-128, 54, -127, 55), dir = dir))
  expect_false(dir.exists(file.path(dir, "src", "AET_YR")))
})

test_that("bboxes that crop differently never share a cache key", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "cgiar_aet_c4920-7920_r3600-5040.tif")
  file.create(f)
  expect_equal(wet_cgiar_aet(c(-139, 48, -114, 60), dir = dir), f)
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9")
  # -139.00001 adds a column to the crop, so it must not hit the cached file
  expect_error(wet_cgiar_aet(c(-139.00001, 48, -114, 60), dir = dir))
})

test_that("the lattice cells follow terra's outward snap, with a tolerance for float noise", {
  cells <- wet:::wet_cgiar_cells
  expect_equal(unname(cells(c(-139, 48, -114, 60))), c(4920, 7920, 3600, 5040))
  # a hair west of an edge takes the next column; float noise at an edge does not
  expect_equal(unname(cells(c(-139.00001, 48, -114, 60))[1]), 4919)
  expect_equal(unname(cells(c(-139 + 1e-12, 48, -114, 60))[1]), 4920)
  # the crop is exactly the keyed cells
  src <- local_cgiar_src()
  cl <- cells(c(-127.2, 54.1, -126.8, 54.4))
  r <- wet:::wet_cgiar_stack(src, cl)
  expect_equal(terra::ncol(r), unname(cl[2] - cl[1]))
  expect_equal(terra::nrow(r), unname(cl[4] - cl[3]))
})
