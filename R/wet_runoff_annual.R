#' Mean annual total per cell from a daily raster
#'
#' Sums each calendar year's daily layers, then averages the yearly totals:
#' the same as `cdo -timmean -yearsum`, which is how fwapg builds mean annual
#' discharge. Units follow the input (PCIC mm/day in, mm/yr out).
#'
#' Only complete years are accepted, because a partial year's sum is not an
#' annual total and would bias the mean low without any warning.
#'
#' @param r A `terra::SpatRaster` of daily layers with a `Date` time axis.
#' @return A one-layer `SpatRaster`.
#' @export
wet_runoff_annual <- function(r) {
  stopifnot(inherits(r, "SpatRaster"))
  d <- terra::time(r)
  if (is.null(d) || anyNA(d)) stop("r needs a time axis on every layer", call. = FALSE)
  d <- as.Date(d)
  if (anyDuplicated(d)) stop("r has duplicate dates", call. = FALSE)
  yr <- as.integer(format(d, "%Y"))
  n <- table(yr)
  full <- as.integer(as.Date(paste0(names(n), "-12-31")) -
                       as.Date(paste0(names(n), "-01-01"))) + 1L
  if (any(n != full)) {
    stop("incomplete years: ", paste(names(n)[n != full], collapse = ", "),
         call. = FALSE)
  }
  yearly <- terra::tapp(r, index = yr, fun = "sum")
  out <- terra::mean(yearly)
  names(out) <- "annual"
  out
}
