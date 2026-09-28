#' Adjust modelled AET by land cover, as Chapman et al. (2018) did
#'
#' Chapman, Kerr & Wilford (2012, p. 83) multiply the CGIAR AET by a per-class
#' ratio of measured AET for the cover to the modelled (agronomic-crop) AET,
#' drawing the measured values from the table published as Table 3 of Chapman
#' et al. (2018, p. 8). The ratios they used were tuned in calibration and never
#' published, so here each class's ratio is fixed without fitting:
#'
#' `ratio_c = et_class[c] / mean(aet over the cells where c is the majority)`
#'
#' and the multiplier of each cell is `sum_c frac_c * ratio_c + (1 - sum_c
#' frac_c)`. Ground no class covers (outside the land-cover product) keeps ratio
#' 1, i.e. the input AET. A cell votes for a majority class only when more than
#' half of it is covered and it lies in `domain`. A class with fewer than
#' `min_cells` majority cells gets ratio 1, and every ratio is clamped to
#' `clamp`, so a class whose modelled AET is near 0 (snow and ice) cannot
#' scale its cells without limit.
#'
#' @param aet One-layer `SpatRaster` of modelled annual AET (mm). The ratio
#'   denominators are taken over its non-`NA` cells.
#' @param frac `SpatRaster` of cover fractions (0-1), one layer per class,
#'   named by class, on the grid of `aet`; e.g. [wet_landcover_nrcan()].
#' @param et_class Named numeric: measured AET (mm) per class, with a value for
#'   every layer of `frac`. Defaults to [wet_chapman_table3()].
#' @param domain Optional one-layer `SpatRaster` on the grid of `aet`: only
#'   cells where it is `TRUE` (non-zero) count towards the ratio denominators.
#'   The adjustment is still applied everywhere.
#' @param min_cells Minimum majority cells for a class to get its own ratio.
#' @param clamp Lower and upper limits of a class ratio.
#' @return `list(aet, ratio)`: the adjusted AET (`SpatRaster`, mm) and a
#'   `data.frame(class, et_mm, aet_mean, n_cells, ratio)`.
#' @export
#' @examples
#' r <- terra::rast(nrows = 1, ncols = 3, xmin = 0, xmax = 3, ymin = 0, ymax = 1)
#' aet <- terra::setValues(r, c(350, 330, 240))
#' frac <- c(terra::setValues(r, c(1, 1, 0)), terra::setValues(r, c(0, 0, 1)))
#' names(frac) <- c("coniferous", "grass")
#' out <- wet_aet_landcover(aet, frac)
#' out$ratio
#' terra::values(out$aet, mat = FALSE)
wet_aet_landcover <- function(aet, frac, et_class = NULL, domain = NULL, min_cells = 1,
                              clamp = c(0.25, 4)) {
  if (is.null(et_class)) {
    t3 <- wet_chapman_table3()
    et_class <- stats::setNames(t3$aet_mm, t3$class)
  }
  stopifnot(inherits(aet, "SpatRaster"), terra::nlyr(aet) == 1, inherits(frac, "SpatRaster"))
  cls <- names(frac)
  miss <- setdiff(cls, names(et_class))
  if (length(miss)) stop("no measured AET for class: ", paste(miss, collapse = ", "), call. = FALSE)
  frac <- terra::classify(frac, cbind(NA, 0))  # no product: no cover
  covered <- sum(frac)
  maj <- terra::ifel(covered > 0.5, terra::which.max(frac), NA)
  if (!is.null(domain)) maj <- terra::mask(maj, domain, maskvalues = c(NA, 0))
  z <- terra::zonal(aet, maj, fun = "mean", na.rm = TRUE)
  n <- terra::zonal(!is.na(aet), maj, fun = "sum", na.rm = TRUE)
  aet_mean <- z[[2]][match(seq_along(cls), z[[1]])]
  n_cells <- n[[2]][match(seq_along(cls), n[[1]])]
  n_cells[is.na(n_cells)] <- 0
  ratio <- unname(et_class[cls]) / aet_mean
  ratio[n_cells < max(min_cells, 1) | !is.finite(ratio)] <- 1
  ratio <- pmin(pmax(ratio, clamp[1]), clamp[2])
  mult <- sum(frac * ratio) + (1 - covered)
  list(aet = aet * mult,
       ratio = data.frame(class = cls, et_mm = unname(et_class[cls]), aet_mean = aet_mean,
                          n_cells = n_cells, ratio = ratio))
}

#' Measured AET by land-cover class (Chapman et al. 2018, Table 3)
#'
#' One value per class from Table 3 of Chapman et al. (2018, p. 8). Where the
#' table has a Canada-wide value (Liu et al. 2003) it is used, so all classes
#' come from one study where possible. The exceptions are wetland, the midpoint
#' of the subarctic boreal fen range (313-341 mm; Chapman 1988), and water, the
#' midpoint of the NE British Columbia range (350-500 mm; Canada 1978). Each
#' class carries the NRCan 2020 land-cover codes that map to it.
#'
#' @return `data.frame(class, aet_mm, table3_setting, table3_aet, reference,
#'   nrcan_2020_codes)`; the codes are `;`-separated.
#' @export
#' @examples
#' wet_chapman_table3()[c("class", "aet_mm", "nrcan_2020_codes")]
wet_chapman_table3 <- function() {
  t3 <- utils::read.csv(system.file("extdata", "chapman_table3.csv", package = "wet"),
                        colClasses = "character")
  t3$aet_mm <- as.numeric(t3$aet_mm)
  t3
}
