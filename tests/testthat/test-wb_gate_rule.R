# The zone adjustment's gate (#47, scripts/wb_gate_rule.R). scripts/ is not in
# the installed package, so these run from the source tree only.
local_gate <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "wb_gate_rule.R"), envir = e)
  e$wb_gate
}

test_that("beating raw on headwater gauges keeps the adjustment, whatever the nested gauges say", {
  gate <- local_gate()
  expect_equal(gate(29, 30, 26, 25), list(keep = TRUE, arm = "headwater"))
})

test_that("losing on headwater gauges by up to the 1.0-point margin keeps it", {
  gate <- local_gate()
  expect_equal(gate(30.72, 30.69, 17.62, 21.52), list(keep = TRUE, arm = "margin"))
  expect_equal(gate(31, 30, 26, 25), list(keep = TRUE, arm = "margin"))
  # a tie is not a win
  expect_equal(gate(30, 30, 26, 25)$arm, "margin")
})

test_that("losing by more keeps it only if it is better on nested gauges", {
  gate <- local_gate()
  expect_equal(gate(31.5, 30, 24, 25), list(keep = TRUE, arm = "nested"))
  expect_equal(gate(31.5, 30, 25, 25), list(keep = FALSE, arm = "dropped"))
  expect_equal(gate(31.5, 30, 26, 25), list(keep = FALSE, arm = "dropped"))
})

test_that("a missing or non-finite MAE refuses rather than deciding", {
  gate <- local_gate()
  expect_error(gate(31.5, 30, NA, 25), "four finite MAEs")
  expect_error(gate(NaN, 30, 24, 25), "four finite MAEs")
  expect_error(gate(31.5, 30, numeric(0), 25), "four finite MAEs")
})
