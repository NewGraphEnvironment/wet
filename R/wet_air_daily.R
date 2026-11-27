#' Daily air temperature on FWA segments
#'
#' Reads daily air temperature for Freshwater Atlas stream segments from wet's
#' published `air_temperature/fwa/v1` tree: each segment's ERA5-Land cell from
#' `segment_cell`, then that cell's days from `cell_daily`. The values are
#' cd's daily cube ([cd::cd_extract_daily()]) copied unchanged, so a segment
#' reads what `cd_extract_daily()` gives at the segment's midpoint, without
#' cd, raster tooling or a download of the cube. The result has the columns
#' [wet_temp_fill()] reads as `air`.
#'
#' @section The cell:
#' A segment takes the cell holding its midpoint along the line. Where that
#' cell has no data (the coast, large lakes) it takes the nearest of the eight
#' around it that has, as cd does (`cell_status` `"moved"`); where none of the
#' nine has, or the midpoint is outside cd's box, it has no cell (`"no_data"`,
#' `"outside"`) and its values are `NA`. Which cells have data is read from
#' one day of the cube, which the manifest names. There is no elevation
#' adjustment between the cell and the segment.
#'
#' @section The day:
#' A day is BC's local standard day (UTC-8), as cd defines it, so `date` is a
#' calendar day, not an instant.
#'
#' @param segments FWA `linear_feature_id`s, whole numbers, none `NA`.
#' @param from,to First and last day, as `Date` or `"YYYY-MM-DD"`.
#' @param variables Any of `"tmean"`, `"tmax"`, `"tmin"` (°C).
#' @param groups Watershed group codes holding the segments (required): only
#'   their lookup parts are read. A segment outside them reads as missing.
#' @param catalog A [wet_catalog()] of the air tree. The default reads option
#'   `wet.air_catalog_url`, or else the published air manifest.
#' @return `data.frame(id, date, variable, value, cell_id, cell_x, cell_y,
#'   cell_moved, cell_status)`, one row per segment, variable and day, ordered
#'   by segment as given, variable as given and date. `id` is the
#'   `linear_feature_id`; `cell_id` numbers the cell on ERA5-Land's own 0.1°
#'   grid (not cd's cell number); `cell_moved` is `TRUE` for a `"moved"`
#'   segment. A segment with no cell, or one the lookup does not hold
#'   (`cell_status` `NA`), has its days with `value` `NA`.
#' @seealso [wet_temp_fill()], which takes this as `air`.
#' @examples
#' # a tiny made-up tree laid out as the published one, from cd's example cube
#' cat <- wet_catalog(system.file("extdata", "air_example", "manifest.json", package = "wet"))
#' a <- wet_air_daily(c(1, 2, 4), "2002-07-01", "2002-07-03", groups = "AAAA", catalog = cat)
#' a
#' @export
wet_air_daily <- function(segments, from, to, variables = "tmean", groups, catalog = NULL) {
  if (!is.numeric(segments) || !length(segments) || anyNA(segments) || any(segments != round(segments))) {
    stop("`segments` must be whole-number linear_feature_ids, none NA", call. = FALSE)
  }
  if (anyDuplicated(segments)) stop("`segments` lists a segment twice", call. = FALSE)
  from <- wet_air_date(from, "from")
  to <- wet_air_date(to, "to")
  if (from > to) stop("`from` (", from, ") is after `to` (", to, ")", call. = FALSE)
  vars <- c("tmean", "tmax", "tmin")
  if (!is.character(variables) || !length(variables) || anyNA(variables) || !all(variables %in% vars) ||
        anyDuplicated(variables)) {
    stop("`variables` must be one or more of ", paste(vars, collapse = ", "), ", each once", call. = FALSE)
  }
  if (missing(groups) || !is.character(groups) || !length(groups) || anyNA(groups) ||
        !all(grepl("^[A-Z]{4}$", groups))) {
    stop("`groups` must name the watershed groups (four capital letters) that hold the segments", call. = FALSE)
  }
  if (!requireNamespace("duckdb", quietly = TRUE)) stop("install duckdb to read the parquet parts", call. = FALSE)
  if (is.null(catalog)) catalog <- wet_catalog(getOption("wet.air_catalog_url", wet_air_catalog_url))
  id <- wet_air_id
  if (!identical(attr(catalog, "id"), id)) {
    stop("the catalog is ", attr(catalog, "id"), ", not the air tree ", id, call. = FALSE)
  }
  ids <- as.integer(segments)
  look_ds <- paste(id, "segment_cell", sep = "/")
  day_ds <- paste(id, "cell_daily", sep = "/")
  look <- catalog[catalog$dataset == look_ds & catalog$scenario == "historical" & catalog$code %in% groups, ]
  missing_groups <- setdiff(groups, look$code)
  if (length(missing_groups)) {
    stop("the catalog has no ", look_ds, " part for group ", paste(missing_groups, collapse = ", "), call. = FALSE)
  }
  years <- seq(as.integer(format(from, "%Y")), as.integer(format(to, "%Y")))
  daily <- catalog[catalog$dataset == day_ds & catalog$scenario == "historical", ]
  absent <- setdiff(as.character(years), daily$code)
  if (length(absent)) {
    stop("the catalog has no ", day_ds, " part for year ", paste(absent, collapse = ", "), call. = FALSE)
  }
  daily <- daily[daily$code %in% as.character(years), ]

  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE), add = TRUE)
  if (any(grepl("^https?://", c(look$href, daily$href)))) DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;")
  cells <- DBI::dbGetQuery(duck, sprintf(
    "SELECT linear_feature_id, cell_id, cell_x, cell_y, cell_status
     FROM read_parquet([%s], hive_partitioning = false) WHERE linear_feature_id IN (%s)",
    wet_sql_in(duck, look$href), wet_sql_in(duck, ids)
  ))
  if (anyDuplicated(cells$linear_feature_id)) {
    stop(look_ds, " lists segment ", cells$linear_feature_id[duplicated(cells$linear_feature_id)][1], " twice",
         call. = FALSE)
  }
  used <- unique(cells$cell_id[!is.na(cells$cell_id)])
  cols <- paste0(variables, "_c")
  vals <- if (length(used)) {
    DBI::dbGetQuery(duck, sprintf(
      "SELECT cell_id, date, %s FROM read_parquet([%s], hive_partitioning = false)
       WHERE cell_id IN (%s) AND date BETWEEN DATE '%s' AND DATE '%s'",
      paste(cols, collapse = ", "), wet_sql_in(duck, daily$href), paste(used, collapse = ", "),
      format(from), format(to)
    ))
  } else {
    stats::setNames(data.frame(integer(), as.Date(character()), matrix(numeric(), 0, length(cols))),
                    c("cell_id", "date", cols))
  }
  vals$date <- as.Date(vals$date)
  vk <- paste(vals$cell_id, as.integer(vals$date))
  if (anyDuplicated(vk)) stop(day_ds, " has more than one row for a cell and day", call. = FALSE)

  dates <- structure(as.double(seq(from, to, by = "day")), class = "Date")
  m <- match(ids, cells$linear_feature_id)
  seg <- data.frame(id = ids, cell_id = as.integer(cells$cell_id[m]), cell_x = as.numeric(cells$cell_x[m]),
                    cell_y = as.numeric(cells$cell_y[m]), cell_status = as.character(cells$cell_status[m]))
  nd <- length(dates)
  nv <- length(variables)
  i <- rep(seq_along(ids), each = nv * nd)
  out <- data.frame(
    id = ids[i],
    date = rep(dates, times = length(ids) * nv),
    variable = rep(rep(variables, each = nd), times = length(ids)),
    stringsAsFactors = FALSE
  )
  hit <- match(paste(seg$cell_id[i], as.integer(out$date)), vk)
  out$value <- NA_real_
  for (v in variables) {
    w <- out$variable == v
    out$value[w] <- as.numeric(vals[[paste0(v, "_c")]][hit[w]])
  }
  out$cell_id <- seg$cell_id[i]
  out$cell_x <- seg$cell_x[i]
  out$cell_y <- seg$cell_y[i]
  out$cell_moved <- seg$cell_status[i] %in% "moved"
  out$cell_status <- seg$cell_status[i]
  # a used cell missing a day the tree should hold reads as a refusal, not a gap
  if (any(!is.na(out$cell_id) & is.na(hit))) {
    stop(day_ds, " lacks days for a cell the lookup names: the tree is incomplete", call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

wet_air_id <- "air_temperature/fwa/v1"
wet_air_catalog_url <- "https://fresh-bc.s3.us-west-2.amazonaws.com/air_temperature/fwa/v1/manifest.json"

# The day whose cube band decides which cells hold data: 1 January of the
# cube's last year (cd reads "has data" from the first band of the first file
# a call opens). The manifest names its file.
wet_air_mask_day <- "2025-01-01"

wet_air_date <- function(x, what) {
  if (inherits(x, "Date") && length(x) == 1L && !is.na(x)) return(x)
  if (is.character(x) && length(x) == 1L && grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)) {
    d <- as.Date(x, format = "%Y-%m-%d")
    if (!is.na(d)) return(d)
  }
  stop("`", what, "` must be one Date or \"YYYY-MM-DD\"", call. = FALSE)
}

# ERA5-Land's native 0.1-degree grid, numbered from the cell centre: row 0 at
# 90 N, column 0 at 0 E (the formula crate's segment_cell schema states). It
# does not depend on cd's box.
wet_air_cell_id <- function(x, y) {
  as.integer(round((90 - y) * 10) * 3600 + round(((x + 360) %% 360) * 10))
}

# The cell for each point, by cd's own call for one day: list each point's
# cell_id, centre and status (own, moved, no_data, outside). `points` is
# data.frame(linear_feature_id, lon, lat). cd's two expected warnings, a point
# outside its box and one with no data around it, are muffled by their opening
# words, and the statuses come from cd's columns; any other warning is raised.
wet_air_cells <- function(points, day = wet_air_mask_day,
                          source = getOption("cd.daily_url",
                                             "https://stac-era5-land.s3.us-west-2.amazonaws.com/daily")) {
  if (!requireNamespace("cd", quietly = TRUE)) stop("install cd to place segments on its cube", call. = FALSE)
  stopifnot(is.data.frame(points), all(c("linear_feature_id", "lon", "lat") %in% names(points)),
            !anyDuplicated(points$linear_feature_id), !anyNA(points$linear_feature_id))
  expected <- "^(Outside the daily cube's extent|No ERA5-Land data in or around the cell for)"
  x <- withCallingHandlers(
    cd::cd_extract_daily(points[c("linear_feature_id", "lon", "lat")], day, day, "tmean",
                         id = "linear_feature_id", source = source),
    warning = function(w) if (grepl(expected, conditionMessage(w))) invokeRestart("muffleWarning")
  )
  if (nrow(x) != nrow(points) || !identical(as.numeric(x$id), as.numeric(points$linear_feature_id))) {
    stop("cd returned other points than it was given", call. = FALSE)
  }
  status <- ifelse(is.na(x$cell), "outside",
                   ifelse(x$cell_moved, "moved", ifelse(is.na(x$value), "no_data", "own")))
  keep <- status %in% c("own", "moved")
  data.frame(
    linear_feature_id = points$linear_feature_id,
    cell_id = ifelse(keep, wet_air_cell_id(x$cell_x, x$cell_y), NA_integer_),
    cell_x = ifelse(keep, x$cell_x, NA_real_),
    cell_y = ifelse(keep, x$cell_y, NA_real_),
    cell_status = status,
    stringsAsFactors = FALSE
  )
}
