#' Upstream sums of additive quantities for every fundamental watershed
#'
#' Sums each column in `cols` over the set of polygons that fwapg's
#' `FWA_Upstream(wscode_a, localcode_a, wscode_b, localcode_b)` counts as
#' upstream of each watershed `a` (including `a` itself), without
#' materialising (watershed, upstream polygon) pairs.
#'
#' FWA codes are dotted labels of fixed width per level (3 digits at the root,
#' 6 below), so ltree order equals C-locale byte order of the strings, and the
#' `FWA_Upstream` set of `a = (W, L)` is at most two contiguous ranges of the
#' polygons sorted by `(wscode, localcode)`:
#'
#' * `W == L`: the subtree of `W`, i.e. `wscode` in `[W, W/)`;
#' * `W != L`: `wscode == W & localcode >= L`, union `wscode` in `[L/, W/)`
#'   (the tributaries above position `L`, with their subtrees).
#'
#' This holds for every upstream polygon `b` whose `localcode` equals or lies
#' under its `wscode`. `FWA_Upstream` treats polygons that break that rule
#' differently (its localcode guards), so they are left out of the ranges and
#' added back from `irregular_pairs`, the exact `FWA_Upstream` pairs for them
#' (see [wet_upstream_irregular()]). Without `irregular_pairs` they are
#' excluded with a warning, and their ids are returned in the `"irregular"`
#' attribute. Pairs that name no row at all for some irregular polygon (pairs
#' from another basin, an empty table) or repeat a row are an error. That
#' check cannot see a table that keeps each polygon's self pair but loses
#' others, so pass [wet_upstream_irregular()] output whole, not filtered.
#'
#' `ws` must be a whole basin: every polygon upstream of any row must be in
#' it (e.g. [wet_ws_fetch()] for a basin root such as `"100"`). A single
#' watershed group is not enough; missing upstream polygons simply drop out
#' of the sums.
#'
#' Range sums use a segment tree rather than differences of prefix sums, so a
#' 1,000 m2 headwater is not the small difference of two 1e11 m2 totals.
#'
#' @param ws `data.frame` with `watershed_feature_id`, `wscode`, `localcode`
#'   (FWA ltree codes as text) and the numeric columns named in `cols`.
#' @param cols Character. Additive columns to sum (no `NA`).
#' @param irregular_pairs Optional `data.frame(watershed_feature_id, id_up)`:
#'   `FWA_Upstream` pairs whose upstream polygon `id_up` is irregular.
#' @return `data.frame(watershed_feature_id, <cols>)` of upstream sums, one row
#'   per input row, with attribute `"irregular"` (ids of irregular polygons).
#' @export
wet_upstream_sums <- function(ws, cols, irregular_pairs = NULL) {
  need <- c("watershed_feature_id", "wscode", "localcode", cols)
  miss <- setdiff(need, names(ws))
  if (length(miss)) stop("ws is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  stopifnot(is.character(cols), length(cols) >= 1L,
            !anyDuplicated(ws$watershed_feature_id))
  W <- as.character(ws$wscode)
  L <- as.character(ws$localcode)
  if (anyNA(W) || anyNA(L)) stop("wscode and localcode must not be NA", call. = FALSE)
  vals <- as.matrix(ws[, cols, drop = FALSE])
  storage.mode(vals) <- "double"
  if (anyNA(vals)) stop("columns in cols must not be NA", call. = FALSE)

  valid <- L == W | startsWith(L, paste0(W, "."))

  # Positions of valid polygons, sorted by (wscode, localcode). A space sorts
  # before "." and "/", so "W L" keys order exactly as (W, L) does.
  kb <- paste(W[valid], L[valid])
  uk <- unique(kb[order(kb, method = "radix")])
  pos <- rowsum(vals[valid, , drop = FALSE], match(kb, uk), reorder = TRUE)
  trees <- lapply(seq_len(ncol(pos)), function(j) wet_seg_build(pos[, j]))

  # Query each distinct (W, L) once.
  ka <- paste(W, L)
  qa <- !duplicated(ka)
  Wq <- W[qa]
  Lq <- L[qa]
  eq <- Wq == Lq
  lt <- function(q) wet_count_lt(uk, q)

  sub_lo <- lt(Wq)
  sub_hi <- lt(paste0(Wq, "/"))
  # W != L: R1 = own rows at or above L; R2 = [L/, W/) clipped to W's subtree.
  r1_lo <- lt(paste(Wq, Lq))
  r1_hi <- lt(paste0(Wq, "!"))
  r2_lo <- pmax(lt(paste0(Lq, "/")), sub_lo)
  r2_hi <- sub_hi
  ix_lo <- pmax(r1_lo, r2_lo)
  ix_hi <- pmin(r1_hi, r2_hi)

  out <- vapply(trees, function(tr) {
    s_sub <- wet_seg_query(tr, sub_lo, sub_hi)
    s_r <- wet_seg_query(tr, r1_lo, r1_hi) + wet_seg_query(tr, r2_lo, r2_hi) -
      wet_seg_query(tr, ix_lo, ix_hi)
    ifelse(eq, s_sub, s_r)
  }, numeric(sum(qa)))
  if (!is.matrix(out)) out <- matrix(out, nrow = sum(qa))
  res <- out[match(ka, ka[qa]), , drop = FALSE]

  irregular <- ws$watershed_feature_id[!valid]
  if (is.null(irregular_pairs)) {
    if (length(irregular)) {
      warning(length(irregular), " irregularly coded polygons are left out of the upstream ",
              "sums; pass irregular_pairs = wet_upstream_irregular(conn, wscode) to match ",
              "FWA_Upstream", call. = FALSE)
    }
  } else {
    stopifnot(all(c("watershed_feature_id", "id_up") %in% names(irregular_pairs)))
    if (!all(irregular_pairs$id_up %in% irregular)) {
      stop("irregular_pairs$id_up must be irregular polygons in ws", call. = FALSE)
    }
    if (anyDuplicated(irregular_pairs[, c("watershed_feature_id", "id_up")])) {
      stop("irregular_pairs has duplicate rows", call. = FALSE)
    }
    # Every irregular polygon is upstream of itself under FWA_Upstream (its own
    # row satisfies wscode = wscode and localcode >= localcode), so a complete
    # pairs table names every one of them. Anything less is pairs from another
    # basin or a partial fetch, and would silently drop ground.
    miss <- setdiff(irregular, irregular_pairs$id_up)
    if (length(miss)) {
      stop(length(miss), " irregular polygons have no pairs (e.g. ", miss[1],
           "); irregular_pairs must come from the same basin as ws", call. = FALSE)
    }
    ia <- match(irregular_pairs$watershed_feature_id, ws$watershed_feature_id)
    ib <- match(irregular_pairs$id_up, ws$watershed_feature_id)
    keep <- !is.na(ia)
    if (any(keep)) {
      add <- rowsum(vals[ib[keep], , drop = FALSE], ia[keep])
      rows <- as.integer(rownames(add))
      res[rows, ] <- res[rows, , drop = FALSE] + add
    }
  }

  res <- as.data.frame(res)
  names(res) <- cols
  res <- cbind(data.frame(watershed_feature_id = ws$watershed_feature_id), res)
  attr(res, "irregular") <- irregular
  res
}

