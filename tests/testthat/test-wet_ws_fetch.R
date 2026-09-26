test_that("basin code is validated before any query", {
  for (bad in list("10", "100.5912", "100; drop table x", c("100", "200"),
                   NA_character_, 100)) {
    expect_error(wet_ws_fetch(NULL, bad), "wscode")
    expect_error(wet_upstream_irregular(NULL, bad), "wscode")
  }
})
