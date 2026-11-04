test_that("roots are the codes with no proper ancestor in the set", {
  w <- c("100.190442.244975", "100.190442", "100.190442.999094.000001",
         "300.625474.584724", "300.625474.584724.100997", "100.190443", NA, "100.190442")
  expect_identical(wet_ws_roots(w), c("100.190442", "100.190443", "300.625474.584724"))
  # a label boundary, not a string prefix: siblings are both roots
  expect_identical(wet_ws_roots(c("100.190442", "100.190442.000001", "100.190443.000001")),
                   c("100.190442", "100.190443.000001"))
  # a basin root covers everything under it
  expect_identical(wet_ws_roots(c("100.000001", "100", "100.000001.000002")), "100")
  expect_identical(wet_ws_roots(character()), character())
  expect_identical(wet_ws_roots(NA_character_), character())
  expect_error(wet_ws_roots("100.1904"), "not an FWA watershed code")
  expect_error(wet_ws_roots(100), "character")
})

test_that("roots do not depend on input order or the session collation", {
  w <- c("920.000002", "100.190442", "920.000002.000005", "100.190442.244975", "200")
  expect_identical(wet_ws_roots(rev(w)), wet_ws_roots(w))
  for (loc in c("C", "en_US.UTF-8", "en_CA.UTF-8")) {
    ok <- tryCatch(withr::with_collate(loc, TRUE), warning = function(w) FALSE, error = function(e) FALSE)
    if (!ok) next
    expect_identical(withr::with_collate(loc, wet_ws_roots(w)), c("100.190442", "200", "920.000002"))
  }
})

test_that("sums over a group's closure equal the whole tree's for the closure's rows", {
  withr::local_collate("C")
  for (seed in 1:40) {
    ws <- random_ws(seed)
    b <- brute_upstream(ws)
    # a "group": a few random rows, wherever they sit in the tree
    set.seed(seed + 1000)
    grp <- ws$watershed_feature_id[sample(nrow(ws), min(3, nrow(ws)))]
    roots <- wet_ws_roots(ws$wscode[ws$watershed_feature_id %in% grp])
    under <- Reduce(`|`, lapply(roots, function(r) ltree_desc(ws$wscode, r)))
    cl <- ws[under, ]
    expect_true(all(grp %in% cl$watershed_feature_id), info = paste("seed", seed))
    pairs <- b$pairs[b$pairs$id_up %in% cl$watershed_feature_id, ]
    got <- wet_upstream_sums(cl, "area", irregular_pairs = pairs)
    expect_equal(got$area, b$sums[under], info = paste("seed", seed))
    # and the closure is upstream-closed: no row in it counts a row outside it
    for (i in which(under)) {
      up <- fwa_upstream_r(ws$wscode[i], ws$localcode[i], ws$wscode, ws$localcode)
      expect_true(all(under[up]), info = paste("seed", seed, "row", i))
    }
  }
})

test_that("a closure missing part of the subtree gives different sums", {
  # the guard the group build's parity check relies on: drop a subtree and
  # the rows below it lose its area
  withr::local_collate("C")
  ws <- random_ws(11, irregular = 0)
  b <- brute_upstream(ws)
  deep <- ws$wscode[nchar(ws$wscode) > 3][1]
  cut <- !ltree_desc(ws$wscode, deep)
  got <- wet_upstream_sums(ws[cut, ], "area")
  expect_false(isTRUE(all.equal(got$area, b$sums[cut])))
})

test_that("BULK's closure is BULK and MORR under one root, as the root's fetch", {
  conn <- local_fwapg()
  ws <- wet_ws_closure(conn, "BULK")
  expect_identical(attr(ws, "wsg"), "BULK")
  expect_identical(attr(ws, "roots"), "400.431358")
  expect_identical(attr(ws, "groups"), c("BULK", "MORR"))
  expect_identical(attr(ws, "codes"), "400")
  ref <- wet_ws_fetch(conn, "400.431358")
  expect_identical(as.data.frame(lapply(ws, identity)), as.data.frame(lapply(ref, identity)))
  irr <- attr(ws, "irregular")
  expect_identical(irr[irr$id_up %in% ws$watershed_feature_id, ], irr)
  expect_error(wet_ws_closure(conn, "bulk"), "one watershed group code")
  expect_error(wet_ws_closure(conn, "ZZZZ"), "no coded polygons")
})

test_that("in basin 925 each group's closure sums equal the basin's for its rows", {
  conn <- local_fwapg()
  basin <- wet_ws_fetch(conn, "925")
  s_basin <- wet_upstream_sums(basin, "area_m2", irregular_pairs = wet_upstream_irregular(conn, "925"))
  groups <- sort(unique(basin$watershed_group_code))
  expect_identical(groups, c("COWN", "PARK", "VICT"))
  for (g in groups) {
    ws <- wet_ws_closure(conn, g)
    expect_true("925" %in% attr(ws, "codes"), info = g)
    s <- wet_upstream_sums(ws, "area_m2", irregular_pairs = attr(ws, "irregular"))
    ids <- basin$watershed_feature_id[basin$watershed_group_code == g]
    expect_equal(s$area_m2[match(ids, s$watershed_feature_id)],
                 s_basin$area_m2[match(ids, s_basin$watershed_feature_id)], info = g)
  }
})
