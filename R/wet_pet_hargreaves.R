#' Monthly reference evapotranspiration by Hargreaves (FAO-56)
#'
#' FAO-56 equation 52, `ET0 = 0.0023 (Tmean + 17.8) (Tmax - Tmin)^0.5 Ra`,
#' with `Ra` the extraterrestrial radiation (equation 21, converted to mm/day
#' by 0.408) on the month's representative day `J = floor(30.4 M - 15)`, times
#' the days in the month from [wet_month_days()]. Allen et al. (1998), *Crop
#' Evapotranspiration*, FAO Irrigation and Drainage Paper 56, chapter 3.
#'
#' Hargreaves needs only temperature, so on climr's monthly `Tmax`/`Tmin`
#' normals it gives a demand on the same climate as the precipitation. A
#' negative diurnal range (independently downscaled `Tmin` above `Tmax`) and
#' `Tmean` below -17.8 C both give 0, never `NaN` or a negative demand.
#'
#' @param tmax,tmin Monthly mean daily maximum and minimum temperature (C):
#'   numeric vectors or `SpatRaster`s.
#' @param lat Latitude (degrees, south negative): numeric, or a `SpatRaster`
#'   such as `terra::init(tmax, "y")` on a geographic grid.
#' @param month Month, 1 to 12 (one value).
#' @return Reference evapotranspiration over the month (mm), numeric or a
#'   `SpatRaster` like the inputs.
#' @export
#' @examples
#' # a July at 50 N with a 20 C diurnal range: about 170 mm
#' wet_pet_hargreaves(tmax = 25, tmin = 5, lat = 50, month = 7)
#' # the annual cycle at one place
#' round(vapply(1:12, function(m) wet_pet_hargreaves(c(-3, 0, 5, 11, 16, 20, 24, 24, 18, 10, 2, -3)[m],
#'   c(-10, -9, -5, -1, 3, 7, 9, 9, 5, 1, -4, -9)[m], 50.7, m), 0))
wet_pet_hargreaves <- function(tmax, tmin, lat, month) {
  if (length(month) != 1 || !month %in% 1:12) stop("month must be one value in 1-12", call. = FALSE)
  j <- floor(30.4 * month - 15)
  ra <- wet_ra(lat, j)
  tmean <- (tmax + tmin) / 2
  et0 <- 0.0023 * wet_pos(tmean + 17.8) * sqrt(wet_pos(tmax - tmin)) * 0.408 * ra
  et0 * wet_month_days()[[month]]
}

# Extraterrestrial radiation (MJ m-2 day-1), FAO-56 equations 21-25, for
# latitude `lat` (degrees) and day of year `j`. The sunset hour angle is
# clamped for polar day and night, where acos() would otherwise be NaN.
wet_ra <- function(lat, j) {
  phi <- lat * pi / 180
  dr <- 1 + 0.033 * cos(2 * pi * j / 365)
  delta <- 0.409 * sin(2 * pi * j / 365 - 1.39)
  x <- -tan(phi) * tan(delta)
  x <- if (inherits(x, "SpatRaster")) terra::clamp(x, -1, 1, values = TRUE) else pmin(pmax(x, -1), 1)
  ws <- acos(x)
  24 * 60 / pi * 0.0820 * dr * (ws * sin(phi) * sin(delta) + cos(phi) * cos(delta) * sin(ws))
}

# max(x, 0) for numeric vectors and SpatRasters alike.
wet_pos <- function(x) {
  if (inherits(x, "SpatRaster")) terra::clamp(x, lower = 0, values = TRUE) else pmax(x, 0)
}
