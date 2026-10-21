# A three-sub-basin network: 1 and 2 drain into 3. Each sub-basin's q_acc is
# its flow at its outlet, q_local its own runoff. The days are a 1981-2010
# climatology: 30 years on every bin, 7 on 29 February.
routed_network <- function() {
  md <- c(wet:::wet_doy_md(), "02-29")
  bins <- data.frame(month = as.integer(substr(md, 1, 2)), day = as.integer(substr(md, 4, 5)))
  bins$n_days <- ifelse(md == "02-29", 7L, 30L)
  base <- c(`1` = 1, `2` = 2, `3` = 10)
  d <- do.call(rbind, lapply(names(base), function(s) {
    t <- seq_len(366)
    data.frame(subid = as.integer(s), bins, q_local = base[[s]] / 2 + 0.4 * sin(t / 50),
               q_acc = base[[s]] + t / 100)
  }))
  # sub-basin 2 loses water on 1 June
  d$q_local[d$subid == 2 & d$month == 6 & d$day == 1] <- -5
  w <- data.frame(linear_feature_id = c(101, 102, 103, 104), subid = c(1L, 3L, 2L, 3L),
                  share = c(0.5, 0.2, 0.9, 0.7))
  w$upstream_subids <- list(integer(), c(1L, 2L), integer(), c(2L, 1L))
  list(d = d, w = w, md = md)
}

test_that("the fold puts 29 February into 28 February by n_days, and nothing else moves", {
  x <- routed_network()
  f <- wet:::wet_routed_fold(x$d[sample(nrow(x$d)), ])  # row order does not matter
  expect_equal(f$subid, 1:3)
  expect_equal(dim(f$q_acc), c(3L, 365L))
  d3 <- x$d[x$d$subid == 3, ]
  q28 <- d3$q_acc[d3$month == 2 & d3$day == 28]
  q29 <- d3$q_acc[d3$month == 2 & d3$day == 29]
  expect_equal(f$q_acc[3, 59], (q28 * 30 + q29 * 7) / 37)
  expect_equal(f$n_days[59], 37)
  expect_equal(f$n_days[-59], rep(30, 364))
  expect_equal(f$q_local[3, 60], d3$q_local[d3$month == 3 & d3$day == 1])
  expect_equal(f$q_acc[3, 365], d3$q_acc[d3$month == 12 & d3$day == 31])
  # a whole-February mean is the same before and after the fold
  feb <- d3[d3$month == 2, ]
  expect_equal(sum(f$q_acc[3, 32:59] * f$n_days[32:59]) / sum(f$n_days[32:59]),
               sum(feb$q_acc * feb$n_days) / sum(feb$n_days))
})

test_that("the fold refuses a missing bin, a duplicate, an NA or unequal days", {
  x <- routed_network()
  expect_error(wet:::wet_routed_fold(x$d[-5, ]), "366 calendar bins")
  expect_error(wet:::wet_routed_fold(rbind(x$d, x$d[5, ])), "366 calendar bins")
  d <- x$d
  d$q_acc[3] <- NA
  expect_error(wet:::wet_routed_fold(d), "NA")
  d <- x$d
  d$n_days[d$subid == 2 & d$month == 1 & d$day == 1] <- 29L
  expect_error(wet:::wet_routed_fold(d), "n_days differ")
  d <- x$d
  d$day[1] <- 32L
  expect_error(wet:::wet_routed_fold(d), "calendar day")
})

test_that("a segment's day is its upstream q_acc plus its share of local flow, clamped and rounded", {
  x <- routed_network()
  f <- wet:::wet_routed_fold(x$d)
  raw <- wet:::wet_routed_raw(f, x$w)
  expect_equal(dim(raw), c(4L, 365L))
  # a headwater segment: its share of local flow only
  expect_equal(raw[1, ], f$q_local[1, ] * 0.5)
  # below sub-basins 1 and 2: their outlet flows plus 0.2 of 3's own
  expect_equal(raw[2, ], f$q_acc[1, ] + f$q_acc[2, ] + 0.2 * f$q_local[3, ])
  # the same upstream set in another order gives the same flow
  expect_equal(raw[4, ] - 0.7 * f$q_local[3, ], raw[2, ] - 0.2 * f$q_local[3, ])
  q <- wet:::wet_routed_days(f, x$w)
  jun1 <- which(wet:::wet_doy_md() == "06-01")
  expect_lt(raw[3, jun1], 0)
  expect_identical(q[3, jun1], 0)
  expect_identical(attr(q, "clamped")[3, jun1], TRUE)
  expect_equal(sum(attr(q, "clamped")), 1L)
  expect_equal(q[2, ], round(raw[2, ], 5))
  expect_true(all(q == round(q, 5)))
})

test_that("routing a period's mean equals the mean of the routed days, as fwapg's tables rely on", {
  x <- routed_network()
  f <- wet:::wet_routed_fold(x$d)
  m <- wet:::wet_doy_month()
  raw <- wet:::wet_routed_raw(f, x$w)
  by_month <- wet:::wet_routed_raw(wet:::wet_routed_period(f, m), x$w)
  from_days <- t(apply(raw, 1, function(r) tapply(r * f$n_days, m, sum) / tapply(f$n_days, m, sum)))
  expect_equal(unname(by_month), unname(from_days))
  # and against the unfolded bins, as fwapg averages them
  d1 <- x$d[x$d$subid == 1, ]
  expect_equal(by_month[1, 2], 0.5 * sum(d1$q_local[d1$month == 2] * d1$n_days[d1$month == 2]) / (27 * 30 + 30 + 7))
})

test_that("weights naming an unknown sub-basin, or with an NA share, are refused", {
  x <- routed_network()
  f <- wet:::wet_routed_fold(x$d)
  w <- x$w
  w$upstream_subids[[2]] <- c(1L, 9L)
  expect_error(wet:::wet_routed_raw(f, w), "does not hold")
  w <- x$w
  w$share[1] <- NA
  expect_error(wet:::wet_routed_raw(f, w), "NA subid or share")
  expect_error(wet:::wet_routed_raw(f, x$w[c("linear_feature_id", "subid")]), "needs columns")
})

test_that("rounding is Postgres's numeric rounding: half away from zero on the 15-digit decimal", {
  # 2.675 is stored as 2.67499999999999982236431605997495353221893310546875;
  # its 15-digit decimal is 2.67500000000000, which Postgres rounds up
  expect_identical(wet:::wet_routed_round(2.675e-3 / 1e-3 * 1e-3), 0.00268)
  expect_identical(wet:::wet_routed_round(0.123455), 0.12346)
  expect_identical(wet:::wet_routed_round(1234.123455), 1234.12346)
  expect_identical(wet:::wet_routed_round(0.1234549), 0.12345)
  expect_identical(wet:::wet_routed_round(0.99999951), 1)
  # above 10,000 a double can sit a few 1e-11 below its 15-digit tie
  expect_identical(wet:::wet_routed_round(12213.315444999958), 12213.31545)
  expect_identical(wet:::wet_routed_round(c(0, 5e-6, 4.9e-6, NA)), c(0, 1e-5, 0, NA))
  set.seed(1)
  v <- stats::runif(1e4, 0, 1e4)
  expect_identical(wet:::wet_routed_round(v), round(v, 5))  # away from ties, R's round()
})
