#' Each year's ERA5-Land snow over one watershed
#'
#' Reads cd's annual snow layers (one band per year, ERA5-Land at 0.1 degree)
#' and returns each year's area-weighted mean over a watershed: the per-year
#' values that [wet_snow_normals()] averages over 1981-2010 onto a grid, here
#' kept year by year and for one area.
#'
#' `ws` is one watershed, given as its fundamental watersheds (as fetched from
#' fwapg) or as a single outline. The polygons are dissolved into one and that
#' union is sampled once with [wet_ws_sample()] (`method = "area"`), so the
#' fundamental watersheds and their union give identical results, and nested
#' or overlapping polygons count their ground once. Several watersheds passed
#' together return the mean over their union; call once per watershed for
#' separate values.
#'
#' Each variable and year is one layer of a single stack, so
#' [wet_ws_sample()]'s rule holds across all of them: a cell counts only where
#' **every** layer has a value, and `cover` is one number, the share of the
#' watershed on those cells. A cell missing in one year or one variable
#' therefore leaves every year's value over the remaining cells, and a year's
#' value can depend on which `years` and `vars` are asked for. ERA5-Land has
#' no cell over the sea, so a watershed reaching the coast reports `cover`
#' below 1.
#'
#' `cap` limits each cell's value in each year before the mean, as
#' [wet_snow_normals()] limits each cell's 1981-2010 mean: ERA5-Land's glacier
#' points carry perennial snow, with `swe_max` of 5,000 to 10,000 mm against a
#' seasonal maximum of about 3,000 mm elsewhere.
#'
#' @param ws `terra::SpatVector` of polygons, in any CRS: one watershed.
#' @param vars cd variable names, each with an `"annual"` row in `catalog`,
#'   for example `snowmelt_doy_50` (the day of the year by which half the
#'   year's snowmelt has happened), `swe_max` (the year's peak snow water
#'   equivalent, mm) or `snowmelt_rate_peak` (the peak weekly melt rate, mm per
#'   week).
#' @param years Years to return; every one must be a band of each variable's
#'   file. `NULL` returns every band year of the first variable, which every
#'   other variable must also have.
#' @param catalog A `data.frame` with columns `variable`, `period` and `href`,
#'   as from `cd::cd_catalog()`; `NULL` reads cd's default catalog. A remote
#'   `href` is read through `cd::cd_cache_fetch()`; any other must be a local
#'   file.
#' @param cap Named numeric: an upper limit for each cell's value of each
#'   named variable, applied in every year before the mean. Variables not named
#'   are not capped. The default caps `swe_max` when it is in `vars`; a `cap`
#'   given explicitly must name only variables in `vars`.
#' @return `data.frame(year, <vars>, cover)`, one row per year in ascending
#'   order. `cover` is the same in every row; where it is 0 the values are
#'   `NA`.
#' @seealso [wet_snow_normals()] for the 1981-2010 means on a grid.
#' @export
#' @examples
#' # Maxan Creek above Bulkley Lake (08EE018) and cd's layers cropped to it,
#' # bundled with wet (data-raw/snow_pilot_data.R)
#' d <- system.file("extdata", "snow_pilot", package = "wet")
#' outline <- readRDS(file.path(d, "maxan_outline.rds"))
#' ws <- terra::vect(outline$wkt, crs = outline$crs)
#' cat <- utils::read.csv(file.path(d, "catalog.csv"))
#' cat$href <- file.path(d, cat$href)
#' snow <- wet_snow_annual(ws, c("swe_max", "snowmelt_doy_50"), catalog = cat)
#' head(snow)
#' # peak snow and melt date over 2011-2025 against 1950-1980
#' rbind(early = colMeans(snow[snow$year <= 1980, 2:3]),
#'       late = colMeans(snow[snow$year >= 2011, 2:3]))
wet_snow_annual <- function(ws, vars = c("snowmelt_doy_50", "swe_max"), years = NULL, catalog = NULL,
                            cap = c(swe_max = 3000)) {
  if (!inherits(ws, "SpatVector") || terra::geomtype(ws) != "polygons" || nrow(ws) == 0) {
    stop("ws must be a SpatVector of one or more polygons", call. = FALSE)
  }
  if (!nzchar(terra::crs(ws))) stop("ws has no CRS", call. = FALSE)
  catalog <- wet_snow_catalog(catalog)
  if (!length(vars) || anyNA(vars) || anyDuplicated(vars) || any(grepl("|", vars, fixed = TRUE))) {
    stop("vars must be distinct cd variable names", call. = FALSE)
  }
  if (!is.null(years) && (!length(years) || anyNA(years) || anyDuplicated(years))) {
    stop("years must be distinct years", call. = FALSE)
  }
  files <- wet_snow_files(vars, catalog)
  # the default cap applies when its variable is asked for
  if (missing(cap)) cap <- cap[names(cap) %in% vars]
  wet_snow_cap_check(cap, vars)

  src <- lapply(files, terra::rast)
  for (i in seq_along(vars)) {
    if (!all(grepl("^[0-9]{4}$", names(src[[i]])))) {
      stop(vars[i], "'s bands are not named by year", call. = FALSE)
    }
    if (i > 1 && !terra::compareGeom(src[[i]], src[[1]], lyrs = FALSE, stopOnError = FALSE)) {
      stop(vars[i], " is not on ", vars[1], "'s grid", call. = FALSE)
    }
  }
  if (is.null(years)) years <- as.integer(names(src[[1]]))
  years <- sort(as.integer(years))
  for (i in seq_along(vars)) wet_snow_bands_check(src[[i]], years, vars[i])

  # one watershed: the union of the polygons, sampled once
  u <- if (nrow(ws) == 1) ws[, 0] else terra::aggregate(ws[, 0])
  u$watershed_feature_id <- 1L
  # two source cells beyond the watershed, so every cell it touches is read
  e <- terra::extend(terra::ext(terra::project(u, terra::crs(src[[1]]))), 2 * terra::res(src[[1]]))
  out <- data.frame(year = years)
  if (is.null(terra::intersect(e, terra::ext(src[[1]])))) {
    for (v in vars) out[[v]] <- NA_real_
    out$cover <- 0
    return(out)
  }
  stack <- terra::rast(lapply(seq_along(vars), function(i) {
    r <- terra::crop(src[[i]][[as.character(years)]], e, snap = "out")
    if (vars[i] %in% names(cap)) r <- terra::ifel(r > cap[[vars[i]]], cap[[vars[i]]], r)
    names(r) <- paste(vars[i], years, sep = "|")
    r
  }))
  s <- wet_ws_sample(stack, u, method = "area")
  # a single layer comes back as `value`
  if (terra::nlyr(stack) == 1) names(s)[names(s) == "value"] <- names(stack)
  for (v in vars) out[[v]] <- unlist(s[1, paste(v, years, sep = "|")], use.names = FALSE)
  out$cover <- s$cover[1]
  out
}
