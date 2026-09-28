test_that("cgiar keeps the stored ro_raw; other variants are p_yr minus their column", {
  d <- data.frame(ro_raw = 101, p_yr = 500, aet_yr = 400, aet_tc = 450, aet_fu = 480)
  expect_equal(wet:::wet_wb_raw(d), 101)
  expect_equal(wet:::wet_wb_raw(d, "tc"), 50)
  expect_equal(wet:::wet_wb_raw(d, "fu"), 20)
})

test_that("an unknown variant or a missing column is an error, not NULL arithmetic", {
  d <- data.frame(ro_raw = 1, p_yr = 500, aet_yr = 400)
  expect_error(wet:::wet_wb_raw(d, "modis"), "unknown AET variant")
  expect_error(wet:::wet_wb_raw(d, "lc"), "aet_lc")
  expect_error(wet:::wet_wb_raw(d[c("p_yr", "aet_yr")]), "ro_raw")
})

test_that("it works on SpatRaster layers as on data frame columns", {
  r <- terra::rast(nrows = 1, ncols = 2, nlyrs = 2)
  terra::values(r) <- cbind(c(500, 600), c(450, 700))
  names(r) <- c("p_yr", "aet_tc")
  expect_equal(terra::values(wet:::wet_wb_raw(r, "tc"), mat = FALSE), c(50, -100))
})
