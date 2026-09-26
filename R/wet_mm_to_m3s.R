#' Convert a mean annual depth over an area to discharge
#'
#' `m3/s = mm/yr * area_m2 / 1000 / (365 * 86400)`, the conversion fwapg uses
#' (a 365-day year).
#'
#' @param mm Mean annual depth, mm/yr.
#' @param area_m2 Contributing area, m^2.
#' @return Discharge, m^3/s.
#' @export
#' @examples
#' wet_mm_to_m3s(500, 1e8)  # 500 mm/yr over 100 km2 is about 1.59 m3/s
wet_mm_to_m3s <- function(mm, area_m2) {
  mm * area_m2 / 31536000000
}
