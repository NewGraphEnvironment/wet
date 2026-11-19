# #147's rule (site_carry_ship() in scripts/departure_site_lib.R), registered
# in scripts/departure_site.R's header before any run. scripts/ is not shipped,
# so these run under devtools::test() only.
site_carry_ship <- function(...) {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "departure_site_lib.R"), envir = e)
  e$site_carry_ship(...)
}

med <- function(d, c) c(distance = d, covariance_pick = c)

test_that("covariance_pick ships only when it wins by the margin in both pools", {
  r <- site_carry_ship(med(0.60, 0.62), med(0.55, 0.57), 20, 20, TRUE, 12)
  expect_equal(r$ship, "covariance_pick")
  # exactly the margin ships (floating point allowed)
  expect_equal(site_carry_ship(med(0.6, 0.61), med(0.5, 0.51), 20, 20, TRUE, 12)$ship, "covariance_pick")
  expect_equal(site_carry_ship(med(0.60, 0.605), med(0.55, 0.57), 20, 20, TRUE, 12)$ship, "distance")
  expect_match(site_carry_ship(med(0.60, 0.62), med(0.55, 0.555), 20, 20, TRUE, 12)$reason, "leak-free gain")
  expect_equal(site_carry_ship(med(0.60, 0.50), med(0.55, 0.57), 20, 20, TRUE, 12)$ship, "distance")
})

test_that("an uncovered target, too few donors or too few gauges keep distance", {
  expect_match(site_carry_ship(med(0.6, 0.8), med(0.6, 0.8), 20, 20, FALSE, 12)$reason, "not covered")
  expect_match(site_carry_ship(med(0.6, 0.8), med(0.6, 0.8), 20, 20, TRUE, 4)$reason, "4 covered donors")
  expect_equal(site_carry_ship(med(0.6, 0.8), med(0.6, 0.8), 20, 20, TRUE, 5)$ship, "covariance_pick")
  expect_match(site_carry_ship(med(0.6, 0.8), med(0.6, 0.8), 9, 20, TRUE, 12)$reason, "gauges scored")
  expect_match(site_carry_ship(med(0.6, 0.8), med(0.6, 0.8), 20, 9, TRUE, 12)$reason, "gauges scored")
  expect_match(site_carry_ship(med(0.6, NA), med(0.6, 0.8), 20, 20, TRUE, 12)$reason, "NA")
})
