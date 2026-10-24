salr_like <- function() {
  # Salmon-shaped: mainstem 100.591289 with tribs at 001654 and 007448.
  data.frame(
    watershed_feature_id = 1:8,
    wscode = c("100.591289", "100.591289", "100.591289.001654",
               "100.591289", "100.591289.007448", "100.591289.007448",
               "100.591289", "100.591289"),
    localcode = c("100.591289", "100.591289.001654", "100.591289.001654",
                  "100.591289.006624", "100.591289.007448",
                  "100.591289.007448.260078", "100.591289.007448",
                  "100.591289.007448"),
    area = c(10, 20, 30, 40, 50, 60, 70, 80)
  )
}

test_that("matches the FWA_Upstream oracle on a Salmon-shaped tree", {
  ws <- salr_like()
  out <- wet_upstream_sums(ws, "area")
  expect_equal(out$watershed_feature_id, ws$watershed_feature_id)
  expect_equal(out$area, brute_upstream(ws)$sums)
  # the mouth polygon sees everything; trib 001654 only itself
  expect_equal(out$area[1], sum(ws$area))
  expect_equal(out$area[3], 30)
  # polygons sharing a position share the sum
  expect_equal(out$area[7], out$area[8])
  expect_length(attr(out, "irregular"), 0)
})

test_that("matches the oracle on random trees, irregular codes corrected by pairs", {
  for (seed in 1:40) {
    ws <- random_ws(seed)
    b <- brute_upstream(ws)
    got <- wet_upstream_sums(ws, "area", irregular_pairs = b$pairs)
    expect_equal(got$area, b$sums, info = paste("seed", seed))
  }
})

test_that("without pairs, irregular polygons are excluded and reported", {
  ws <- random_ws(7, irregular = 4)
  irr <- !(ws$localcode == ws$wscode | startsWith(ws$localcode, paste0(ws$wscode, ".")))
  expect_true(any(irr))
  expect_warning(got <- wet_upstream_sums(ws, "area"), "irregularly coded")
  expect_setequal(attr(got, "irregular"), ws$watershed_feature_id[irr])
  ws0 <- ws
  ws0$area[irr] <- 0
  expect_equal(got$area, brute_upstream(ws0)$sums)
})

test_that("several columns are summed independently", {
  ws <- random_ws(3, irregular = 0)
  ws$x <- ws$area * 2.5
  ws$y <- 1
  got <- wet_upstream_sums(ws, c("area", "x", "y"))
  expect_equal(got$x, got$area * 2.5)
  withr::local_collate("C")
  expect_equal(got$y, vapply(seq_len(nrow(ws)), function(i)
    sum(fwa_upstream_r(ws$wscode[i], ws$localcode[i], ws$wscode, ws$localcode)), 1))
})

test_that("result does not depend on the session collation", {
  ws <- random_ws(11)
  pairs <- brute_upstream(ws)$pairs
  b <- withr::with_collate("C", wet_upstream_sums(ws, "area", irregular_pairs = pairs))
  for (loc in c("en_US.UTF-8", "en_CA.UTF-8")) {
    ok <- tryCatch({ withr::local_collate(loc); TRUE }, warning = function(w) FALSE,
                   error = function(e) FALSE)
    if (!ok) next
    expect_equal(withr::with_collate(loc, wet_upstream_sums(ws, "area", irregular_pairs = pairs)), b)
  }
})

test_that("small headwaters keep precision next to a huge basin total", {
  ws <- salr_like()
  ws$area <- c(2e11, 1e3, 1.5e3, 2e11, 1, 2, 3e11, 4e11)
  got <- wet_upstream_sums(ws, "area")
  expect_identical(got$area[3], 1.5e3)
  expect_identical(got$area[6], 2)
})

test_that("inputs are checked", {
  ws <- salr_like()
  expect_error(wet_upstream_sums(ws[, -2], "area"), "wscode")
  bad <- ws; bad$area[1] <- NA
  expect_error(wet_upstream_sums(bad, "area"), "must not be NA")
  bad <- ws; bad$localcode[1] <- NA
  expect_error(wet_upstream_sums(bad, "area"), "must not be NA")
  expect_error(wet_upstream_sums(ws, "area", irregular_pairs =
    data.frame(watershed_feature_id = 1L, id_up = 2L)), "irregular")
})

