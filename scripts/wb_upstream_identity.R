# The province run with the snow layers (#16) against the run set aside before
# it: every upstream mean but the snow columns must agree.
#
#   Rscript scripts/wb_upstream_identity.R data/wb/_pre16/962a9cc2c4
#
# The snow layers are filled onto the analysis mask after it is fixed, so
# sampling and accumulating them cannot move any other column. This is what
# lets the fits carry their decision files (pooled_variant.txt,
# adjust_override.txt, and aet_decision.txt where one exists, #81) and the AET
# choice to the new key: the annual balance,
# and everything that chose them, reads the same numbers.
#
# "The same" is to rounding, not to the bit: wet_ws_fetch() takes the basin's
# polygons in whatever order PostgreSQL returns them, which follows the
# table's physical layout, so polygons sharing FWA codes are summed in another
# order once the database has changed (#76). Rows are matched on
# watershed_feature_id and every numeric column must agree to a relative
# 1e-10, with NA, NaN and infinite values in the same places and equal; the
# worst difference is reported. NA patterns, codes and the
# irregularly coded watersheds must be identical. Stops on the first basin that fails;
# writes the tracked report data/checks/wb_upstream_identity.txt.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
old <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(old) || !file.exists(file.path(old, "upstream", "_complete"))) {
  stop("name the set-aside province run (a directory with upstream/_complete)")
}
new <- wb_key_dir()
if (identical(normalizePath(old), normalizePath(new))) stop("the set-aside run is the current one")
snow_cols <- c("snowmelt_doy_50", "swe_max")
codes_old <- readLines(file.path(old, "upstream", "_complete"))
codes_new <- readLines(file.path(new, "upstream", "_complete"))
if (!identical(codes_old, codes_new)) stop("the two runs accumulated different basins")
# Largest relative difference between two numeric vectors, Inf unless their
# missing and non-finite entries match exactly (NA is not NaN, Inf is not -Inf)
rel_diff <- function(x, y) {
  if (length(x) != length(y) || !identical(is.finite(x), is.finite(y))) return(Inf)
  if (!identical(x[!is.finite(x)], y[!is.finite(y)])) return(Inf)
  f <- is.finite(x)
  big <- pmax(abs(x[f]), abs(y[f]))
  max(c(0, ifelse(big > 0, abs(x[f] - y[f]) / big, 0)))
}
n_rows <- 0
rel_tol <- 1e-10
worst <- list(r = 0, at = "")
for (code in codes_new) {
  a <- readRDS(file.path(old, "upstream", paste0(code, ".rds")))
  b <- readRDS(file.path(new, "upstream", paste0(code, ".rds")))
  if (!all(snow_cols %in% names(b))) stop(code, ": the new run has no snow columns")
  if (any(snow_cols %in% names(a))) stop(code, ": the set-aside run already has snow columns")
  if (anyNA(b[snow_cols][!is.na(b$p_yr), ])) stop(code, ": snow is NA where p_yr is not")
  if (nrow(a) != nrow(b) || anyDuplicated(b$watershed_feature_id) ||
        !setequal(a$watershed_feature_id, b$watershed_feature_id)) {
    stop(code, ": the two runs hold different watersheds")
  }
  b <- b[match(a$watershed_feature_id, b$watershed_feature_id), ]
  if (!all(names(a) %in% names(b))) {
    stop(code, ": the current run has no ", paste(setdiff(names(a), names(b)), collapse = ", "))
  }
  for (x in names(a)) {
    if (!identical(is.na(a[[x]]), is.na(b[[x]]))) stop(code, ": ", x, " is NA in different watersheds")
    if (is.numeric(a[[x]])) {
      r <- rel_diff(a[[x]], b[[x]])
      if (r > rel_tol) stop(code, ": ", x, " differs from the set-aside run by a relative ", format(r, digits = 3))
      if (r > worst$r) worst <- list(r = r, at = paste(code, x))
    } else if (!identical(a[[x]], b[[x]])) {
      stop(code, ": ", x, " differs from the set-aside run")
    }
  }
  # the irregularly coded watersheds, as sets (their order follows the fetch's too)
  if (!identical(sort(attr(a, "irregular")), sort(attr(b, "irregular")))) {
    stop(code, ": the irregularly coded watersheds differ from the set-aside run")
  }
  if (!setequal(setdiff(names(b), names(a)), snow_cols)) stop(code, ": the new run adds columns other than snow")
  n_rows <- n_rows + nrow(b)
}
writeLines(c(
  "# Upstream means with the snow layers (#16) against the run set aside before them", "",
  sprintf("set aside: %s", old), sprintf("current:   %s", new),
  sprintf("basins: %d; watersheds: %d", length(codes_new), n_rows),
  sprintf(paste("every column of the set-aside run agrees in the current one, rows matched on",
                "watershed_feature_id: codes, NA patterns and irregular watersheds identical,",
                "numbers to a relative %g"),
          rel_tol),
  sprintf("worst relative difference: %s (%s); the polygons come back in another order (#76)",
          format(worst$r, digits = 3), worst$at),
  sprintf("the current run adds %s", paste(snow_cols, collapse = " and ")),
  "snow has a value wherever p_yr does"
), "data/checks/wb_upstream_identity.txt")
message("agree: ", length(codes_new), " basins, ", n_rows, " watersheds; worst relative ", format(worst$r, digits = 3))
