# The shared core of scripts/air_publish.R (#216, move 21): daily air temperature on every
# Freshwater Atlas segment as two datasets under one tree, air_temperature/fwa/v1:
# segment_cell (each segment's ERA5-Land cell) and cell_daily (each used cell's days, copied
# from cd's daily cube). Sourced after devtools::load_all(); not run on its own. Also sourced
# by data-raw/air_example_data.R and tests/testthat/test-air_publish_lib.R. Needs arrow and
# crate (the release carrying the two schemas); the build also needs duckdb, cd, terra and
# fwapg.

air_bucket <- "fresh-bc"
air_id <- "air_temperature/fwa/v1"
air_url <- sprintf("https://%s.s3.us-west-2.amazonaws.com/%s/manifest.json", air_bucket, air_id)
stopifnot(identical(air_id, wet:::wet_air_id), identical(air_url, wet:::wet_air_catalog_url))
air_scenario <- "historical"
air_forcing <- "ERA5-Land"
air_source <- "cd_daily"
air_mask_day <- wet:::wet_air_mask_day
air_vars <- c("tmean", "tmax", "tmin")

# cd's daily cube as the build reads it, passed to every cd call (never cd's option), and the
# published grid: the build holds the mask file and every year's three files to it
air_cube_url <- "https://stac-era5-land.s3.us-west-2.amazonaws.com/daily"
air_grid <- list(xmin = -140.05, xmax = -113.95, ymin = 47.95, ymax = 60.05, nrow = 121L, ncol = 261L,
                 res = 0.1, crs = "EPSG:4326")

# The files whose change since the build's commit stales a built tree: what the build and
# its checks read. tests/testthat/test-air_publish_lib.R derives the same list from the
# calls the scripts make, so a new dependency fails that test rather than passing the
# upload's guard.
air_code_files <- c(
  "scripts/air_publish.R", "scripts/air_publish_lib.R", "R/wet_air_daily.R", "R/wet_catalog.R",
  "R/wet_db_load.R",  # wet's %||%, which the build and wet_catalog_verify() use
  "inst/receipt/air_temperature_fwa_v1.yaml"
)

# The part key for a unit and code, through wet's own parser, so writer and reader agree.
air_part_key <- function(unit, code) {
  key <- sprintf("%s/scenario=%s/forcing=%s/source=%s/part-%s.parquet", unit, air_scenario, air_forcing,
                 air_source, code)
  p <- wet:::wet_part_parse(key, air_id)
  stopifnot(identical(p$dataset, paste(air_id, unit, sep = "/")), identical(p$code, as.character(code)))
  key
}

# Each column's parquet type: the crate schema says integer, double, string, date; the
# values of cell_daily are written as the cube's own 4-byte float, which holds every value
# the cube holds exactly (checked on a whole year in #237's findings), so none is rounded.
air_arrow_types <- list(
  segment_cell = list(linear_feature_id = arrow::int32(), watershed_group_code = arrow::utf8(),
                      cell_id = arrow::int32(), cell_x = arrow::float64(), cell_y = arrow::float64(),
                      cell_status = arrow::utf8(), point_x = arrow::float64(), point_y = arrow::float64(),
                      segment_elev_m = arrow::float64()),
  cell_daily = list(cell_id = arrow::int32(), date = arrow::date32(), tmean_c = arrow::float32(),
                    tmax_c = arrow::float32(), tmin_c = arrow::float32())
)
air_statuses <- c("own", "moved", "no_data", "outside")

# The segment_cell frame of one watershed group: `points` data.frame(linear_feature_id,
# watershed_group_code, lon, lat, elev), `cells` wet_air_cells() of those points.
air_lookup_frame <- function(points, cells) {
  stopifnot(identical(as.numeric(points$linear_feature_id), as.numeric(cells$linear_feature_id)))
  x <- data.frame(
    linear_feature_id = points$linear_feature_id, watershed_group_code = points$watershed_group_code,
    cell_id = cells$cell_id, cell_x = cells$cell_x, cell_y = cells$cell_y, cell_status = cells$cell_status,
    point_x = points$lon, point_y = points$lat, segment_elev_m = points$elev, stringsAsFactors = FALSE
  )
  x[order(x$linear_feature_id, method = "radix"), , drop = FALSE]
}

