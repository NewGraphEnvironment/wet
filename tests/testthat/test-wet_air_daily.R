# The air temperature lookup and its reader (#216). The cell rule is cd's own, so each test
# compares with cd::cd_extract_daily() on the masked copy of cd's example cube
# (helper-air.R); the bundled tree (data-raw/air_example_data.R) is read through
# wet_catalog().

air_cat <- function() {
  wet_catalog(system.file("extdata", "air_example", "manifest.json", package = "wet"))
}

air_cube <- function() {
  skip_if_not_installed("cd")
  skip_if_not_installed("terra")
  air_masked_cube(file.path(withr::local_tempdir(.local_envir = parent.frame()), "cube"))
}

cd_quiet <- function(...) suppressWarnings(cd::cd_extract_daily(...))

test_that("each status comes from cd's own call, a moved point on the neighbour cd names", {
  cube <- air_cube()
  p <- air_fixture_points()
  cells <- wet:::wet_air_cells(p[c("linear_feature_id", "lon", "lat")], day = "2002-01-01", source = cube)
  expect_identical(cells$cell_status, c("own", "own", "moved", "no_data", "outside", "moved", "own"))
  ref <- cd_quiet(data.frame(id = p$linear_feature_id, lon = p$lon, lat = p$lat), "2002-01-01", "2002-01-01",
                  "tmean", source = cube)
  has <- cells$cell_status %in% c("own", "moved")
  expect_identical(cells$cell_x[has], ref$cell_x[has])
  expect_identical(cells$cell_y[has], ref$cell_y[has])
  expect_identical(cells$cell_id[has], wet:::wet_air_cell_id(ref$cell_x[has], ref$cell_y[has]))
  expect_true(all(is.na(cells$cell_id[!has])) && all(is.na(cells$cell_x[!has])))
  # the moved points take the cells cd's rule names: east of the 2 x 2 block, west of cell 19
  expect_equal(cells$cell_x[cells$linear_feature_id %in% c(3, 6)], c(-126.2, -126.2), tolerance = 1e-9)
  expect_equal(cells$cell_y[cells$linear_feature_id %in% c(3, 6)], c(54.4, 54.7), tolerance = 1e-9)
})

test_that("cd's two expected warnings are muffled", {
  cube <- air_cube()
  p <- air_fixture_points()[c("linear_feature_id", "lon", "lat")]
  expect_no_warning(wet:::wet_air_cells(p, day = "2002-01-01", source = cube))
})

test_that("an unexpected cd warning is not muffled", {
  cube <- air_cube()
  p <- air_fixture_points()[c("linear_feature_id", "lon", "lat")]
  real <- cd::cd_extract_daily
  testthat::local_mocked_bindings(
    cd_extract_daily = function(...) {
      warning("an unexpected warning")
      suppressWarnings(real(...))
    },
    .package = "cd"
  )
  expect_warning(wet:::wet_air_cells(p, day = "2002-01-01", source = cube), "unexpected")
})

test_that("the cell id is ERA5-Land's own grid, not cd's box", {
  expect_identical(wet:::wet_air_cell_id(-126.2, 54.5), as.integer(355 * 3600 + 2338))
  expect_identical(wet:::wet_air_cell_id(0, 90), 0L)
  expect_identical(wet:::wet_air_cell_id(-0.1, -90), as.integer(1800 * 3600 + 3599))
  # a cube on a larger box numbers the same cell the same way
  expect_identical(wet:::wet_air_cell_id(-140, 60), as.integer(300 * 3600 + 2200))
})

test_that("the reader returns cd's values at each segment's stored point", {
  cube <- air_cube()
  cat <- air_cat()
  p <- air_fixture_points()
  a <- wet_air_daily(c(1, 2, 3, 6), "2002-06-30", "2002-07-02", c("tmean", "tmin"), groups = "AAAA", catalog = cat)
  expect_named(a, c("id", "date", "variable", "value", "cell_id", "cell_x", "cell_y", "cell_moved", "cell_status"))
  expect_s3_class(a$date, "Date")
  expect_identical(nrow(a), 4L * 2L * 3L)
  w <- match(c(1, 2, 3, 6), p$linear_feature_id)
  ref <- cd_quiet(data.frame(id = p$linear_feature_id[w], lon = p$lon[w], lat = p$lat[w]), "2002-06-30",
                  "2002-07-02", c("tmean", "tmin"), source = cube)
  expect_identical(a$id, as.integer(ref$id))
  expect_identical(a$date, ref$date)
  expect_identical(a$variable, ref$variable)
  expect_identical(a$value, ref$value)
  expect_identical(a$cell_x, ref$cell_x)
  expect_identical(a$cell_moved, ref$cell_moved)
})

test_that("a segment with no cell, one the lookup lacks and one outside the groups read as missing", {
  cat <- air_cat()
  a <- wet_air_daily(c(4, 5, 99, 7, 1), "2002-07-01", "2002-07-02", groups = "AAAA", catalog = cat)
  expect_identical(nrow(a), 10L)
  expect_identical(unique(a$id), c(4L, 5L, 99L, 7L, 1L))
  miss <- a$id %in% c(4, 5, 99, 7)
  expect_true(all(is.na(a$value[miss])))
  expect_false(anyNA(a$value[!miss]))
  expect_identical(unique(a$cell_status[a$id == 4]), "no_data")
  expect_identical(unique(a$cell_status[a$id == 5]), "outside")
  expect_true(all(is.na(a$cell_status[a$id %in% c(99, 7)])))
  # segment 7 reads once its group is named
  b <- wet_air_daily(7, "2002-07-01", "2002-07-02", groups = c("AAAA", "BBBB"), catalog = cat)
  expect_false(anyNA(b$value))
})

test_that("bad arguments are refused before any read", {
  cat <- air_cat()
  expect_error(wet_air_daily(1, "2002-07-01", "2002-07-02", catalog = cat), "groups")
  expect_error(wet_air_daily(1, "2002-07-01", "2002-07-02", groups = "aaaa", catalog = cat), "groups")
  expect_error(wet_air_daily(1.5, "2002-07-01", "2002-07-02", groups = "AAAA", catalog = cat), "segments")
  expect_error(wet_air_daily(c(1, NA), "2002-07-01", "2002-07-02", groups = "AAAA", catalog = cat), "segments")
  expect_error(wet_air_daily(c(1, 1), "2002-07-01", "2002-07-02", groups = "AAAA", catalog = cat), "twice")
  expect_error(wet_air_daily(1, "2002-07-02", "2002-07-01", groups = "AAAA", catalog = cat), "after")
  expect_error(wet_air_daily(1, "2002-7-1", "2002-07-02", groups = "AAAA", catalog = cat), "from")
  expect_error(wet_air_daily(1, "2002-07-01", "2002-07-02", "tavg", groups = "AAAA", catalog = cat), "variables")
  expect_error(wet_air_daily(1, "2001-12-31", "2002-01-01", groups = "AAAA", catalog = cat), "year 2001")
  expect_error(wet_air_daily(1, "2002-07-01", "2002-07-02", groups = "CCCC", catalog = cat), "CCCC")
  dis <- wet_catalog(system.file("extdata", "discharge_manifest.json", package = "wet"))
  expect_error(wet_air_daily(1, "2002-07-01", "2002-07-02", groups = "AAAA", catalog = dis), "not the air tree")
})
