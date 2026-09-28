test_that("Fu's curve stays between 0 and the smaller of P and PET", {
  p <- c(100, 500, 1000, 3000, 400)
  pet <- c(800, 500, 300, 200, 0)
  for (w in c(1.5, 2, 2.6, 3.5)) {
    a <- wet_aet_budyko(p, pet, w)
    expect_true(all(a >= 0))
    expect_true(all(a <= pmin(p, pet) + 1e-9))
  }
})

test_that("the limits are energy- and water-limited", {
  expect_equal(wet_aet_budyko(400, 0), 0)
  expect_equal(wet_aet_budyko(0, 400), 0)
  expect_equal(wet_aet_budyko(1e7, 500), 500, tolerance = 1e-4)  # very wet: AET -> PET
  expect_equal(wet_aet_budyko(300, 1e7), 300, tolerance = 1e-4)  # very dry: AET -> P
})

test_that("it matches the dimensionless form of Fu (1981)", {
  # E/P = 1 + phi - (1 + phi^w)^(1/w), phi = PET / P
  p <- 750
  pet <- 600
  w <- 2.6
  phi <- pet / p
  expect_equal(wet_aet_budyko(p, pet, w), p * (1 + phi - (1 + phi^w)^(1 / w)))
})

test_that("a larger omega gives more evaporation", {
  a <- vapply(c(1.5, 2, 2.6, 3.5), function(w) wet_aet_budyko(746, 650, w), 1)
  expect_true(all(diff(a) > 0))
})

test_that("negative inputs count as zero, and omega must exceed 1", {
  expect_equal(wet_aet_budyko(-5, 400), 0)
  expect_error(wet_aet_budyko(500, 400, 1), "omega")
})

test_that("SpatRasters give the same values as vectors", {
  r <- terra::rast(nrows = 1, ncols = 3)
  p <- terra::setValues(r, c(300, 700, 1500))
  pet <- terra::setValues(r, c(600, 600, 400))
  out <- wet_aet_budyko(p, pet)
  expect_s4_class(out, "SpatRaster")
  expect_equal(terra::values(out, mat = FALSE), wet_aet_budyko(c(300, 700, 1500), c(600, 600, 400)))
})
