test_that("extraterrestrial radiation matches FAO-56 Example 8", {
  # 20 deg S on 3 September (J = 246): Ra = 32.2 MJ m-2 day-1
  expect_equal(wet:::wet_ra(-20, 246), 32.2, tolerance = 0.05 / 32.2)
})

test_that("extraterrestrial radiation is seasonal, mirrored across the equator, and 0 in polar night", {
  expect_gt(wet:::wet_ra(50, 172), 4 * wet:::wet_ra(50, 355))
  # the same day at 50 N and 50 S differ only through dr and the sign of delta
  expect_equal(wet:::wet_ra(50, 172), wet:::wet_ra(-50, 355), tolerance = 0.07)
  # no sun, no radiation, and no NaN from acos()
  expect_equal(wet:::wet_ra(80, 15), 0)
})

test_that("Hargreaves ET0 is the FAO-56 equation 52 times the days in the month", {
  ra <- wet:::wet_ra(50, floor(30.4 * 7 - 15))
  expected <- 0.0023 * (15 + 17.8) * sqrt(25 - 5) * 0.408 * ra * 31
  expect_equal(wet_pet_hargreaves(25, 5, 50, 7), expected)
})

test_that("no diurnal range or a very cold month gives zero, never negative or NaN", {
  expect_equal(wet_pet_hargreaves(10, 10, 50, 7), 0)
  expect_equal(wet_pet_hargreaves(-30, -40, 50, 1), 0)
  # Tmin above Tmax (possible after independent downscaling) is no range, not NaN
  expect_equal(wet_pet_hargreaves(5, 6, 50, 7), 0)
})

test_that("vectors recycle and SpatRasters give the same values as vectors", {
  v <- wet_pet_hargreaves(c(20, 25), c(5, 8), c(49, 55), 6)
  expect_length(v, 2)
  r <- terra::rast(nrows = 2, ncols = 1, xmin = -120, xmax = -119, ymin = 49, ymax = 55)
  tx <- terra::setValues(r, c(20, 25))
  tn <- terra::setValues(r, c(5, 8))
  lat <- terra::setValues(r, c(55, 49))  # row 1 is north
  out <- wet_pet_hargreaves(tx, tn, lat, 6)
  expect_s4_class(out, "SpatRaster")
  expect_equal(terra::values(out, mat = FALSE), wet_pet_hargreaves(c(20, 25), c(5, 8), c(55, 49), 6))
})

test_that("a month outside 1-12 is refused", {
  expect_error(wet_pet_hargreaves(20, 5, 50, 13), "month")
})