test_that("incomplete or duplicated irregular pairs are refused", {
  ws <- random_ws(7, irregular = 4)
  b <- brute_upstream(ws)
  irr <- unique(b$pairs$id_up)
  expect_true(length(irr) >= 2)
  expect_error(wet_upstream_sums(ws, "area", irregular_pairs = b$pairs[0, ]), "have no pairs")
  expect_error(wet_upstream_sums(ws, "area",
    irregular_pairs = b$pairs[b$pairs$id_up != irr[1], ]), "have no pairs")
  expect_error(wet_upstream_sums(ws, "area",
    irregular_pairs = rbind(b$pairs, b$pairs[1, ])), "duplicate")
  # a basin with no irregular polygons accepts an empty table silently
  clean <- random_ws(3, irregular = 0)
  expect_no_warning(wet_upstream_sums(clean, "area",
    irregular_pairs = data.frame(watershed_feature_id = integer(), id_up = integer())))
})

# Three polygons at one FWA position (rows 7, 8 and a ninth), with values whose
# double sum depends on the order they are added in: 1e16 + 1 is 1e16.
order_ws <- function() {
  ws <- salr_like()
  ws <- rbind(ws, ws[8, ])
  ws$watershed_feature_id[9] <- 9L
  ws$area[7:9] <- c(1e16, 1, -1e16)
  ws
}

test_that("sums do not depend on the row order of ws", {
  ws <- order_ws()
  # the fixture reaches the failure mode: the order changes the double. Reduce()
  # adds in plain double as rowsum() does; sum() may use long double.
  expect_false(identical(Reduce(`+`, ws$area[7:9]), Reduce(`+`, ws$area[c(7, 9, 8)])))
  ref <- wet_upstream_sums(ws, "area")
  perms <- list(c(1:6, 7, 9, 8), c(1:6, 8, 7, 9), c(1:6, 9, 8, 7), rev(1:9), c(9, 3, 7, 1, 8, 2, 6, 4, 5))
  for (p in perms) {
    got <- wet_upstream_sums(ws[p, ], "area")
    expect_identical(got$area[match(ref$watershed_feature_id, got$watershed_feature_id)], ref$area,
                     info = paste(p, collapse = " "))
  }
})

test_that("sums do not depend on the row order of irregular_pairs", {
  # rows 2-4 are irregular (localcode beside, not under, wscode) and upstream of
  # the mouth, so the mouth's sum adds all three from the pairs
  ws <- data.frame(watershed_feature_id = 1:4,
                   wscode = c("100", rep("100.000500", 3)),
                   localcode = c("100", rep("100.000400", 3)),
                   area = c(0, 1e16, 1, -1e16))
  pairs <- brute_upstream(ws)$pairs
  expect_equal(sort(pairs$id_up[pairs$watershed_feature_id == 1L]), 2:4)
  ref <- wet_upstream_sums(ws, "area", irregular_pairs = pairs)
  # the mouth's pairs come first (2, 3, 4); adding them as 2, 4, 3 changes the double
  expect_identical(pairs$id_up[1:3], 2:4)
  n <- nrow(pairs)
  for (p in list(c(1, 3, 2, 4:n), rev(seq_len(n)), c(3, 1, 2, 4:n))) {
    got <- wet_upstream_sums(ws, "area", irregular_pairs = pairs[p, ])
    expect_identical(got$area, ref$area, info = paste(p, collapse = " "))
  }
  # and of ws, which numbers the pairs' rows: summing by position in ws would
  # add the mouth's pairs as 2, 4, 3 here
  for (p in list(c(1, 2, 4, 3), 4:1)) {
    got <- wet_upstream_sums(ws[p, ], "area", irregular_pairs = pairs)
    expect_identical(got$area[match(1:4, got$watershed_feature_id)], ref$area,
                     info = paste(p, collapse = " "))
  }
})

test_that("a basin from fwapg sums the same in any row order", {
  conn <- local_fwapg()
  ws <- wet_ws_fetch(conn, "925")
  irr <- wet_upstream_irregular(conn, "925")
  # the fetches come back in id order, so two runs see the same rows
  expect_identical(ws$watershed_feature_id, sort(ws$watershed_feature_id))
  expect_identical(irr, irr[order(irr$watershed_feature_id, irr$id_up), , drop = FALSE])
  ws$one <- 1
  ref <- wet_upstream_sums(ws, c("area_m2", "one"), irregular_pairs = irr)
  set.seed(76)
  p <- sample(nrow(ws))
  q <- sample(nrow(irr))
  got <- wet_upstream_sums(ws[p, ], c("area_m2", "one"), irregular_pairs = irr[q, ])
  got <- got[match(ref$watershed_feature_id, got$watershed_feature_id), ]
  rownames(got) <- NULL
  attr(got, "irregular") <- attr(ref, "irregular") <- NULL
  expect_identical(got, ref)
})
