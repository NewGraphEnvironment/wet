test_that("conversion matches fwapg's constant", {
  # 1 mm/yr over 1 km2 = 1000 m3/yr
  expect_equal(wet_mm_to_m3s(1, 1e6), 1000 / (365 * 86400))
  expect_equal(wet_mm_to_m3s(500, 1e8), 500 * 1e8 / 31536000000)
  expect_equal(wet_mm_to_m3s(c(0, NA), 1), c(0, NA))
})

test_that("days sets the period, and months sum to the 365.25-day year", {
  expect_equal(wet_mm_to_m3s(1, 1e6, days = 1), 1000 / 86400)
  expect_equal(sum(wet_month_days()), 365.25)
  mm <- rep(10, 12)
  q <- wet_mm_to_m3s(mm, 1e8, days = wet_month_days())
  # volume-weighted monthly flow equals the annual flow of the summed depth
  expect_equal(sum(q * wet_month_days()) / 365.25, wet_mm_to_m3s(120, 1e8, days = 365.25))
})
