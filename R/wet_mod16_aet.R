#' Annual AET on a grid from MODIS MOD16A3GF v061
#'
#' Downloads the MOD16A3GF v061 granules (Running, Mu and Zhao, NASA LP DAAC,
#' doi:10.5067/MODIS/MOD16A3GF.061; gap-filled annual ET, 500 m sinusoidal) for
#' every sinusoidal tile `grid` touches and every year in `years`, averages the
#' annual ET per pixel, and puts the mean on `grid`. MOD16 is a Penman-Monteith
#' model driven by MODIS land cover, LAI and albedo and by GMAO meteorology, so
#' unlike a soil bucket it is not capped by a precipitation field.
#'
#' The `ET_500m` layer (kg/m2/yr, i.e. mm/yr; stored as unsigned 16-bit with a
#' 0.1 scale that terra applies) has a valid range of 0-65500. Codes 65529-65535
#' mark pixels the product does not model (unclassified, urban, permanent
#' wetland, snow and ice, barren, water, fill), so every value above the valid
#' range is a gap. A pixel's mean is taken over its valid years and kept only
#' when it has at least `min_years` of them, since its land-cover class can
#' change between years.
#'
#' The tiles are mosaicked in their sinusoidal CRS and put on `grid` in two
#' steps, as in [wet_landcover_nrcan()]: nearest onto a grid `fact` times finer
#' than `grid` and aligned with it, then block means. A single warp would take
#' each target cell's footprint as an axis-aligned box in the source CRS, and
#' the sinusoidal grid is strongly sheared at BC's longitudes. The result has
#' two layers: `et_mod16`, the mean over the valid part of each cell, and
#' `frac_mod16`, the share of the cell that is valid (0-1). Where the share is
#' 0, `et_mod16` is `NA`; filling the gaps is left to the caller, and
#' `frac_mod16` lets it weight the fill by area.
#'
#' Granules are listed through NASA's CMR search (no login) and downloaded from
#' LP DAAC with an Earthdata login read from a netrc file: the option
#' `wet.earthdata_netrc`, otherwise the first of `$NETRC`, the file
#' `earthdatalogin` keeps (`tools::R_user_dir("earthdatalogin")/netrc`) and
#' `~/.netrc` that has a `machine urs.earthdata.nasa.gov` entry. Downloads are
#' written to `.part`, renamed on HTTP 200 and opened before they are kept, since
#' a failed login can end on a page served with 200. Granules already in `dir` are
#' used without a search, and the grid is cached under a key that includes the
#' md5 of every granule read.
#'
#' @param grid Target grid: a `SpatRaster` or a path to one, in lon/lat (EPSG:4326).
#' @param years Calendar years to average.
#' @param dir Cache directory for the granules and the result.
#' @param overwrite Logical. Rebuild the grid even when cached.
#' @param timeout Seconds allowed for each download (a granule is about 20 MB).
#' @param fact Subdivision of each `grid` cell for the nearest-neighbour step;
#'   4 makes a 30 arc-second cell about 230 x 130 m at 55 N, finer than 500 m.
#' @param min_years Valid years a pixel needs for its mean to count.
#' @return Path to a GeoTIFF with layers `et_mod16` (mm per year) and
#'   `frac_mod16`.
#' @export
#' @examplesIf interactive()
#' # needs an Earthdata login in a netrc; about 20 MB a granule on first use
#' g <- terra::rast(xmin = -120, xmax = -119, ymin = 50, ymax = 51, res = 1 / 120)
#' m <- terra::rast(wet_mod16_aet(g, years = 2010:2011, min_years = 1))
#' terra::global(m, "mean", na.rm = TRUE)
wet_mod16_aet <- function(grid, years = 2001:2020, dir = "data/mod16", overwrite = FALSE, timeout = 600,
                          fact = 4, min_years = 10) {
  grid <- if (inherits(grid, "SpatRaster")) grid[[1]] else terra::rast(grid)[[1]]
  # the tile search and the CMR bbox read the grid's extent as degrees
  if (!isTRUE(terra::is.lonlat(grid))) stop("grid must be in lon/lat (EPSG:4326)", call. = FALSE)
  years <- sort(unique(as.integer(years)))
  if (min_years < 1 || min_years > length(years)) stop("min_years must be in 1-", length(years), call. = FALSE)
  tiles <- wet_modis_tiles(grid)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  local <- wet_mod16_local(dir, tiles, years)
  if (anyNA(local$path)) {
    gr <- wet_mod16_search(grid, years)
    gr <- gr[gr$tile %in% tiles, ]
    wet_mod16_check(gr, tiles, years)
    netrc <- wet_earthdata_netrc()
    for (i in which(is.na(local$path))) {
      u <- gr$url[gr$tile == local$tile[i] & gr$year == local$year[i]]
      dest <- file.path(dir, basename(u))
      wet_download(u, dest, timeout, netrc = netrc)
      # a failed login can end in an HTML page served with 200: check the file
      # is a granule before a cache check would trust it
      ok <- tryCatch(inherits(wet_mod16_read(dest), "SpatRaster"), error = function(e) FALSE)
      if (!ok) {
        unlink(dest)
        stop(basename(u), " is not a readable MOD16A3GF granule (a login page?); check the Earthdata netrc",
             call. = FALSE)
      }
      local$path[i] <- dest
    }
  }
  # keyed on the grid, the parameters, the granules actually read and the method
  # version (bump it whenever wet_mod16_grid() changes what it computes)
  key <- wet_md5_text(paste(c(wet_grid_key(grid), years, min_years, fact, unname(tools::md5sum(local$path)),
                              wet_mod16_method), collapse = "|"))
  dest <- file.path(dir, sprintf("mod16_%d_%d_%s.tif", min(years), max(years), substr(key, 1, 10)))
  if (file.exists(dest) && !overwrite) return(dest)
  out <- wet_mod16_grid(local, grid, fact, min_years)
  tmp <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  terra::writeRaster(out, tmp, datatype = "FLT4S", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move MOD16 grid to ", dest, call. = FALSE)
  dest
}

wet_mod16_method <- "year-mean-two-step-near-aggregate-1"

# MODIS sinusoidal grid: sphere radius, tile size and the grid's upper-left corner
wet_modis_sinu <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +R=6371007.181 +units=m +no_defs"
wet_modis_tile_m <- 1111950.5197665233
wet_modis_ul <- c(-20015109.354, 10007554.677)

# Sinusoidal tiles ("h10v03") that the grid's extent reaches by more than 1 m. The extent is
# densified before projecting, since its meridian edges curve in sinusoidal
# and a straight chord between the corners can miss a tile corner.
wet_modis_tiles <- function(grid) {
  p <- terra::as.polygons(terra::ext(grid), crs = terra::crs(grid))
  p <- terra::project(terra::densify(p, 0.01, flat = TRUE), wet_modis_sinu)
  e <- as.vector(terra::ext(p))
  h <- seq(floor((e[["xmin"]] - wet_modis_ul[1]) / wet_modis_tile_m),
           floor((e[["xmax"]] - wet_modis_ul[1]) / wet_modis_tile_m))
  v <- seq(floor((wet_modis_ul[2] - e[["ymax"]]) / wet_modis_tile_m),
           floor((wet_modis_ul[2] - e[["ymin"]]) / wet_modis_tile_m))
  hv <- expand.grid(h = h, v = v)
  keep <- vapply(seq_len(nrow(hv)), function(i) {
    x0 <- wet_modis_ul[1] + hv$h[i] * wet_modis_tile_m
    y1 <- wet_modis_ul[2] - hv$v[i] * wet_modis_tile_m
    # shrunk by 1 m: the parallels at 40, 50 and 60 N project onto tile edges to
    # within float noise, and a sliver of overlap would add a whole empty tile row
    tp <- terra::as.polygons(terra::ext(x0 + 1, x0 + wet_modis_tile_m - 1, y1 - wet_modis_tile_m + 1, y1 - 1),
                             crs = wet_modis_sinu)
    terra::relate(p, tp, "intersects")[1, 1]
  }, TRUE)
  sort(sprintf("h%02dv%02d", hv$h[keep], hv$v[keep]))
}

# Granules already in `dir`, one row per tile-year: path NA where none is.
wet_mod16_local <- function(dir, tiles, years) {
  f <- list.files(dir, "^MOD16A3GF\\.A[0-9]{7}\\.h[0-9]{2}v[0-9]{2}\\.061\\..*\\.hdf$", full.names = TRUE)
  id <- wet_mod16_id(basename(f))
  out <- expand.grid(tile = tiles, year = years, stringsAsFactors = FALSE)
  out$path <- vapply(seq_len(nrow(out)), function(i) {
    x <- f[id$tile == out$tile[i] & id$year == out$year[i]]
    if (length(x) > 1) stop("more than one local granule for ", out$tile[i], " ", out$year[i], ": ",
                            paste(basename(x), collapse = ", "), call. = FALSE)
    if (length(x)) x else NA_character_
  }, "")
  out
}

# tile and year from granule names such as MOD16A3GF.A2010001.h10v03.061.<prod>.hdf
wet_mod16_id <- function(x) {
  data.frame(tile = sub("^MOD16A3GF\\.A[0-9]{7}\\.(h[0-9]{2}v[0-9]{2})\\..*$", "\\1", x),
             year = as.integer(sub("^MOD16A3GF\\.A([0-9]{4}).*$", "\\1", x)))
}

# Every tile-year has exactly one granule.
wet_mod16_check <- function(gr, tiles, years) {
  n <- table(factor(gr$tile, levels = tiles), factor(gr$year, levels = years))
  idx <- which(n == 0, arr.ind = TRUE)
  if (nrow(idx)) {
    stop("no MOD16A3GF granule for ", paste(tiles[idx[, 1]], years[idx[, 2]], collapse = ", "), call. = FALSE)
  }
  idx <- which(n > 1, arr.ind = TRUE)
  if (nrow(idx)) {
    stop("more than one MOD16A3GF granule for ", paste(tiles[idx[, 1]], years[idx[, 2]], collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}

# MOD16A3GF v061 granules over the grid's extent from NASA's CMR (public).
wet_mod16_search <- function(grid, years) {
  e <- as.vector(terra::ext(grid))
  url <- paste0("https://cmr.earthdata.nasa.gov/search/granules.json?short_name=MOD16A3GF&version=061",
                sprintf("&temporal=%d-01-01T00:00:00Z,%d-12-31T23:59:59Z", min(years), max(years)),
                sprintf("&bounding_box=%.6f,%.6f,%.6f,%.6f", e[["xmin"]], e[["ymin"]], e[["xmax"]], e[["ymax"]]),
                "&page_size=2000")
  res <- curl::curl_fetch_memory(url, handle = curl::new_handle(useragent = "wet"))
  if (res$status_code != 200) stop("HTTP ", res$status_code, " from CMR", call. = FALSE)
  entry <- jsonlite::fromJSON(rawToChar(res$content), simplifyVector = FALSE)$feed$entry
  hits <- as.integer(curl::parse_headers_list(res$headers)[["cmr-hits"]])
  if (length(hits) != 1 || is.na(hits) || hits != length(entry)) {
    stop("CMR returned ", length(entry), " of ", hits, " granules; page through them", call. = FALSE)
  }
  url <- vapply(entry, function(x) {
    h <- vapply(x$links, function(l) l$href, "")
    h <- h[grepl("^https://.*/MOD16A3GF\\.[^/]*\\.hdf$", h)]
    if (length(h) != 1) stop("no single https .hdf link for ", x$title, call. = FALSE)
    h
  }, "")
  out <- wet_mod16_id(basename(url))
  out$url <- url
  out[out$year %in% years, ]
}

# ET_500m as mm/yr (terra applies the file's 0.1 scale), a whole 2400 x 2400 tile.
wet_mod16_read <- function(f) {
  r <- terra::rast(sprintf('HDF4_EOS:EOS_GRID:"%s":MOD_Grid_MOD16A3:ET_500m', normalizePath(f)))
  if (!isTRUE(all.equal(unname(terra::scoff(r)[1, ]), c(0.1, 0)))) {
    stop(basename(f), ": ET_500m is not scaled by 0.1", call. = FALSE)
  }
  if (terra::nrow(r) != 2400 || terra::ncol(r) != 2400) stop(basename(f), ": not a 2400 x 2400 tile", call. = FALSE)
  r
}

# Per-pixel mean over valid years in each tile, a sinusoidal mosaic, then
# nearest onto `grid` disaggregated by `fact` and block means back onto it.
wet_mod16_grid <- function(local, grid, fact, min_years) {
  per_tile <- lapply(split(local$path, local$tile), function(f) {
    s <- NULL
    n <- NULL
    for (x in f) {
      r <- wet_mod16_read(x)
      # valid raw values are 0-65500 (0-6550 scaled); 65529-65535 are gap codes
      r <- terra::ifel(r > 6551, NA, r)
      # a scale read wrongly would pass the mask; no land evaporates 3 m a year
      mx <- terra::global(r, "max", na.rm = TRUE)[[1]]
      if (is.finite(mx) && mx > 3000) stop(basename(x), ": ET up to ", mx, " mm/yr after masking", call. = FALSE)
      ok <- !is.na(r)
      s <- if (is.null(s)) terra::ifel(ok, r, 0) else s + terra::ifel(ok, r, 0)
      n <- if (is.null(n)) ok else n + ok
    }
    terra::ifel(n >= min_years, s / n, NA)
  })
  mos <- if (length(per_tile) == 1) per_tile[[1]] else terra::merge(terra::sprc(unname(per_tile)))
  tmp <- tempfile(fileext = ".tif")
  on.exit(unlink(tmp), add = TRUE)
  # geometry only: disagg() of the grid itself would first write out its values
  fine <- terra::project(mos, terra::disagg(terra::rast(grid), fact), method = "near", filename = tmp)
  aet <- terra::aggregate(fine, fact, fun = "mean", na.rm = TRUE)
  frac <- terra::aggregate(!is.na(fine), fact, fun = "mean")
  aet <- terra::ifel(frac > 0, aet, NA)
  out <- c(aet, frac)
  if (!terra::compareGeom(out, grid, stopOnError = FALSE)) stop("MOD16 grid is off the target grid", call. = FALSE)
  names(out) <- c("et_mod16", "frac_mod16")
  out
}

# The netrc holding the Earthdata login (see wet_mod16_aet()).
wet_earthdata_netrc <- function() {
  has_urs <- function(f) any(grepl("machine urs.earthdata.nasa.gov", readLines(f, warn = FALSE), fixed = TRUE))
  f <- getOption("wet.earthdata_netrc")
  if (!is.null(f)) {
    if (!file.exists(f)) stop("netrc ", f, " (option wet.earthdata_netrc) does not exist", call. = FALSE)
    if (!has_urs(f)) stop("netrc ", f, " has no 'machine urs.earthdata.nasa.gov' entry", call. = FALSE)
    return(f)
  }
  cand <- c(Sys.getenv("NETRC"), file.path(tools::R_user_dir("earthdatalogin"), "netrc"), path.expand("~/.netrc"))
  cand <- cand[nzchar(cand) & file.exists(cand)]
  cand <- cand[vapply(cand, has_urs, TRUE)]
  if (!length(cand)) {
    stop("no netrc with a 'machine urs.earthdata.nasa.gov' entry; set options(wet.earthdata_netrc = <path>)",
         call. = FALSE)
  }
  cand[1]
}
