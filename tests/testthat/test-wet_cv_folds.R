# Three gauges on one river (100) and a tributary (100.000500):
#   A mainstem outlet (100, 100)            400 km2
#   B tributary       (100.000500, same)    100 km2, upstream of A
#   C mainstem above the tributary (100, 100.000800) 200 km2, upstream of A
# and D on another river (200), a headwater.
st <- data.frame(
  station_number = c("08AA001", "08AB001", "08AA002", "08BA001"),
  wscode = c("100", "100.000500", "100", "200"),
  localcode = c("100", "100.000500", "100.000800", "200"),
  upstream_area_km2 = c(400, 100, 200, 50)
)

test_that("upstream relations follow FWA_Upstream", {
  expect_equal(wet:::wet_fwa_upstream("100", "100", st$wscode, st$localcode),
               c(TRUE, TRUE, TRUE, FALSE))
  # C (above the tributary) does not see the tributary B
  expect_equal(wet:::wet_fwa_upstream("100", "100.000800", st$wscode, st$localcode),
               c(FALSE, FALSE, TRUE, FALSE))
})

test_that("blocks, nesting and leak exposure", {
  f <- wet_cv_folds(st)
  expect_equal(f$fold, c("08AA", "08AB", "08AA", "08BA"))
  expect_equal(f$nesting, c("nested", "headwater", "headwater", "headwater"))
  # A shares a fold with C, so only B (another fold) leaks: 100 / 400
  expect_equal(f$leak_up, c(0.25, 0, 0, 0))
  # B has A downstream in another fold; C's downstream A is in its own fold
  expect_equal(f$leak_down, c(FALSE, TRUE, FALSE, FALSE))
})

test_that("leave-one-out exposes every nested gauge", {
  f <- wet_cv_folds(st, block = "station")
  expect_equal(f$fold, st$station_number)
  expect_equal(f$leak_up, c(0.5, 0, 0, 0))  # largest upstream gauge of A is C, 200 / 400
  expect_equal(f$leak_down, c(FALSE, TRUE, TRUE, FALSE))
})

test_that("bad input is refused", {
  expect_error(wet_cv_folds(st[, -2]), "wscode")
  expect_error(wet_cv_folds(rbind(st, st[1, ])), "duplicate")
  bad <- st
  bad$upstream_area_km2[2] <- NA
  expect_error(wet_cv_folds(bad), "NA")
})
