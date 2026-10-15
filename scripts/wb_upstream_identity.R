# The province run with the snow layers (#16) against the run set aside before
# it: every upstream mean but the snow columns must be identical.
#
#   Rscript scripts/wb_upstream_identity.R data/wb/_pre16/962a9cc2c4
#
# The snow layers are filled onto the analysis mask after it is fixed, so
# sampling and accumulating them cannot move any other column. This is what
# lets the fits carry their decision files (pooled_variant.txt,
# adjust_override.txt) and the AET choice to the new key: the annual balance,
# and everything that chose them, reads the same numbers. Stops on the first
# basin that differs; writes the tracked report data/checks/wb_upstream_identity.txt.

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
n_rows <- 0
for (code in codes_new) {
  a <- readRDS(file.path(old, "upstream", paste0(code, ".rds")))
  b <- readRDS(file.path(new, "upstream", paste0(code, ".rds")))
  if (!all(snow_cols %in% names(b))) stop(code, ": the new run has no snow columns")
  if (any(snow_cols %in% names(a))) stop(code, ": the set-aside run already has snow columns")
  if (anyNA(b[snow_cols][!is.na(b$p_yr), ])) stop(code, ": snow is NA where p_yr is not")
  # column by column, then the frame's own attributes: subsetting b to a's
  # columns would drop the `irregular` attribute wet_upstream_means() stores
  k <- names(a)[!vapply(names(a), function(x) identical(a[[x]], b[[x]]), TRUE)]
  if (length(k)) {
    stop(code, ": upstream columns differ from the set-aside run: ", paste(utils::head(k, 5), collapse = ", "))
  }
  if (!identical(attr(a, "row.names"), attr(b, "row.names")) ||
        !identical(attr(a, "irregular"), attr(b, "irregular"))) {
    stop(code, ": row names or irregular pairs differ from the set-aside run")
  }
  if (!setequal(setdiff(names(b), names(a)), snow_cols)) stop(code, ": the new run adds columns other than snow")
  n_rows <- n_rows + nrow(b)
}
writeLines(c(
  "# Upstream means with the snow layers (#16) against the run set aside before them", "",
  sprintf("set aside: %s", old), sprintf("current:   %s", new),
  sprintf("basins: %d; watersheds: %d", length(codes_new), n_rows),
  sprintf("every column of the set-aside run is identical() in the current one; the current run adds %s",
          paste(snow_cols, collapse = " and ")),
  "snow has a value wherever p_yr does"
), "data/checks/wb_upstream_identity.txt")
message("identical: ", length(codes_new), " basins, ", n_rows, " watersheds")