# Conform a frame to its crate schema and check what conforming must not change and what
# the dataset must hold; returns the frame in its stored order.
air_conform <- function(x, unit) {
  dataset <- paste(air_id, unit, sep = "/")
  cols <- names(air_arrow_types[[unit]])
  if (!identical(names(x), cols)) stop(unit, ": columns must be ", paste(cols, collapse = ", "))
  na_before <- vapply(x, function(v) sum(is.na(v)), 0)
  y <- as.data.frame(crate::crt_schema_conform(x, "nge", dataset))
  if (!identical(names(y), cols) || !identical(vapply(y, function(v) sum(is.na(v)), 0), na_before)) {
    stop(dataset, ": crt_schema_conform() changed a column or an NA count; fix the frame, not the schema")
  }
  if (unit == "segment_cell") {
    has <- y$cell_status %in% c("own", "moved")
    stopifnot(
      !anyNA(y$linear_feature_id), !anyDuplicated(y$linear_feature_id), !anyNA(y$watershed_group_code),
      all(y$cell_status %in% air_statuses), !anyNA(y$point_x), !anyNA(y$point_y),
      all(!is.na(y$cell_id[has])), all(is.na(y$cell_id[!has])), all(is.na(y$cell_x[!has])),
      identical(y$cell_id[has], wet:::wet_air_cell_id(y$cell_x[has], y$cell_y[has]))
    )
    y <- y[order(y$linear_feature_id, method = "radix"), , drop = FALSE]
  } else {
    stopifnot(!anyNA(y$cell_id), !anyNA(y$date), !anyDuplicated(y[c("cell_id", "date")]))
    y <- y[order(y$cell_id, y$date, method = "radix"), , drop = FALSE]
  }
  rownames(y) <- NULL
  y
}

# Write a conformed frame as one part under `root`, typed by air_arrow_types, in row groups
# of `rows_per_group` so a read of a few segments or cells skips the rest on their
# statistics. Written to a temporary file and moved. No time, host or path is written into
# the file, so the same frame writes the same bytes.
air_part_write <- function(x, root, unit, code, rows_per_group = 1e6) {
  types <- air_arrow_types[[unit]]
  stopifnot(identical(names(x), names(types)))
  path <- file.path(root, air_part_key(unit, code))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  arrays <- Map(function(v, ty) arrow::Array$create(v)$cast(ty), x, types)
  tab <- do.call(arrow::arrow_table, arrays)
  if (unit == "cell_daily") {
    back <- lapply(c("tmean_c", "tmax_c", "tmin_c"), function(k) as.numeric(tab[[k]]$as_vector()))
    if (!identical(back, unname(as.list(x[c("tmean_c", "tmax_c", "tmin_c")])))) {
      stop("a cell_daily value does not survive a 4-byte float: the cube is not the type it was")
    }
  }
  tmp <- paste0(path, ".tmp")
  arrow::write_parquet(tab, tmp, compression = "zstd", chunk_size = rows_per_group)
  if (!file.rename(tmp, path)) stop("could not move ", tmp)
  invisible(path)
}

# The cell_daily frame of one year from cd_extract_daily() at the used cells' centres (its
# long output): every cell must come back on its own cell, unmoved, with values and a
# checksum, or the year is refused.
air_daily_frame <- function(x, cells) {
  stopifnot(all(air_vars %in% unique(x$variable)))
  back_id <- wet:::wet_air_cell_id(x$cell_x, x$cell_y)
  if (anyNA(x$cell) || any(x$cell_moved) || !identical(back_id, as.integer(x$id))) {
    stop("cd placed a cell centre on another cell, or moved it")
  }
  if (anyNA(x$value)) stop("cd returned NA at a used cell: ", paste(unique(x$id[is.na(x$value)])[1:3], collapse = ", "))
  if (anyNA(x$checksum)) stop("cd returned no checksum for a cube file: a stale cached file?")
  w <- lapply(air_vars, function(v) x[x$variable == v, c("id", "date", "value")])
  for (i in 2:3) stopifnot(identical(w[[i]][c("id", "date")], w[[1]][c("id", "date")]))
  y <- data.frame(cell_id = as.integer(w[[1]]$id), date = w[[1]]$date, tmean_c = w[[1]]$value,
                  tmax_c = w[[2]]$value, tmin_c = w[[3]]$value)
  stopifnot(setequal(unique(y$cell_id), cells))
  y
}

# ---- the source's description and citation (read from cd's NOTICE.md and README, and the
# publisher's pages: the ESSD article and the Copernicus dataset page, 2026-11-27) -----------
air_source_description <- paste(
  "Daily mean, maximum and minimum 2 m air temperature (degrees C) on BC's local standard day (UTC-8),",
  "from cd's daily ERA5-Land cube (cd::cd_extract_daily()), copied unchanged for the cells Freshwater",
  "Atlas segments read: no downscaling, no lapse-rate or elevation adjustment. ERA5-Land is produced by",
  "ECMWF for the Copernicus Climate Change Service; cd reads it from the DestinE Earth Data Hub and",
  "aggregates the hourly data to local days. Contains modified Copernicus Climate Change Service",
  "information, under CC BY 4.0."
)
air_source_citation <- paste(
  "Munoz-Sabater, J., Dutra, E., Agusti-Panareda, A., et al. (2021). ERA5-Land: a state-of-the-art global",
  "reanalysis dataset for land applications. Earth System Science Data, 13, 4349-4383.",
  "https://doi.org/10.5194/essd-13-4349-2021. Dataset: ERA5-Land hourly data from 1950 to present,",
  "Copernicus Climate Change Service, https://doi.org/10.24381/cds.e2161bac (CC BY 4.0). Daily cube:",
  "%s"
)

