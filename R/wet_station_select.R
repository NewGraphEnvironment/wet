#' Natural-flow HYDAT stations with a usable record in a period
#'
#' Selects stations whose HYDAT regulation flag is `0` (stations with no
#' regulation record are treated as unknown and left out) and which have at
#' least `min_years` complete years inside `years`. A complete year has all 12
#' months, each with at least `min_days` days of daily flow. Seasonal gauges
#' therefore never qualify.
#'
#' @param hydat Path to the HYDAT sqlite database. Defaults to tidyhydat's
#'   download location.
#' @param years Integer vector of calendar years.
#' @param min_years Minimum number of complete years.
#' @param min_days Minimum days of flow for a month to count as complete.
#' @param prov Province or territory codes (`PROV_TERR_STATE_LOC`).
#' @return `data.frame(station_number, station_name, prov, lon, lat,
#'   drainage_area_gross_km2, n_years)`, one row per qualifying station, with
#'   the complete years as attribute `"years"` (a named list by station).
#' @export
wet_station_select <- function(hydat = wet_hydat_path(), years = 1981:2010, min_years = 10,
                               min_days = 20, prov = "BC") {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  st <- DBI::dbGetQuery(con, sprintf("
    SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name,
           s.PROV_TERR_STATE_LOC prov, s.LONGITUDE lon, s.LATITUDE lat,
           s.DRAINAGE_AREA_GROSS drainage_area_gross_km2
    FROM STATIONS s JOIN STN_REGULATION r USING (STATION_NUMBER)
    WHERE r.REGULATED = 0 AND s.PROV_TERR_STATE_LOC IN (%s)",
    paste(DBI::dbQuoteString(con, prov), collapse = ", ")))
  if (!nrow(st)) return(wet_station_empty())
  cy <- wet_complete_years(con, st$station_number, years, min_days)
  n <- vapply(split(cy$year, factor(cy$station_number, levels = st$station_number)), length, 1L)
  st$n_years <- unname(n[st$station_number])
  st <- st[st$n_years >= min_years, ]
  st <- st[order(st$station_number), ]
  rownames(st) <- NULL
  attr(st, "years") <- split(cy$year, cy$station_number)[st$station_number]
  st
}

# Years in which all 12 months have at least min_days days of daily flow.
wet_complete_years <- function(con, stations, years, min_days) {
  if (!length(stations)) return(data.frame(station_number = character(), year = integer()))
  days <- paste(sprintf("(FLOW%d IS NOT NULL)", 1:31), collapse = " + ")
  q <- sprintf("
    SELECT STATION_NUMBER station_number, YEAR year
    FROM (SELECT STATION_NUMBER, YEAR, MONTH, %s AS n FROM DLY_FLOWS
          WHERE YEAR BETWEEN %d AND %d AND STATION_NUMBER IN (%s))
    WHERE n >= %d
    GROUP BY STATION_NUMBER, YEAR
    HAVING COUNT(DISTINCT MONTH) = 12",
    days, min(years), max(years), paste(DBI::dbQuoteString(con, stations), collapse = ", "),
    as.integer(min_days))
  out <- DBI::dbGetQuery(con, q)
  out[out$year %in% years, ]
}

wet_hydat_path <- function() {
  if (!requireNamespace("tidyhydat", quietly = TRUE)) {
    stop("pass `hydat`, or install tidyhydat for its default path", call. = FALSE)
  }
  file.path(tidyhydat::hy_dir(), "Hydat.sqlite3")
}

# The release a HYDAT file holds, as YYYYMMDD from its VERSION table: what names
# a water-balance fit (#43), so two releases never share one set of outputs.
wet_hydat_release <- function(hydat) {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  if (!DBI::dbExistsTable(con, "VERSION")) stop("no VERSION table in ", hydat, call. = FALSE)
  d <- DBI::dbGetQuery(con, "SELECT Date FROM VERSION")$Date
  rel <- format(as.Date(substr(as.character(d), 1, 10)), "%Y%m%d")
  if (length(rel) != 1 || is.na(rel)) stop("expected one release date in ", hydat, "'s VERSION table", call. = FALSE)
  rel
}

# Read-only: connecting to a missing sqlite path would create an empty database.
wet_hydat_connect <- function(hydat) {
  if (!file.exists(hydat)) stop("HYDAT not found at ", hydat, call. = FALSE)
  DBI::dbConnect(RSQLite::SQLite(), hydat, flags = RSQLite::SQLITE_RO)
}

wet_station_empty <- function() {
  out <- data.frame(station_number = character(), station_name = character(),
                    prov = character(), lon = numeric(), lat = numeric(),
                    drainage_area_gross_km2 = numeric(), n_years = integer())
  attr(out, "years") <- list()
  out
}
