# scripts/air_publish_lib.R (#216): the part writer, the frames and the checks that take no
# database, on the masked copy of cd's example cube. scripts/ is not shipped to R CMD check,
# so these run under devtools::test() only. Tests that conform to the crate schemas need a
# crate holding them, and skip without one.

air_lib <- function(env = parent.frame()) {
  d <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(d), "scripts/ is not in the installed package")
  testthat::skip_if_not_installed("arrow")
  e <- new.env()
  sys.source(file.path(d, "air_publish_lib.R"), envir = e)
  e
}

has_air_schemas <- function() {
  requireNamespace("crate", quietly = TRUE) &&
    nzchar(system.file("extdata", "schemas", "nge", "air_temperature", "fwa", "v1", "cell_daily.yaml",
                       package = "crate"))
}

# the fixture lookup, made by the lib's own frame from cd's call on the masked cube
fixture_lookup <- function(e, cube) {
  p <- air_fixture_points()
  cells <- wet_air_cells(p[c("linear_feature_id", "lon", "lat")], day = "2002-01-01", source = cube)
  e$air_lookup_frame(p, cells)
}

masked <- function(env = parent.frame()) {
  testthat::skip_if_not_installed("cd")
  air_masked_cube(file.path(withr::local_tempdir(.local_envir = env), "cube"))
}

test_that("part keys parse back to the tree's datasets and codes", {
  e <- air_lib()
  k <- e$air_part_key("segment_cell", "BULK")
  expect_identical(k, "segment_cell/scenario=historical/forcing=ERA5-Land/source=cd_daily/part-BULK.parquet")
  p <- wet_part_parse(e$air_part_key("cell_daily", 1950), e$air_id)
  expect_identical(p$dataset, "air_temperature/fwa/v1/cell_daily")
  expect_identical(p$code, "1950")
})

test_that("a cell id maps back to its centre", {
  e <- air_lib()
  ids <- wet_air_cell_id(c(-126.2, -140, -113.9, 0, 179.9), c(54.5, 60, 48, 0, -10))
  ctr <- e$air_cell_centre(ids)
  expect_equal(ctr$x, c(-126.2, -140, -113.9, 0, 179.9), tolerance = 1e-12)
  expect_equal(ctr$y, c(54.5, 60, 48, 0, -10), tolerance = 1e-12)
})

test_that("a lookup and a year are written typed, and the same frame writes the same bytes", {
  skip_if_not(has_air_schemas(), "crate does not hold the air schemas")
  e <- air_lib()
  cube <- masked()
  lk <- e$air_conform(fixture_lookup(e, cube), "segment_cell")
  root <- withr::local_tempdir()
  f <- e$air_part_write(lk, root, "segment_cell", "AAAA")
  s <- arrow::read_parquet(f, as_data_frame = FALSE)$schema
  expect_identical(s$cell_id$type$ToString(), "int32")
  expect_identical(s$linear_feature_id$type$ToString(), "int32")
  md5 <- unname(tools::md5sum(f))
  e$air_part_write(lk, root, "segment_cell", "AAAA")
  expect_identical(unname(tools::md5sum(f)), md5)
  used <- sort(unique(stats::na.omit(lk$cell_id)))
  ctr <- e$air_cell_centre(used)
  x <- cd::cd_extract_daily(data.frame(id = used, lon = ctr$x, lat = ctr$y), "2002-01-01", "2002-12-31",
                            source = cube)
  x$checksum <- "local"
  y <- e$air_conform(e$air_daily_frame(x, used), "cell_daily")
  g <- e$air_part_write(y, root, "cell_daily", 2002)
  s <- arrow::read_parquet(g, as_data_frame = FALSE)$schema
  expect_identical(s$date$type$ToString(), "date32[day]")
  expect_identical(s$tmean_c$type$ToString(), "float")
  back <- as.data.frame(arrow::read_parquet(g))
  expect_identical(as.numeric(back$tmax_c), y$tmax_c)
})

test_that("a year cd moved, left without a value or without a checksum is refused", {
  e <- air_lib()
  cube <- masked()
  used <- wet_air_cell_id(c(-126.2, -126.2), c(54.5, 54.4))
  ctr <- e$air_cell_centre(used)
  x <- cd::cd_extract_daily(data.frame(id = used, lon = ctr$x, lat = ctr$y), "2002-01-01", "2002-01-03",
                            source = cube)
  x$checksum <- "local"
  expect_silent(e$air_daily_frame(x, used))
  bad <- x
  bad$cell_moved[1] <- TRUE
  expect_error(e$air_daily_frame(bad, used), "moved")
  bad <- x
  bad$value[2] <- NA
  expect_error(e$air_daily_frame(bad, used), "NA")
  bad <- x
  bad$checksum[1] <- NA
  expect_error(e$air_daily_frame(bad, used), "checksum")
  # a centre that cd placed on another cell
  far <- cd::cd_extract_daily(data.frame(id = used, lon = ctr$x + 0.1, lat = ctr$y), "2002-01-01", "2002-01-03",
                              source = cube)
  far$checksum <- "local"
  expect_error(e$air_daily_frame(far, used), "another cell")
})

