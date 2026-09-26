#' OPeNDAP index ranges for a bounding box and date range on the PCIC grid
#'
#' The PCIC VIC-GL grid is 0.0625 degrees, with cell centres at
#' `lon0 + 0.0625 * i` and `lat0 + 0.0625 * j` (both ascending). Time is daily,
#' `days since 1945-01-01`, standard calendar, so the time index of a date is
#' its day offset from the origin.
#'
#' A cell is included when any part of it intersects `bbox`.
#'
#' @param bbox Numeric `c(xmin, ymin, xmax, ymax)` in longitude/latitude.
#' @param start,end Dates (or strings coercible by [as.Date()]), inclusive.
#' @param origin Time origin of the dataset.
#' @param lon0,lat0 Centre of the first cell.
#' @param res Cell size in degrees.
#' @param nlon,nlat Grid dimensions.
#' @return Named list of zero-based inclusive integer pairs: `time`, `lat`,
#'   `lon`.
#' @export
#' @examples
#' # 1981-2010, the slice fwapg uses: time indices 13149 to 24105
#' wet_pcic_index(c(-122.5, 54, -122, 54.5), "1981-01-01", "2010-12-31")
wet_pcic_index <- function(bbox, start, end, origin = "1945-01-01",
                           lon0 = -139.96875, lat0 = 41.09375, res = 0.0625,
                           nlon = 496L, nlat = 367L) {
  stopifnot(is.numeric(bbox), length(bbox) == 4L, !anyNA(bbox),
            bbox[1] < bbox[3], bbox[2] < bbox[4])
  start <- as.Date(start)
  end <- as.Date(end)
  stopifnot(!is.na(start), !is.na(end), start <= end)

  # Edge of the first cell, then which cell each bbox edge falls in.
  cell <- function(v, v0, n) {
    i <- floor((v - (v0 - res / 2)) / res)
    as.integer(min(max(i, 0), n - 1))
  }
  lon <- c(cell(bbox[1], lon0, nlon), cell(bbox[3], lon0, nlon))
  lat <- c(cell(bbox[2], lat0, nlat), cell(bbox[4], lat0, nlat))
  # A bbox entirely off the grid clamps to an edge cell; refuse rather than
  # return data for somewhere else.
  grid_ext <- c(lon0 - res / 2, lat0 - res / 2,
                lon0 + res * (nlon - 0.5), lat0 + res * (nlat - 0.5))
  if (bbox[3] < grid_ext[1] || bbox[1] > grid_ext[3] ||
      bbox[4] < grid_ext[2] || bbox[2] > grid_ext[4]) {
    stop("bbox does not intersect the PCIC grid", call. = FALSE)
  }

  time <- as.integer(c(start, end) - as.Date(origin))
  if (time[1] < 0) stop("start is before the dataset origin ", origin, call. = FALSE)
  list(time = time, lat = lat, lon = lon)
}
