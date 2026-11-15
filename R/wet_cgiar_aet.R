#' Actual evapotranspiration from the CGIAR Global Soil-Water Balance
#'
#' Downloads the CGIAR-CSI Global High-Resolution Soil-Water Balance v3 AET
#' (Trabucco & Zomer; figshare article 7707605, CC0), checks each archive
#' against the md5 figshare reports, extracts it, and crops the annual and 12
#' monthly grids to `bbox`. The crop is cached under a name keyed on the
#' archives' md5s, so a revised archive gives a new crop. This is the ET family Chapman et al. (2018) used,
#' on its native 30 arc-second grid, so it is cropped but never resampled.
#'
#' The archives are RAR4 and ship ArcInfo grids. They are extracted with
#' `bsdtar` (libarchive), which reads RAR4; the Homebrew `7z` build does not.
#'
#' @param bbox Numeric `c(xmin, ymin, xmax, ymax)` in degrees (EPSG:4326),
#'   snapped outward to the 30 arc-second cell lattice.
#' @param dir Cache directory for the archives, extracted grids and the crop.
#' @param overwrite Logical. Rebuild the crop even when it is cached.
#' @param timeout Seconds allowed for each download.
#' @return Path to a GeoTIFF with 13 layers, `aet_01` to `aet_12` and `aet_yr`,
#'   in mm.
#' @export
wet_cgiar_aet <- function(bbox, dir = "data/cgiar", overwrite = FALSE,
                          timeout = 3600) {
  stopifnot(is.numeric(bbox), length(bbox) == 4, bbox[1] < bbox[3], bbox[2] < bbox[4])
  # The crop is computed from the bbox snapped outward to the CGIAR cell
  # lattice, and keyed on those integer cell indices, so the cached content is
  # a function of the key alone. Any decimal encoding of the requested bbox
  # can collide, because terra snaps a cell edge with no tolerance. The method
  # version and the md5 of each source archive ride along, so neither a
  # changed crop nor a revised archive ever reuses an old file.
  cells <- wet_cgiar_cells(bbox)
  rars <- file.path(dir, wet_cgiar_archives)
  if (!overwrite && all(file.exists(rars))) {
    dest <- wet_cgiar_dest(dir, cells, unname(tools::md5sum(rars)))
    if (file.exists(dest)) return(dest)
  }
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  # A rebuild first brings each archive into line with the md5 figshare
  # reports now, so a revised archive is fetched rather than reused.
  files <- wet_figshare_files(7707605)
  for (i in seq_along(rars)) {
    nm <- wet_cgiar_archives[i]
    hit <- files[files$name == nm, ]
    if (nrow(hit) != 1) stop("figshare article 7707605 has no file ", nm, call. = FALSE)
    if (!file.exists(rars[i]) || unname(tools::md5sum(rars[i])) != hit$md5) {
      wet_download(hit$url, rars[i], timeout)
      if (unname(tools::md5sum(rars[i])) != hit$md5) {
        stop(nm, " does not match the md5 figshare reports (", hit$md5, ")", call. = FALSE)
      }
    }
  }
  md5 <- unname(tools::md5sum(rars))
  dest <- wet_cgiar_dest(dir, cells, md5)
  if (file.exists(dest) && !overwrite) return(dest)

  src <- file.path(dir, "src")
  done <- file.path(src, ".extracted")
  # A marker naming each archive's md5, written only after every archive
  # extracted: an interrupted extraction leaves directories that look
  # complete, and a replaced archive leaves grids extracted from the old one,
  # so the directories' presence is not evidence.
  stamp <- paste(wet_cgiar_archives, md5)
  if (!file.exists(done) || !identical(readLines(done, warn = FALSE), stamp)) {
    unlink(src, recursive = TRUE)
    for (i in seq_along(rars)) {
      exdir <- if (wet_cgiar_archives[i] == "aet_monthly.rar") file.path(src, "aet_monthly") else src
      wet_unrar(rars[i], exdir)
    }
    writeLines(stamp, done)
  }
  r <- wet_cgiar_stack(src, cells)
  tmp <- tempfile(fileext = ".tif", tmpdir = dir)
  on.exit(unlink(tmp), add = TRUE)
  terra::writeRaster(r, tmp, datatype = "INT2U", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move crop to ", dest, call. = FALSE)
  dest
}

# Bump whenever wet_cgiar_aet() or wet_cgiar_stack() changes what the crop holds.
wet_cgiar_method <- "crop-near-int2u-1"

# The figshare archives the crop is built from, in the order their md5s enter its key.
wet_cgiar_archives <- c("AET_YR.rar", "aet_monthly.rar")

# The crop's path for lattice cells, keyed on the cells, the method version
# and the archives' md5s (#23).
wet_cgiar_dest <- function(dir, cells, md5) {
  key <- wet_md5_text(paste(c(wet_cgiar_method, md5), collapse = "|"))
  file.path(dir, sprintf("cgiar_aet_c%d-%d_r%d-%d_%s.tif", cells[1], cells[2], cells[3], cells[4],
                         substr(key, 1, 8)))
}

# Column and row indices (0-based edges) of the CGIAR 1/120-degree lattice,
# origin -180 / 90, that enclose bbox. The 1e-6-cell tolerance keeps a value
# that is on an edge in principle from flipping on floating-point noise.
wet_cgiar_cells <- function(bbox, res = 1 / 120, tol = 1e-6) {
  c(col0 = floor((bbox[1] + 180) / res + tol), col1 = ceiling((bbox[3] + 180) / res - tol),
    row0 = floor((90 - bbox[4]) / res + tol), row1 = ceiling((90 - bbox[2]) / res - tol))
}

# Read the 12 monthly grids and the annual grid under `src` and crop to the
# lattice cells from wet_cgiar_cells().
wet_cgiar_stack <- function(src, cells, res = 1 / 120) {
  paths <- c(file.path(src, "aet_monthly", sprintf("aet_%d", 1:12)),
             file.path(src, "AET_YR", "aet_yr"))
  missing <- paths[!file.exists(paths)]
  if (length(missing)) stop("CGIAR grid missing: ", missing[1], call. = FALSE)
  r <- terra::rast(paths)
  e <- terra::ext(-180 + cells[[1]] * res, -180 + cells[[2]] * res,
                  90 - cells[[4]] * res, 90 - cells[[3]] * res)
  r <- terra::crop(r, e, snap = "near")
  names(r) <- c(sprintf("aet_%02d", 1:12), "aet_yr")
  r
}

# name, url and md5 of each file in a public figshare article.
wet_figshare_files <- function(article) {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  base <- getOption("wet.figshare_api", "https://api.figshare.com")
  wet_download(sprintf("%s/v2/articles/%d", base, article), tmp, 60)
  x <- jsonlite::fromJSON(tmp)$files
  data.frame(name = x$name, url = x$download_url, md5 = x$computed_md5)
}

# Download with the HTTP status checked, following redirects (figshare
# serves files from a redirect).
# Written to "<dest>.part" and renamed only on HTTP 200, so a timeout or an
# error page never leaves a file at `dest` that a cache check would trust.
# `netrc` names a netrc file for hosts that ask for a login (Earthdata's
# redirects), with cookies kept across the redirect chain.
wet_download <- function(url, dest, timeout, netrc = NULL) {
  part <- paste0(dest, ".part")
  on.exit(unlink(part), add = TRUE)
  h <- curl::new_handle(followlocation = TRUE, timeout = timeout, useragent = "wet")
  if (!is.null(netrc)) curl::handle_setopt(h, netrc = 1L, netrc_file = netrc, cookiefile = "")
  res <- curl::curl_fetch_disk(url, part, handle = h)
  if (res$status_code != 200) stop("HTTP ", res$status_code, " from ", url, call. = FALSE)
  if (!file.rename(part, dest)) stop("could not move download to ", dest, call. = FALSE)
  invisible(dest)
}

wet_unrar <- function(rar, exdir) {
  bsdtar <- Sys.which("bsdtar")
  if (!nzchar(bsdtar)) {
    stop("extracting ", basename(rar), " needs bsdtar (libarchive), which reads RAR4",
         call. = FALSE)
  }
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
  status <- system2(bsdtar, c("-xf", shQuote(rar), "-C", shQuote(exdir)))
  if (status != 0) stop("bsdtar failed on ", rar, " (status ", status, ")", call. = FALSE)
  invisible(exdir)
}