test_that("the cell checks pass the fixture and each turns red on its own mutation", {
  e <- air_lib()
  cube <- masked()
  lk <- fixture_lookup(e, cube)
  r <- terra::rast(file.path(cube, "tmean_daily_2002.tif"))
  mask <- !is.na(terra::values(r[[1]], mat = FALSE))
  ok <- e$air_check_cells(lk, r, mask)
  expect_true(all(grepl("differing 0, .* pass$", ok)))
  fails <- function(x, which) grepl("FAIL$", e$air_check_cells(x, r, mask)[which])
  # an own segment's cell moved to a neighbour
  m <- lk
  i <- which(m$linear_feature_id == 1)
  m$cell_id[i] <- wet_air_cell_id(-126.3, 54.5)
  expect_true(fails(m, 1))
  # a moved segment's cell changed to another of the eight around its own
  m <- lk
  i <- which(m$linear_feature_id == 3)
  m$cell_id[i] <- wet_air_cell_id(-126.0, 54.4)
  expect_true(fails(m, 2))
  # a status flipped: a no_data segment said to have moved, an own one said to be outside
  m <- lk
  m$cell_status[m$linear_feature_id == 4] <- "moved"
  expect_true(fails(m, 2))
  m <- lk
  m$cell_status[m$linear_feature_id == 1] <- "outside"
  expect_true(fails(m, 4))
  # a moved segment said to have no data around it
  m <- lk
  i <- which(m$linear_feature_id == 3)
  m$cell_status[i] <- "no_data"
  m$cell_id[i] <- NA
  expect_true(fails(m, 3))
})

test_that("completeness and values pass a year part and turn red on a dropped or changed row", {
  e <- air_lib()
  cube <- masked()
  used <- wet_air_cell_id(c(-126.2, -126.2, -126.4), c(54.5, 54.4, 54.3))
  ctr <- e$air_cell_centre(used)
  x <- cd::cd_extract_daily(data.frame(id = used, lon = ctr$x, lat = ctr$y), "2002-01-01", "2002-12-31",
                            source = cube)
  x$checksum <- "local"
  y <- e$air_daily_frame(x, used)
  files <- stats::setNames(file.path(cube, paste0(e$air_vars, "_daily_2002.tif")), e$air_vars)
  expect_identical(e$air_check_complete(y, used, 2002)$differing, 0L)
  v <- e$air_check_values(y, files)
  expect_identical(c(v$compared, v$differing), c(3L * 3L * 365L, 0L))
  # one cell's rows dropped
  expect_gt(e$air_check_complete(y[y$cell_id != used[2], ], used, 2002)$differing, 0L)
  # one value changed
  y2 <- y
  y2$tmin_c[100] <- y2$tmin_c[100] + 0.5
  v2 <- e$air_check_values(y2, files)
  expect_identical(v2$differing, 1L)
  expect_equal(v2$largest, 0.5, tolerance = 1e-6)
})

test_that("the upload guard's file list is what the build reads", {
  e <- air_lib()
  d <- testthat::test_path("..", "..")
  scripts <- c("scripts/air_publish.R", "scripts/air_publish_lib.R")
  ns <- asNamespace("wet")
  fns <- Filter(function(n) is.function(get(n, ns)), ls(ns, all.names = TRUE))
  # wet functions the two scripts call, as wet:::f, wet::f or a bare wet_* name
  called <- unique(unlist(lapply(scripts, function(f) {
    code <- getParseData(parse(file.path(d, f), keep.source = TRUE))
    intersect(code$text[code$token %in% c("SYMBOL_FUNCTION_CALL", "SYMBOL")], fns)
  })))
  # and what those call in turn, within wet
  seen <- character()
  while (length(called <- setdiff(called, seen))) {
    seen <- c(seen, called)
    called <- unique(unlist(lapply(called, function(n) intersect(all.names(body(get(n, ns))), fns))))
  }
  files <- unique(vapply(seen, function(n) {
    sf <- utils::getSrcFilename(get(n, ns), full.names = FALSE)
    if (length(sf)) file.path("R", sf) else NA_character_
  }, ""))
  files <- files[!is.na(files)]
  sourced <- unique(unlist(lapply(scripts, function(f) {
    l <- readLines(file.path(d, f))
    sub('^.*source\\("([^"]+)"\\).*$', "\\1", grep('^[^#]*source\\("scripts/', l, value = TRUE))
  })))
  derived <- sort(unique(c(scripts, files, sourced,
                           if ("wet_receipt_write" %in% seen) "inst/receipt/air_temperature_fwa_v1.yaml")))
  expect_setequal(e$air_code_files, derived)
})
