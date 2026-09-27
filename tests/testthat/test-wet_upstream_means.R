test_that("upstream means of several layers match wet_upstream_mean() layer by layer", {
  ws <- data.frame(watershed_feature_id = 1:4, wscode = c("100", "100", "100.000001", "100.000002"),
                   localcode = c("100", "100.000003", "100.000001", "100.000002"),
                   area_m2 = c(4, 3, 2, 1))
  vals <- data.frame(watershed_feature_id = 1:4, a = c(1, 2, 3, NA), b = c(5, 6, 7, NA),
                     cover = c(1, 0.5, 1, 0))
  m <- wet_upstream_means(ws, vals)
  for (k in c("a", "b")) {
    one <- wet_upstream_mean(ws, data.frame(watershed_feature_id = 1:4, value = vals[[k]], cover = vals$cover),
                             denom = "covered")
    expect_equal(m[[k]], one$value)
    expect_equal(m$coverage, one$coverage)
  }
  expect_error(wet_upstream_means(ws, transform(vals, a = c(1, NA, 3, NA))), "NA value")
})
