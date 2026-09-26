test_that("watershed group code is validated before any query", {
  expect_error(wet_upstream_pairs(NULL, "salr"))
  expect_error(wet_upstream_pairs(NULL, "SALR'; DROP TABLE x; --"))
  expect_error(wet_upstream_pairs(NULL, c("SALR", "BOWR")))
})
