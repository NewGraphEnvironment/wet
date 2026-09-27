#' Convert a depth over an area to discharge
#'
#' `m3/s = mm * area_m2 / 1000 / (days * 86400)`. The default `days = 365` is
#' the conversion fwapg uses for mean annual discharge. The water balance uses
#' 365.25 for a year and [wet_month_days()] for months, so that monthly volumes
#' sum to the annual one.
#'
#' @param mm Depth over the period, mm.
#' @param area_m2 Contributing area, m^2.
#' @param days Length of the period, days.
#' @return Discharge, m^3/s.
#' @export
#' @examples
#' wet_mm_to_m3s(500, 1e8)  # 500 mm/yr over 100 km2 is about 1.59 m3/s
#' wet_mm_to_m3s(40, 1e8, days = wet_month_days()[7])  # 40 mm in July
wet_mm_to_m3s <- function(mm, area_m2, days = 365) {
  mm * area_m2 / 1000 / (days * 86400)
}

#' Days in each month, with February at 28.25
#'
#' The monthly convention for the water balance: the twelve values sum to
#' 365.25, the year [wet_mm_to_m3s()] is given for annual flow, so monthly
#' volumes add up to the annual volume.
#'
#' @return Named numeric vector of length 12.
#' @export
#' @examples
#' sum(wet_month_days())
wet_month_days <- function() {
  stats::setNames(c(31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31), month.abb)
}