# Number of elements of sorted character vector `s` strictly less than each
# query, in C-locale byte order (radix sort), without locale collation.
wet_count_lt <- function(s, q) {
  n <- length(s)
  key <- c(q, s)
  # ties: queries before elements, so an equal element is not counted as less
  o <- order(key, c(rep(0L, length(q)), rep(1L, n)), method = "radix")
  is_s <- o > length(q)
  cum <- cumsum(is_s)
  res <- integer(length(q))
  res[o[!is_s]] <- cum[!is_s]
  res
}

# Segment tree over x for 0-based half-open range sums [lo, hi). Stored
# 1-based: node i (0-based) lives at tree[i + 1]; leaves are nodes n..2n-1.
# Built one level at a time so no R loop runs per node.
wet_seg_build <- function(x) {
  n <- 1L
  while (n < length(x)) n <- n * 2L
  tree <- numeric(2L * n)
  tree[n + seq_along(x)] <- x
  k <- n %/% 2L
  while (k >= 1L) {
    i <- k:(2L * k - 1L)
    tree[i + 1L] <- tree[2L * i + 1L] + tree[2L * i + 2L]
    k <- k %/% 2L
  }
  list(tree = tree, n = n)
}

wet_seg_query <- function(tr, lo, hi) {
  res <- numeric(length(lo))
  ok <- hi > lo
  l <- lo[ok] + tr$n
  r <- hi[ok] + tr$n
  acc <- numeric(length(l))
  while (any(l < r)) {
    act <- l < r
    take_l <- act & (l %% 2L == 1L)
    acc[take_l] <- acc[take_l] + tr$tree[l[take_l] + 1L]
    l[take_l] <- l[take_l] + 1L
    take_r <- act & (r %% 2L == 1L)
    r[take_r] <- r[take_r] - 1L
    acc[take_r] <- acc[take_r] + tr$tree[r[take_r] + 1L]
    l <- l %/% 2L
    r <- r %/% 2L
  }
  res[ok] <- acc
  res
}
