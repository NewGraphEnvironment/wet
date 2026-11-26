#' Mean monthly total per cell from a daily raster
#'
#' For each calendar month, sums the month's daily layers in each year, then
#' averages those totals over the years. The twelve layers sum to
#' [wet_runoff_annual()]'s annual mean, so a monthly share is a layer over their
#' sum. Units follow the input (PCIC mm/day in, mm/month out).
#'
#' Only complete years are accepted, as in [wet_runoff_annual()], so every month
#' is averaged over the same years.
#'
#' @param r A `terra::SpatRaster` of daily layers with a `Date` time axis.
#' @return A 12-layer `SpatRaster`, layers `m01` to `m12`.
#' @export
#' @examples
#' d <- seq(as.Date("1983-01-01"), as.Date("1984-12-31"), by = "day")
#' r <- terra::rast(nrows = 1, ncols = 2, nlyrs = length(d), vals = 1)
#' terra::time(r) <- d
#' # one mm a day: each month's mean total is its mean number of days
#' m <- wet_runoff_monthly(r)
#' terra::values(m)[1, ]
#' # and the months add up to the annual mean, (365 + 366) / 2
#' terra::values(sum(m))[1, ]
wet_runoff_monthly <- function(r) {
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
  mo <- as.integer(format(d, "%m"))
  out <- lapply(1:12, function(m) {
    i <- which(mo == m)
    terra::mean(terra::tapp(r[[i]], index = yr[i], fun = "sum"))
  })
  out <- terra::rast(out)
  names(out) <- sprintf("m%02d", 1:12)
  out
}
