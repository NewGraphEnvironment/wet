# A copy of cd's example daily cube (2002, 5 x 5 cells at 0.1 degrees, 54.25-54.75 N,
# 126.45-125.95 W) with cells set to no-data, for the air temperature lookup (#216). cd's
# own cube has no empty cell. Masked: the top-left 2 x 2 block (cells 1, 2, 6, 7: cell 1
# then has no data around it, cell 2 has data to its east) and cell 19 alone, which has
# data on every side. Also sourced by data-raw/air_example_data.R.
air_masked_cells <- c(1L, 2L, 6L, 7L, 19L)

air_masked_cube <- function(dir) {
  src <- system.file("extdata", "example_daily", package = "cd")
  if (!nzchar(src)) stop("cd's example cube is not installed", call. = FALSE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  for (v in c("tmean", "tmax", "tmin")) {
    f <- file.path(src, paste0(v, "_daily_2002.tif"))
    r <- terra::rast(f)
    m <- terra::values(r)
    m[air_masked_cells, ] <- NA
    out <- terra::rast(r)
    terra::values(out) <- m
    names(out) <- names(r)
    terra::writeRaster(out, file.path(dir, basename(f)), datatype = "FLT4S", overwrite = TRUE,
                       gdal = c("COMPRESS=DEFLATE"))
  }
  dir
}

# Made-up segments placed for each status on the masked cube, in two groups.
air_fixture_points <- function() {
  data.frame(
    linear_feature_id = c(1, 2, 3, 4, 5, 6, 7),
    watershed_group_code = c("AAAA", "AAAA", "AAAA", "AAAA", "AAAA", "AAAA", "BBBB"),
    lon = c(-126.21, -126.18, -126.12, -126.42, -125.50, -126.31, -126.38),
    lat = c(54.52, 54.47, 54.42, 54.72, 54.50, 54.69, 54.31),
    elev = c(600, 610, 640, 700, 900, 720, 580),
    stringsAsFactors = FALSE
  )
}
