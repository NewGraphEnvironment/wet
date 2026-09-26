test_that("1981-2010 maps to fwapg's time indices 13149:24105", {
  ix <- wet_pcic_index(c(-123, 54, -122, 55), "1981-01-01", "2010-12-31")
  expect_equal(ix$time, c(13149L, 24105L))
})

test_that("cells are those whose extent intersects the bbox", {
  # first cell centre -139.96875 spans -140 to -139.9375
  ix <- wet_pcic_index(c(-140, 41.0625, -139.93, 41.13), "1945-01-01", "1945-01-01")
  expect_equal(ix$lon, c(0L, 1L))
  expect_equal(ix$lat, c(0L, 1L))
  expect_equal(ix$time, c(0L, 0L))
  # a bbox inside a single cell gives one index
  ix <- wet_pcic_index(c(-139.99, 41.07, -139.95, 41.1), "1945-01-01", "1945-01-02")
  expect_equal(ix$lon, c(0L, 0L))
  expect_equal(ix$lat, c(0L, 0L))
  expect_equal(ix$time, c(0L, 1L))
})

test_that("indices clamp to the grid and off-grid boxes are refused", {
  ix <- wet_pcic_index(c(-150, 30, -139.9, 41.1), "1945-01-01", "1945-01-01")
  expect_equal(ix$lon[1], 0L)
  expect_equal(ix$lat[1], 0L)
  expect_error(wet_pcic_index(c(-160, 30, -150, 35), "1945-01-01", "1945-01-01"),
               "does not intersect")
})

test_that("invalid bbox and dates are refused", {
  expect_error(wet_pcic_index(c(-122, 54, -123, 55), "1981-01-01", "1981-12-31"))
  expect_error(wet_pcic_index(c(-123, 54, -122, 55), "1981-12-31", "1981-01-01"))
  expect_error(wet_pcic_index(c(-123, 54, -122, 55), "1944-12-31", "1981-01-01"),
               "before the dataset origin")
})
