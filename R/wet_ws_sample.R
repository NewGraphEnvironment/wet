#' Cell value for each fundamental watershed
#'
#' Two methods:
#'
#' * `"centroid"`: the value of the cell containing each polygon's centroid
#'   (centroid taken in the polygons' own CRS, then reprojected). This is what
#'   fwapg does with `ST_Value()`, and the method to use for a parity check.
#'   `cover` is 1 where the value is present and 0 where it is `NA`.
#' * `"area"`: the mean of every cell the polygon overlaps, weighted by the
#'   overlapping fraction, over cells that have a value. `cover` is the share of
#'   the polygon's overlap that falls on cells with a value, so a polygon
#'   half off the model domain reports `cover = 0.5` rather than a silently
#'   halved value downstream.
#'
#' @param r One-layer `terra::SpatRaster`.
#' @param ws `terra::SpatVector` of polygons with a `watershed_feature_id`
#'   attribute.
#' @param method `"centroid"` or `"area"`.
#' @return `data.frame(watershed_feature_id, value, cover)`.
#' @export
wet_ws_sample <- function(r, ws, method = c("centroid", "area")) {
  method <- match.arg(method)
  stopifnot(inherits(r, "SpatRaster"), terra::nlyr(r) == 1L,
            inherits(ws, "SpatVector"), "watershed_feature_id" %in% names(ws))
  id <- ws$watershed_feature_id

  if (method == "centroid") {
    pts <- terra::project(terra::centroids(ws, inside = FALSE), terra::crs(r))
    value <- terra::extract(r, pts, ID = FALSE)[[1]]
    return(data.frame(watershed_feature_id = id, value = value,
                      cover = as.numeric(!is.na(value))))
  }

  poly <- terra::project(ws, terra::crs(r))
  # extract() returns no rows for ground beyond the raster, so pad with NA
  # cells first; otherwise a polygon hanging off a bbox subset reports full
  # cover.
  r <- terra::extend(r, terra::union(terra::ext(r), terra::ext(poly)), snap = "out")
  ex <- terra::extract(r, poly, exact = TRUE, ID = TRUE)
  names(ex) <- c("ID", "v", "fraction")
  ok <- !is.na(ex$v)
  tot <- tapply(ex$fraction, factor(ex$ID, levels = seq_along(id)), sum)
  cov <- tapply(ex$fraction[ok], factor(ex$ID[ok], levels = seq_along(id)), sum)
  wv <- tapply(ex$v[ok] * ex$fraction[ok],
               factor(ex$ID[ok], levels = seq_along(id)), sum)
  cov[is.na(cov)] <- 0
  value <- ifelse(cov > 0, wv / cov, NA_real_)
  cover <- ifelse(is.na(tot) | tot == 0, 0, cov / tot)
  data.frame(watershed_feature_id = id, value = as.numeric(value),
             cover = as.numeric(cover))
}
