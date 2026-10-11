test_that("routed is picked unless it carries under far_low of the balance", {
  pick <- wet:::wet_source_pick(c(10, 1, 2, 1.99), c(10, 10, 10, 10), far_low = 0.2)
  expect_identical(pick, c("pcic_routed", "wet_balance", "pcic_routed", "wet_balance"))
})

test_that("a missing source falls to the other; neither gives NA", {
  pick <- wet:::wet_source_pick(c(NA, 5, NA), c(5, NA, NA), far_low = 0.2)
  expect_identical(pick, c("wet_balance", "pcic_routed", NA_character_))
})

test_that("a zero balance never displaces routed, even a zero routed", {
  expect_identical(wet:::wet_source_pick(c(0, 3), c(0, 0), far_low = 0.2), c("pcic_routed", "pcic_routed"))
  expect_identical(wet:::wet_source_pick(0, 1, far_low = 0.2), "wet_balance")
})

test_that("lengths, the cut and negative flow are checked", {
  expect_error(wet:::wet_source_pick(1:2, 1, far_low = 0.2), "same length")
  expect_error(wet:::wet_source_pick(1, 1), "far_low")
  expect_error(wet:::wet_source_pick(1, 1, far_low = c(0.1, 0.2)), "far_low")
  expect_error(wet:::wet_source_pick(1, 1, far_low = NA_real_), "far_low")
  expect_error(wet:::wet_source_pick(1, 1, far_low = 1.5), "far_low")
  expect_error(wet:::wet_source_pick(-1, 1, far_low = 0.2), "negative")
  expect_error(wet:::wet_source_pick(1, -1, far_low = 0.2), "negative")
  expect_identical(wet:::wet_source_pick(numeric(), numeric(), far_low = 0.2), character())
})
