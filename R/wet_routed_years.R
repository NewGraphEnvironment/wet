#' Routed PCIC flow on FWA segments, day by day and year by year
#'
#' Gives each segment's routed PCIC flow (m3/s) for every day of the years
#' asked, from PCIC's per-year sub-basin flows, so a window statistic can be
#' taken in each year rather than from a climatology. A segment's flow on a
#' day is
#'
#' `max(sum(q_acc of upstream_subids) + q_local(subid) * share, 0)`,
#'
#' rounded to 5 decimals, the routing and rounding fwapg uses for the daily
#' climatology it publishes, applied to one day of one year instead of a mean
#' over years.
#'
#' The sub-basin flows are read through duckdb from parquet files under
#' `dir`, one row per sub-basin and calendar day: `subid`, `year`, `month`,
#' `day`, `q_local` and `q_acc` (m3/s). Only the sub-basins `weights` names
#' are read. Each must hold every day of `years` once, with no missing flow.
#'
#' @param dir Directory holding the per-year sub-basin flows as parquet,
#'   searched recursively.
#' @param weights `data.frame(linear_feature_id, subid, share,
#'   upstream_subids)`, one row per segment, as fwapg's
#'   `pcic.segment_weights`: `upstream_subids` is a list of integer vectors.
#' @param years Years to route.
#' @return `data.frame(linear_feature_id, date, q_m3s)`, one row per segment
#'   and day, ordered by segment and date, in [wet_station_daily()]'s layout,
#'   so [wet_window_stats()] takes it with `by = "linear_feature_id"`.
#' @examples
#' if (requireNamespace("duckdb", quietly = TRUE)) {
#'   fx <- system.file("extdata", "pcic_years", package = "wet")
#'   w <- read.csv(file.path(fx, "weights.csv"), colClasses = c(upstream_subids = "character"))
#'   w$upstream_subids <- lapply(strsplit(w$upstream_subids, ";", fixed = TRUE), as.integer)
#'   q <- wet_routed_years(file.path(fx, "days"), w, years = 1981:1990)
#'   head(q)
#'   # the Chinook migration window's mean flow on each segment, year by year
#'   win <- data.frame(window = "migration", start = "05-01", end = "08-01")
#'   s <- wet_window_stats(q, win, stats = "mean", by = "linear_feature_id")
#'   head(s[c("linear_feature_id", "year", "value")])
#' }
#' @export
wet_routed_years <- function(dir, weights, years = 1951:2012) {
  if (!requireNamespace("duckdb", quietly = TRUE)) stop("install duckdb to read the per-year flows", call. = FALSE)
  if (!is.character(dir) || length(dir) != 1 || !dir.exists(dir)) stop("`dir` must be an existing directory", call. = FALSE)
  need <- c("linear_feature_id", "subid", "share", "upstream_subids")
  if (!is.data.frame(weights) || !all(need %in% names(weights)) || !is.list(weights$upstream_subids)) {
    stop("`weights` needs columns ", paste(need, collapse = ", "), ", upstream_subids a list", call. = FALSE)
  }
  if (!nrow(weights)) stop("`weights` has no rows", call. = FALSE)
  if (anyNA(weights$linear_feature_id) || anyDuplicated(weights$linear_feature_id)) {
    stop("`weights` must name each segment once", call. = FALSE)
  }
  if (!is.numeric(years) || !length(years) || anyNA(years) || any(years != round(years)) || anyDuplicated(years)) {
    stop("`years` must be distinct whole years", call. = FALSE)
  }
  years <- sort(as.integer(years))
  files <- list.files(dir, "\\.parquet$", recursive = TRUE, full.names = TRUE)
  if (!length(files)) stop("`dir` holds no parquet files", call. = FALSE)

  subid <- sort(unique(as.integer(c(weights$subid, unlist(weights$upstream_subids, use.names = FALSE)))))
  if (anyNA(subid)) stop("`weights` has an NA subid", call. = FALSE)
  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE), add = TRUE)
  d <- DBI::dbGetQuery(duck, sprintf(
    "SELECT subid, year, month, day, q_local, q_acc FROM read_parquet([%s], hive_partitioning = false)
     WHERE subid IN (%s) AND year IN (%s) ORDER BY subid, year, month, day",
    wet_sql_in(duck, files), paste(subid, collapse = ", "), paste(years, collapse = ", ")))

  absent <- setdiff(subid, d$subid)
  if (length(absent)) {
    stop("the per-year flows have no rows in ", min(years), "-", max(years), " for sub-basin ",
         paste(utils::head(absent, 10), collapse = ", "), if (length(absent) > 10) ", ...", call. = FALSE)
  }
  if (anyNA(d)) stop("the per-year flows have an NA value", call. = FALSE)
  date <- as.Date(sprintf("%04d-%02d-%02d", as.integer(d$year), as.integer(d$month), as.integer(d$day)),
                  format = "%Y-%m-%d")
  if (anyNA(date)) stop("the per-year flows have a year, month and day that is not a calendar date", call. = FALSE)
  dates <- do.call(c, lapply(years, function(y) {
    seq(as.Date(sprintf("%d-01-01", y)), as.Date(sprintf("%d-12-31", y)), by = "day")
  }))
  row <- match(as.integer(d$subid), subid)
  col <- match(date, dates)
  if (anyDuplicated(cbind(row, col))) stop("the per-year flows hold a sub-basin's day more than once", call. = FALSE)
  short <- subid[tabulate(row, length(subid)) != length(dates)]
  if (length(short)) {
    stop("the per-year flows lack days of ", min(years), "-", max(years), " for sub-basin ",
         paste(utils::head(short, 10), collapse = ", "), if (length(short) > 10) ", ...", call. = FALSE)
  }
  grid <- function(v) {
    m <- matrix(NA_real_, length(subid), length(dates))
    m[cbind(row, col)] <- as.numeric(v)
    m
  }
  q <- wet_routed_days(list(subid = subid, q_local = grid(d$q_local), q_acc = grid(d$q_acc)), weights)
  out <- data.frame(linear_feature_id = rep(weights$linear_feature_id, times = length(dates)),
                    date = rep(dates, each = nrow(weights)), q_m3s = as.vector(q))
  out <- out[order(out$linear_feature_id, out$date), ]
  rownames(out) <- NULL
  out
}
