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

# Two small files standing in for the figshare archives, in a cache dir;
# returns their md5s.
local_cgiar_archives <- function(dir, content = c("yr", "monthly")) {
  rars <- file.path(dir, c("AET_YR.rar", "aet_monthly.rar"))
  writeLines(content[1], rars[1])
  writeLines(content[2], rars[2])
  unname(tools::md5sum(rars))
}

# The crop's cache name for lattice cells c(col0, col1, row0, row1) and the
# archives' md5s.
cgiar_name <- function(cells, md5, method = wet:::wet_cgiar_method) {
  key <- wet:::wet_md5_text(paste(c(method, md5), collapse = "|"))
  sprintf("cgiar_aet_c%d-%d_r%d-%d_%s.tif", cells[1], cells[2], cells[3], cells[4], substr(key, 1, 8))
}

# figshare reporting the archives in `dir` as they are now, extraction
# recorded in `calls` rather than run, and the stack stopped at its first
# step; the network behind them unreachable.
local_cgiar_rebuild <- function(dir, calls, env = parent.frame()) {
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9", .local_envir = env)
  testthat::local_mocked_bindings(
    wet_figshare_files = function(article) {
      nm <- c("AET_YR.rar", "aet_monthly.rar")
      data.frame(name = nm, url = "http://127.0.0.1:9/x", md5 = unname(tools::md5sum(file.path(dir, nm))))
    },
    wet_unrar = function(rar, exdir) {
      assign("n", get("n", calls) + 1, envir = calls)
      dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
    },
    wet_cgiar_stack = function(src, cells) stop("stacking the crop"),
    .env = env
  )
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

test_that("a cached crop is returned without downloading when its archives match", {
  dir <- withr::local_tempdir()
  md5 <- local_cgiar_archives(dir)
  bbox <- c(-139.1, 48.2, -114, 60.1)
  f <- file.path(dir, cgiar_name(c(4908, 7920, 3588, 5016), md5))
  file.create(f)
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9")
  expect_equal(wet_cgiar_aet(bbox, dir = dir), f)
})

test_that("an archive with another md5 gives another crop path, so the crop is rebuilt", {
  dir <- withr::local_tempdir()
  md5 <- local_cgiar_archives(dir)
  bbox <- c(-139.1, 48.2, -114, 60.1)
  file.create(file.path(dir, cgiar_name(c(4908, 7920, 3588, 5016), md5)))
  local_cgiar_archives(dir, c("yr", "monthly, revised"))
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9")
  expect_error(wet_cgiar_aet(bbox, dir = dir), "127.0.0.1")
})

test_that("a crop cached under another builder method is rebuilt, not returned", {
  dir <- withr::local_tempdir()
  md5 <- local_cgiar_archives(dir)
  bbox <- c(-139.1, 48.2, -114, 60.1)
  # the names the crop had before its builder's method (#19) and its archives (#23) were in the key
  file.create(file.path(dir, "cgiar_aet_c4908-7920_r3588-5016.tif"))
  file.create(file.path(dir, sprintf("cgiar_aet_c4908-7920_r3588-5016_%s.tif",
                                     substr(wet:::wet_md5_text(wet:::wet_cgiar_method), 1, 8))))
  # and one under a method since superseded
  file.create(file.path(dir, cgiar_name(c(4908, 7920, 3588, 5016), md5, method = "superseded")))
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9")
  expect_error(wet_cgiar_aet(bbox, dir = dir), "127.0.0.1")
})

test_that("an archive figshare reports with another md5 is downloaded again", {
  dir <- withr::local_tempdir()
  local_cgiar_archives(dir)
  withr::local_options(wet.figshare_api = "http://127.0.0.1:9")
  local_mocked_bindings(
    wet_figshare_files = function(article) {
      data.frame(name = c("AET_YR.rar", "aet_monthly.rar"), url = "http://127.0.0.1:9/x",
                 md5 = c("0123456789abcdef0123456789abcdef",
                         unname(tools::md5sum(file.path(dir, "aet_monthly.rar")))))
    },
    wet_download = function(url, dest, timeout, netrc = NULL) stop("downloading ", basename(dest))
  )
  expect_error(wet_cgiar_aet(c(-128, 54, -127, 55), dir = dir, overwrite = TRUE), "downloading AET_YR.rar")
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
  local_cgiar_archives(dir)
  dir.create(file.path(dir, "src", "AET_YR", "aet_yr"), recursive = TRUE)
  dir.create(file.path(dir, "src", "aet_monthly", "aet_1"), recursive = TRUE)
  calls <- new.env()
  calls$n <- 0
  local_cgiar_rebuild(dir, calls)
  # no .extracted marker: the half-extracted tree is removed and both archives extracted again
  expect_error(wet_cgiar_aet(c(-128, 54, -127, 55), dir = dir), "stacking the crop")
  expect_equal(calls$n, 2)
  expect_false(dir.exists(file.path(dir, "src", "AET_YR", "aet_yr")))
})

test_that("an archive whose md5 differs from the marker is extracted again", {
  dir <- withr::local_tempdir()
  md5 <- local_cgiar_archives(dir)
  src <- file.path(dir, "src")
  dir.create(src)
  writeLines(paste(c("AET_YR.rar", "aet_monthly.rar"), md5), file.path(src, ".extracted"))
  file.create(file.path(src, "from_the_old_archive"))
  calls <- new.env()
  calls$n <- 0
  local_cgiar_rebuild(dir, calls)
  # the marker matches: nothing is extracted
  expect_error(wet_cgiar_aet(c(-128, 54, -127, 55), dir = dir), "stacking the crop")
  expect_equal(calls$n, 0)
  expect_true(file.exists(file.path(src, "from_the_old_archive")))
  # an archive replaced since: the tree is removed and extracted again, and the marker names the new md5
  md5 <- local_cgiar_archives(dir, c("yr", "monthly, revised"))
  expect_error(wet_cgiar_aet(c(-128, 54, -127, 55), dir = dir), "stacking the crop")
  expect_equal(calls$n, 2)
  expect_false(file.exists(file.path(src, "from_the_old_archive")))
  expect_equal(readLines(file.path(src, ".extracted")), paste(c("AET_YR.rar", "aet_monthly.rar"), md5))
})

test_that("bboxes that crop differently never share a cache key", {
  dir <- withr::local_tempdir()
  md5 <- local_cgiar_archives(dir)
  f <- file.path(dir, cgiar_name(c(4920, 7920, 3600, 5040), md5))
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
