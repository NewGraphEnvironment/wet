#' Actual evapotranspiration from Fu's Budyko curve
#'
#' `AET = P + PET - (P^w + PET^w)^(1/w)`: Fu's (1981) form of the Budyko
#' curve, as given by Zhang et al. (2004, *Water Resources Research* 40,
#' W02502). It is 0 when either P or PET is 0, tends to PET where water is
#' plentiful and to P where it is scarce, and never exceeds either. `omega` sets
#' how closely it hugs those limits; 2.6 is the mean Zhang et al. fitted over
#' 470 catchments.
#'
#' Applied per cell to long-term annual means, it gives the evaporation that
#' the local demand and supply imply, whatever a soil-bucket product computed
#' from a different precipitation.
#'
#' @param p,pet Long-term mean annual precipitation and potential (reference)
#'   evapotranspiration (mm): numeric vectors or `SpatRaster`s. Negative values
#'   count as 0.
#' @param omega Fu's parameter, greater than 1.
#' @return Actual evapotranspiration (mm), like the inputs.
#' @export
#' @examples
#' # Greata Creek (Okanagan): P 746 mm against a demand of about 650 mm
#' wet_aet_budyko(746, 650)
#' # the whole curve, as the evaporative index E/P against the dryness index PET/P
#' dryness <- c(0.25, 0.5, 1, 2, 4)
#' round(wet_aet_budyko(1, dryness), 2)
wet_aet_budyko <- function(p, pet, omega = 2.6) {
  if (length(omega) != 1 || !is.finite(omega) || omega <= 1) {
    stop("omega must be one number greater than 1", call. = FALSE)
  }
  p <- wet_pos(p)
  pet <- wet_pos(pet)
  p + pet - (p^omega + pet^omega)^(1 / omega)
}
