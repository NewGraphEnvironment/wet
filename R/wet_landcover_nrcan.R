#' Land-cover fractions on a grid from the NRCan 2020 land cover
#'
#' Downloads the Natural Resources Canada 2020 Land Cover of Canada (30 m,
#' Cloud-Optimized GeoTIFF, Open Government Licence - Canada) once, and
#' averages it onto `grid` as one fraction layer per land-cover class of
#' [wet_chapman_table3()]: the share of each cell covered by the NRCan codes
#' that map to that class.
#'
#' It is done in two steps. First the codes are resampled (nearest) onto a grid
#' `fact` times finer than `grid` and aligned with it, in `grid`'s CRS. Then a
#' VRT carries one band per class, each a lookup table that turns the class's
#' codes into 1 and every other code into 0, and `terra::aggregate()` takes
#' their block means onto `grid`. A single
#' average warp from the source CRS is not used: GDAL takes each target cell's
#' footprint as an axis-aligned rectangle in the source CRS, and NRCan's Lambert
#' conformal grid is rotated about 20 degrees against a lon/lat cell in western
#' BC, which put single cells off by up to 0.3 (measured 2026-09-27; the two-step
#' fractions match exact-overlap counts to a mean 0.002). Ground outside Canada
#' (the product's no-data 0) and codes no class claims count as uncovered, so
#' the fractions of a cell sum to less than 1 there and [wet_aet_landcover()]
#' leaves that part of the cell unadjusted.
#'
#' NRCan publishes no checksum for the file (its ETag is a multipart hash), so
#' the download is written to `.part` and renamed only on HTTP 200, its md5
#' belongs in the caller's input manifest, and the fractions are cached under a
#' key that includes the source file's md5 (hashing 2.1 GB takes a few seconds
#' on each call). The option `wet.nrcan_landcover_url` only sets where a missing
#' source file is fetched from; delete the cached file to fetch another.
#'
#' @param grid Target grid: a `SpatRaster` or a path to one (EPSG:4326 here).
#' @param table Class table with `class` and `nrcan_2020_codes` (`;`-separated).
#' @param dir Cache directory for the source file and the fractions.
#' @param overwrite Logical. Rebuild the fractions even when cached.
#' @param timeout Seconds allowed for the download (about 2.1 GB).
#' @param fact Subdivision of each `grid` cell for the nearest-neighbour step;
#'   30 makes a 30 arc-second grid 1 arc-second, about the source's 30 m.
#' @return Path to a GeoTIFF with one fraction layer (0-1) per class.
#' @export
#' @examplesIf interactive()
#' # about 2.1 GB on first use
#' g <- terra::rast(xmin = -120, xmax = -119, ymin = 49, ymax = 50, res = 1 / 120)
#' fr <- terra::rast(wet_landcover_nrcan(g))
#' terra::global(fr, "mean")
wet_landcover_nrcan <- function(grid, table = wet_chapman_table3(), dir = "data/landcover",
                                overwrite = FALSE, timeout = 7200, fact = 30) {
  grid <- if (inherits(grid, "SpatRaster")) grid[[1]] else terra::rast(grid)[[1]]
  default_url <- paste0("https://datacube-prod-data-public.s3.ca-central-1.amazonaws.com/store/land/",
                        "landcover/landcover-2020-classification.tif")
  url <- getOption("wet.nrcan_landcover_url", default_url)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  src <- file.path(dir, basename(url))
  if (!file.exists(src)) wet_download(url, src, timeout)
  dest <- wet_landcover_dest(grid, table, dir, c(unname(tools::md5sum(src)), fact))
  if (file.exists(dest) && !overwrite) return(dest)
  wet_landcover_fractions(src, grid, table, dest, fact)
}

# Cache path: keyed on the grid, the class table (codes and classes) and the
# md5 of the source file actually read, so a changed crosswalk or a revised
# source never reuses old fractions. The url is not in the key: it only says
# where a missing file is fetched from.
wet_landcover_dest <- function(grid, table, dir, source_id) {
  key <- wet_md5_text(paste(c(wet_grid_key(grid), table$class, table$nrcan_2020_codes, source_id),
                            collapse = "|"))
  file.path(dir, sprintf("lc2020_frac_%s.tif", substr(key, 1, 10)))
}

# Codes resampled (nearest) onto `grid` subdivided by `fact`, then one LUT band
# per class averaged onto `grid`, written to `dest`.
wet_landcover_fractions <- function(src, grid, table, dest, fact = 30) {
  codes <- lapply(strsplit(table$nrcan_2020_codes, ";"), function(x) as.integer(trimws(x)))
  all_codes <- unlist(codes)
  dup <- unique(all_codes[duplicated(all_codes)])
  if (length(dup)) stop("codes claimed by more than one class: ", paste(dup, collapse = ", "), call. = FALSE)
  if (anyNA(all_codes) || any(all_codes < 1 | all_codes > 254)) {
    stop("land-cover codes must be integers in 1-254", call. = FALSE)
  }
  fine <- tempfile(fileext = ".tif", tmpdir = dirname(dest))
  on.exit(unlink(fine), add = TRUE)
  # NA (the source's no-data) written back as 0, which the LUT counts as uncovered
  # geometry only: disagg() of the grid itself would first write out its values
  terra::project(terra::rast(src), terra::disagg(terra::rast(grid), fact), method = "near", filename = fine,
                 wopt = list(datatype = "INT1U", NAflag = 0, gdal = "COMPRESS=LZW"))
  r <- terra::rast(fine)
  # Every integer 0-255 is listed, because GDAL interpolates linearly between
  # LUT entries: a gap would give a fractional indicator for codes inside it.
  lut <- function(k) paste(sprintf("%d:%d", 0:255, as.integer(0:255 %in% k)), collapse = ",")
  bands <- vapply(seq_along(codes), function(i) {
    sprintf(paste0('<VRTRasterBand dataType="Float32" band="%d"><Description>%s</Description>',
                   "<ComplexSource><SourceFilename relativeToVRT=\"0\">%s</SourceFilename>",
                   "<SourceBand>1</SourceBand><LUT>%s</LUT></ComplexSource></VRTRasterBand>"),
            i, wet_xml_escape(table$class[i]), wet_xml_escape(normalizePath(fine)), lut(codes[[i]]))
  }, "")
  e <- terra::ext(r)
  vrt <- tempfile(fileext = ".vrt", tmpdir = dirname(dest))
  on.exit(unlink(vrt), add = TRUE)
  xml <- c(sprintf('<VRTDataset rasterXSize="%d" rasterYSize="%d">', terra::ncol(r), terra::nrow(r)),
           sprintf("<SRS>%s</SRS>", wet_xml_escape(terra::crs(r))),
           sprintf("<GeoTransform>%.17g, %.17g, 0, %.17g, 0, %.17g</GeoTransform>",
                   e$xmin, terra::xres(r), e$ymax, -terra::yres(r)),
           bands, "</VRTDataset>")
  writeLines(xml, vrt)
  lc <- terra::rast(vrt)
  tmp <- tempfile(fileext = ".tif", tmpdir = dirname(dest))
  on.exit(unlink(tmp), add = TRUE)
  out <- terra::aggregate(lc, fact, fun = "mean")
  if (!terra::compareGeom(out, grid, stopOnError = FALSE)) stop("fractions are off the grid", call. = FALSE)
  names(out) <- table$class
  terra::writeRaster(out, tmp, datatype = "FLT4S", overwrite = TRUE)
  if (!file.rename(tmp, dest)) stop("could not move fractions to ", dest, call. = FALSE)
  dest
}

wet_xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
