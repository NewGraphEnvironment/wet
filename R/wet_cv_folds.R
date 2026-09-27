#' Cross-validation folds for gauges on one stream network
#'
#' Assigns each station a fold for blocked cross-validation and describes how
#' much a held-out station can still "see" of itself through the stations
#' left in training, which is what makes plain leave-one-out optimistic on
#' nested gauges.
#'
#' * `fold`: the block, by default the WSC sub-sub-drainage (the first four
#'   characters of the station number, e.g. `08MF`). All stations in a block
#'   are held out together. `block = "station"` gives plain leave-one-out.
#' * `nesting`: `"headwater"` when no other station is upstream on the FWA
#'   network, `"nested"` otherwise.
#' * `leak_up`: the largest share of the station's upstream area that a
#'   station in another fold gauges upstream of it (0 when none), so the
#'   training set already knows that much of the held-out basin.
#' * `leak_down`: `TRUE` when a station in another fold is downstream, so its
#'   training residual includes the held-out basin.
#'
#' Upstream is fwapg's `FWA_Upstream()` between the stations' fundamental
#' watersheds (codes compared in C-locale order, as FWA codes require).
#'
#' @param stations `data.frame(station_number, wscode, localcode,
#'   upstream_area_km2)`, one row per station (e.g. accepted rows of
#'   [wet_station_snap()]).
#' @param block `"subsubdrainage"` or `"station"`.
#' @return `stations[, "station_number"]` with `fold`, `nesting`, `leak_up`,
#'   `leak_down`.
#' @export
wet_cv_folds <- function(stations, block = c("subsubdrainage", "station")) {
  block <- match.arg(block)
  need <- c("station_number", "wscode", "localcode", "upstream_area_km2")
  miss <- setdiff(need, names(stations))
  if (length(miss)) stop("stations is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (anyDuplicated(stations$station_number)) stop("duplicate station_number", call. = FALSE)
  if (anyNA(stations[need])) stop("stations has NA in ", paste(need, collapse = ", "), call. = FALSE)
  n <- nrow(stations)
  fold <- if (block == "station") stations$station_number else substr(stations$station_number, 1, 4)
  # up[i, j]: station j is upstream of station i (j != i)
  up <- matrix(FALSE, n, n)
  for (i in seq_len(n)) {
    up[i, ] <- wet_fwa_upstream(stations$wscode[i], stations$localcode[i],
                                stations$wscode, stations$localcode)
  }
  diag(up) <- FALSE
  area <- stations$upstream_area_km2
  other <- outer(fold, fold, "!=")
  lu <- up & other
  leak_up <- vapply(seq_len(n), function(i) {
    if (any(lu[i, ])) max(area[lu[i, ]]) / area[i] else 0
  }, numeric(1))
  data.frame(station_number = stations$station_number, fold = fold,
             nesting = ifelse(rowSums(up) > 0, "nested", "headwater"),
             leak_up = pmin(leak_up, 1),
             leak_down = colSums(up & other) > 0)
}

# fwapg's FWA_Upstream(wscode_a, localcode_a, wscode_b, localcode_b) for one
# watershed a against vectors b: TRUE where b is upstream of (or is) a. FWA
# codes are fixed-width dotted labels, so byte order is ltree order.
wet_fwa_upstream <- function(wa, la, wb, lb) {
  old <- Sys.getlocale("LC_COLLATE")
  on.exit(Sys.setlocale("LC_COLLATE", old), add = TRUE)
  Sys.setlocale("LC_COLLATE", "C")
  desc <- function(x, y) x == y | startsWith(x, paste0(y, "."))
  if (wa == la) {
    desc(wb, wa) & desc(lb, la)
  } else {
    desc(wb, wa) & ((wb > la & !desc(wb, la) & desc(lb, wa) & lb > la) | (wb == wa & lb >= la))
  }
}
