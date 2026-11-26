#' Mean monthly total per cell, fetched one year at a time
#'
#' The monthly counterpart of [wet_pcic_annual()]: fetches each calendar year
#' with [wet_pcic_fetch()] (cached per year), reduces it to that year's twelve
#' monthly totals with [wet_runoff_monthly()], and averages them over the
#' years. The result equals [wet_runoff_monthly()] on the whole period, and its
#' twelve layers sum to [wet_pcic_annual()]'s.
#'
#' @inheritParams wet_pcic_annual
#' @return A 12-layer `SpatRaster`, layers `m01` to `m12` (units of the variable
#'   per month).
#' @export
#' @examples
#' \dontrun{
#' # 1981-2010 runoff by month for one CMIP5 run, over a box near Prince George
#' # (30 one-year requests to PCIC, cached under data/pcic/)
#' m <- wet_pcic_monthly("RUNOFF", c(-123, 53.8, -122.5, 54.2), 1981:2010,
#'                       run = "CanESM2_rcp45_r1i1p1")
#' terra::global(m, "mean", na.rm = TRUE)
#' }
wet_pcic_monthly <- function(variable, bbox, years, run = "TPS_gridded_obs_init",
                             dir = "data/pcic", timeout = 3600) {
  years <- as.integer(years)
  stopifnot(length(years) >= 1L, !anyNA(years), !anyDuplicated(years))
  total <- NULL
  for (y in years) {
    f <- wet_pcic_fetch(variable, bbox, sprintf("%d-01-01", y), sprintf("%d-12-31", y),
                        run = run, dir = dir, timeout = timeout)
    m <- wet_runoff_monthly(terra::rast(f))
    if (is.null(total)) {
      total <- m
    } else {
      if (!terra::compareGeom(total, m, stopOnError = FALSE)) {
        stop("year ", y, " came back on a different grid", call. = FALSE)
      }
      total <- total + m
    }
  }
  out <- total / length(years)
  names(out) <- sprintf("m%02d", 1:12)
  out
}
