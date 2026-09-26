#' Mean annual total per cell, fetched one year at a time
#'
#' For basin-scale extents a whole 30-year daily subset does not fit in memory
#' (the Fraser is ~22,000 cells x 10,957 days per variable). This fetches each
#' calendar year with [wet_pcic_fetch()] (cached per year), reduces it to that
#' year's total with [wet_runoff_annual()], and averages the yearly totals:
#' the same result as [wet_runoff_annual()] on the whole period, i.e. cdo's
#' `-timmean -yearsum`.
#'
#' @inheritParams wet_pcic_fetch
#' @param years Integer vector of whole calendar years.
#' @return A one-layer `SpatRaster` (units of the variable per year).
#' @export
wet_pcic_annual <- function(variable, bbox, years, run = "TPS_gridded_obs_init",
                            dir = "data/pcic", timeout = 3600) {
  years <- as.integer(years)
  stopifnot(length(years) >= 1L, !anyNA(years), !anyDuplicated(years))
  total <- NULL
  for (y in years) {
    f <- wet_pcic_fetch(variable, bbox, sprintf("%d-01-01", y), sprintf("%d-12-31", y),
                        run = run, dir = dir, timeout = timeout)
    a <- wet_runoff_annual(terra::rast(f))
    if (is.null(total)) {
      total <- a
    } else {
      if (!terra::compareGeom(total, a, stopOnError = FALSE)) {
        stop("year ", y, " came back on a different grid", call. = FALSE)
      }
      total <- total + a
    }
  }
  out <- total / length(years)
  names(out) <- "annual"
  out
}
