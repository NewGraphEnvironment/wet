# Brute-force transcription of whse_basemapping.fwa_upstream(ltree x4), the
# polygon form, used only as a test oracle. String comparison must run under
# the C collation (ltree order = byte order for fixed-width FWA labels).
ltree_desc <- function(x, y) x == y | startsWith(x, paste0(y, "."))

fwa_upstream_r <- function(Wa, La, Wb, Lb) {
  if (Wa == La) {
    ltree_desc(Wb, Wa) & ltree_desc(Lb, La)
  } else {
    ltree_desc(Wb, Wa) & (
      (Wb > La & !ltree_desc(Wb, La) & ltree_desc(Lb, Wa) & Lb > La) |
        (Wb == Wa & Lb >= La))
  }
}

# Brute-force upstream sums of `col` and the irregular pairs, over all b.
brute_upstream <- function(ws, col = "area") {
  withr::local_collate("C")
  n <- nrow(ws)
  sums <- numeric(n)
  irr <- !(ws$localcode == ws$wscode | startsWith(ws$localcode, paste0(ws$wscode, ".")))
  pairs <- list()
  for (i in seq_len(n)) {
    up <- fwa_upstream_r(ws$wscode[i], ws$localcode[i], ws$wscode, ws$localcode)
    sums[i] <- sum(ws[[col]][up])
    j <- which(up & irr)
    if (length(j)) pairs[[length(pairs) + 1L]] <-
      data.frame(watershed_feature_id = ws$watershed_feature_id[i],
                 id_up = ws$watershed_feature_id[j])
  }
  list(sums = sums, pairs = do.call(rbind, c(list(
    data.frame(watershed_feature_id = integer(), id_up = integer())), pairs)))
}

lab <- function(k) sprintf("%06d", k)

# Random FWA-like tree: streams with tributaries at sorted positions; one
# polygon below the first tributary (W, W), one or more per reach (W, W.p);
# optionally deeper localcodes, tributaries under a stream that has no rows
# of its own, and irregular localcodes pointing into another branch.
random_ws <- function(seed, max_depth = 3, irregular = 3) {
  set.seed(seed)
  rows <- list()
  add <- function(w, l) rows[[length(rows) + 1L]] <<- c(w, l)
  grow <- function(w, depth, own_rows = TRUE) {
    k <- if (depth >= max_depth) 0L else sample(0:4, 1)
    pos <- sort(sample(1:999998, k))
    if (own_rows) {
      for (d in seq_len(sample(1:2, 1))) add(w, w)
      for (p in pos) for (d in seq_len(sample(1:2, 1))) add(w, paste(w, lab(p), sep = "."))
      if (k && runif(1) < 0.3) add(w, paste(w, lab(pos[1]), lab(sample(1:999998, 1)), sep = "."))
    }
    for (p in pos) grow(paste(w, lab(p), sep = "."), depth + 1L,
                        own_rows = runif(1) > 0.1)
  }
  grow("100", 0L)
  m <- do.call(rbind, rows)
  ws <- data.frame(watershed_feature_id = seq_len(nrow(m)), wscode = m[, 1],
                   localcode = m[, 2], area = sample(1:10000, nrow(m), TRUE))
  if (irregular && nrow(ws) > 3) {
    i <- sample(nrow(ws), min(irregular, nrow(ws) - 1))
    ws$localcode[i] <- sample(ws$wscode, length(i), TRUE)
    ws$localcode[i] <- ifelse(ws$localcode[i] == ws$wscode[i],
                              paste0("100.", lab(999999)), ws$localcode[i])
  }
  ws
}
