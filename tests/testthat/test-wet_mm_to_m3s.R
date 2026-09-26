test_that("conversion matches fwapg's constant", {
  # 1 mm/yr over 1 km2 = 1000 m3/yr
  expect_equal(wet_mm_to_m3s(1, 1e6), 1000 / (365 * 86400))
  expect_equal(wet_mm_to_m3s(500, 1e8), 500 * 1e8 / 31536000000)
  expect_equal(wet_mm_to_m3s(c(0, NA), 1), c(0, NA))
})
