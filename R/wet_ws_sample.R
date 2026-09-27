#' Cell values for each fundamental watershed
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
#' With several layers, a cell counts only where **every** layer has a value,
#' and all layers are averaged over those same cells. There is then one
#' `cover` per polygon, so upstream means of every layer share one
#' denominator and a linear combination of layers is exactly the same
#' combination of their means.
#'
#' @param r `terra::SpatRaster`, one or more layers.
#' @param ws `terra::SpatVector` of polygons with a `watershed_feature_id`
#'   attribute; or, for `"centroid"` only, a `data.frame(watershed_feature_id,
#'   lon, lat)` of centroids already computed (e.g. by [wet_ws_fetch()]),
#'   which avoids transferring geometry for a whole basin.
#' @param method `"centroid"` or `"area"`.
#' @return For one layer, `data.frame(watershed_feature_id, value, cover)`.
#'   For several, `data.frame(watershed_feature_id, <layer names>, cover)`.
#' @export
wet_ws_sample <- function(r, ws, method = c("centroid", "area")) {
  method <- match.arg(method)
  stopifnot(inherits(r, "SpatRaster"), "watershed_feature_id" %in% names(ws))
  lyr <- names(r)
  if (terra::nlyr(r) > 1 && (anyDuplicated(lyr) || any(lyr %in% c("watershed_feature_id", "cover")))) {
    stop("layer names must be unique and not 'watershed_feature_id' or 'cover'", call. = FALSE)
  }
  id <- ws$watershed_feature_id

  if (method == "centroid") {
    if (is.data.frame(ws)) {
      stopifnot(all(c("lon", "lat") %in% names(ws)), !anyNA(ws$lon), !anyNA(ws$lat))
      pts <- terra::vect(data.frame(lon = ws$lon, lat = ws$lat), geom = c("lon", "lat"),
                         crs = "EPSG:4326")
    } else {
      stopifnot(inherits(ws, "SpatVector"))
      pts <- terra::centroids(ws, inside = FALSE)
    }
    v <- as.matrix(terra::extract(r, terra::project(pts, terra::crs(r)), ID = FALSE))
    ok <- stats::complete.cases(v)
    v[!ok, ] <- NA
    return(wet_ws_frame(id, v, as.numeric(ok), lyr))
  }
  if (is.data.frame(ws)) stop("method = \"area\" needs polygons (a SpatVector)", call. = FALSE)
  stopifnot(inherits(ws, "SpatVector"))

  poly <- terra::project(ws, terra::crs(r))
  # extract() returns no rows for ground beyond the raster, so pad with NA
  # cells first; otherwise a polygon hanging off a bbox subset reports full
  # cover.
  r <- terra::extend(r, terra::union(terra::ext(r), terra::ext(poly)), snap = "out")
  ex <- terra::extract(r, poly, exact = TRUE, ID = TRUE)
  v <- as.matrix(ex[, seq_along(lyr) + 1L, drop = FALSE])
  ok <- stats::complete.cases(v)
  n <- length(id)
  # sums placed by polygon index: rowsum() returns only the groups present
  by_id <- function(x) {
    s <- rowsum(x, ex$ID)
    out <- matrix(0, n, ncol(s))
    out[as.integer(rownames(s)), ] <- s
    out
  }
  tot <- by_id(ex$fraction)[, 1]
  fr <- ifelse(ok, ex$fraction, 0)
  cov <- by_id(fr)[, 1]
  v[!ok, ] <- 0
  wv <- by_id(v * fr)
  val <- wv / cov
  val[!(cov > 0), ] <- NA
  wet_ws_frame(id, val, ifelse(tot > 0, cov / tot, 0), lyr)
}

wet_ws_frame <- function(id, v, cover, lyr) {
  if (length(lyr) == 1L) {
    return(data.frame(watershed_feature_id = id, value = as.numeric(v[, 1]), cover = cover))
  }
  out <- data.frame(watershed_feature_id = id, v, cover = cover, check.names = FALSE)
  names(out)[seq_along(lyr) + 1L] <- lyr
  rownames(out) <- NULL
  out
}
