# Extracted from test-wet_air_daily.R:32

# prequel ----------------------------------------------------------------------
air_cat <- function() {
  wet_catalog(system.file("extdata", "air_example", "manifest.json", package = "wet"))
}
air_cube <- function() {
  skip_if_not_installed("cd")
  skip_if_not_installed("terra")
  air_masked_cube(file.path(withr::local_tempdir(.local_envir = parent.frame()), "cube"))
}
cd_quiet <- function(...) suppressWarnings(cd::cd_extract_daily(...))

# test -------------------------------------------------------------------------
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
expect_identical(cells$cell_x[cells$linear_feature_id %in% c(3, 6)], c(-126.2, -126.2))
expect_identical(cells$cell_y[cells$linear_feature_id %in% c(3, 6)], c(54.4, 54.7))