# ---- the grid and the checks that do not pass through the code that made the tree --------------
# A template on the cube's grid, from its definition alone.
air_template <- function() {
  terra::rast(xmin = air_grid$xmin, xmax = air_grid$xmax, ymin = air_grid$ymin, ymax = air_grid$ymax,
              nrows = air_grid$nrow, ncols = air_grid$ncol, crs = air_grid$crs)
}

# A cell_id's centre, the inverse of wet_air_cell_id().
air_cell_centre <- function(id) {
  row <- id %/% 3600L
  col <- id %% 3600L
  x <- col / 10
  data.frame(x = ifelse(x > 180, x - 360, x), y = 90 - row / 10)
}

# Compared, differing and the largest difference, as each check reports them.
air_check_line <- function(name, compared, differing, largest = NA) {
  sprintf("%s: compared %d, differing %d, largest difference %s -> %s", name, compared, differing,
          if (is.na(largest)) "-" else format(signif(largest, 6)), if (differing == 0L) "pass" else "FAIL")
}

# Every own row's cell from its point and the grid alone (terra's cellFromXY on the grid's
# definition: a point exactly on a cell edge is where plain floor() arithmetic disagrees),
# and every moved, no_data and outside row by cd's stated rule on the mask: a moved row's
# own cell has no data and its cell is the nearest of the eight around with data
# (geodesic distance from the point to the cell centre, ties to the lower cell number); a
# no_data row has none of the nine with data; an outside row's point is off the grid.
# `mask` is TRUE where the mask day's band holds data, by cell of the template.
air_check_cells <- function(lk, template, mask) {
  cell <- terra::cellFromXY(template, as.matrix(lk[c("point_x", "point_y")]))
  centre_id <- function(cl) {
    xy <- terra::xyFromCell(template, cl)
    wet:::wet_air_cell_id(xy[, 1], xy[, 2])
  }
  own <- lk$cell_status == "own"
  own_bad <- is.na(cell[own]) | !mask[cell[own]] | centre_id(cell[own]) != lk$cell_id[own]
  out <- lk$cell_status == "outside"
  out_bad <- !is.na(cell[out])
  rest <- which(lk$cell_status %in% c("moved", "no_data"))
  rest_bad <- vapply(rest, function(i) {
    c0 <- cell[i]
    if (is.na(c0) || mask[c0]) return(TRUE)
    nb <- terra::adjacent(template, c0, directions = "queen")
    nb <- nb[!is.na(nb)]
    nb <- nb[mask[nb]]
    if (lk$cell_status[i] == "no_data") return(length(nb) > 0L || !is.na(lk$cell_id[i]))
    if (!length(nb)) return(TRUE)
    d <- terra::distance(as.matrix(lk[i, c("point_x", "point_y")]), terra::xyFromCell(template, nb), lonlat = TRUE)
    centre_id(nb[order(as.vector(d), nb)[1]]) != lk$cell_id[i]
  }, logical(1))
  mv <- lk$cell_status[rest] == "moved"
  c(
    air_check_line("own rows: cell from the point and the grid", sum(own), sum(own_bad)),
    air_check_line("moved rows: cd's rule from the point and the mask", sum(mv), sum(rest_bad[mv])),
    air_check_line("no_data rows: none of the nine cells has data", sum(!mv), sum(rest_bad[!mv])),
    air_check_line("outside rows: the point is off the grid", sum(out), sum(out_bad))
  )
}

# Every used cell has every day of the year in a year's part, and no other cell is there.
air_check_complete <- function(y, used, year) {
  days <- seq(as.Date(sprintf("%d-01-01", year)), as.Date(sprintf("%d-12-31", year)), by = "day")
  have <- paste(y$cell_id, as.integer(y$date))
  want <- paste(rep(used, each = length(days)), rep(as.integer(days), times = length(used)))
  missing <- sum(!want %in% have)
  extra <- sum(!have %in% want)
  list(compared = length(want), differing = missing + extra)
}

# A year part's values against the cube's files read directly with terra (not through cd):
# `files` the local cube files by variable. Returns compared, differing, largest difference.
air_check_values <- function(y, files) {
  ids <- sort(unique(y$cell_id))
  ctr <- air_cell_centre(ids)
  out <- list(compared = 0L, differing = 0L, largest = 0)
  for (v in air_vars) {
    r <- terra::rast(files[[v]])
    cells <- terra::cellFromXY(r, as.matrix(ctr))
    if (anyNA(cells)) stop("a used cell is off the cube's ", v, " file")
    m <- as.matrix(terra::extract(r, cells))
    dates <- as.Date(names(r))
    got <- y[[paste0(v, "_c")]][match(paste(rep(ids, times = length(dates)), rep(as.integer(dates), each = length(ids))),
                                      paste(y$cell_id, as.integer(y$date)))]
    ref <- as.vector(m)
    d <- abs(got - ref)
    out$compared <- out$compared + length(ref)
    out$differing <- out$differing + sum(is.na(d) | d != 0)
    out$largest <- max(out$largest, d, na.rm = TRUE)
  }
  out
}
