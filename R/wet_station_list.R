#' Hydrometric stations beyond HYDAT that wet reads
#'
#' One row per station of the networks [wet_station_daily()] reads outside
#' Water Survey of Canada's HYDAT, with where each sits, the days it holds, and
#' the HYDAT station at the same site where there is one. For HYDAT's own
#' stations, use [wet_station_select()].
#'
#' The province's non-integrated hydrometric network (`"bcenv"`) is the one
#' such network so far: stations run by the province and its partners, whose
#' hourly discharge the province publishes beside HYDAT. Its list comes from a
#' pinned snapshot of those files, made with the package, so it needs no
#' download.
#'
#' A provincial station at a HYDAT site keeps its own number, and its days are
#' never joined to the HYDAT station's: `hydat_site` names that station (the
#' same stream name within 1 km) so a caller can join the two. Regulation is
#' known only where a station's name says it (a dam, diversion, intake and
#' similar); every other station is `"unknown"`, not natural.
#'
#' @param sources Which networks to list; only `"bcenv"` so far.
#' @param snapshot The provincial snapshot, as `YYYYMMDD`.
#' @return `data.frame(station_number, name, lon, lat, source, network,
#'   first, last, regulation, hydat_site, hydat_km, licence, credit)`, one row
#'   per station, ordered by number. `first` and `last` are the first and last
#'   days [wet_station_daily()] returns for the station (`NA` for one with no
#'   complete day), recorded when the snapshot was pinned and held to the
#'   reader's days by the package's harvest check whenever its rules change; `hydat_km` is the distance to `hydat_site`; `licence` and
#'   `credit` are the terms the source's data carry and the line to credit it
#'   with.
#' @examples
#' s <- wet_station_list()
#' nrow(s)
#' # provincial stations at a HYDAT station's site, carrying its record on in new years
#' head(s[!is.na(s$hydat_site), c("station_number", "name", "first", "last", "hydat_site", "hydat_km")])
#' @export
wet_station_list <- function(sources = "bcenv", snapshot = wet_bcenv_snapshot) {
  if (!is.character(sources) || !length(sources) || length(setdiff(sources, "bcenv"))) {
    stop("`sources` must be \"bcenv\", the only network listed so far", call. = FALSE)
  }
  s <- wet_bcenv_stations(snapshot)
  data.frame(station_number = s$station_number, name = s$name, lon = s$lon, lat = s$lat, source = "bcenv",
             network = "BC ENV non-integrated hydrometric network", first = s$first, last = s$last,
             regulation = s$regulation, hydat_site = s$hydat_site, hydat_km = s$hydat_km,
             licence = "OGL-BC 2.0",
             credit = "Contains information licensed under the Open Government Licence \u2013 British Columbia")
}

# The station registry of a provincial snapshot, written with the snapshot by
# data-raw/station_sources_snapshot.R and shipped with the package.
wet_bcenv_stations <- function(snapshot) {
  wet_bcenv_manifest(snapshot)  # validates the snapshot and that it is pinned
  path <- system.file("extdata", "station_sources", sprintf("bcenv_%s_hydat.csv", snapshot), package = "wet")
  if (!nzchar(path)) stop("no station registry for the provincial snapshot ", snapshot, call. = FALSE)
  s <- utils::read.csv(path, na.strings = "", encoding = "UTF-8", colClasses = c(
    station_number = "character", name = "character", lon = "numeric", lat = "numeric",
    first = "Date", last = "Date", regulation = "character", hydat_site = "character", hydat_km = "numeric"))
  if (anyDuplicated(s$station_number) || anyNA(s$station_number)) {
    stop("the station registry ", path, " does not hold one row per station", call. = FALSE)
  }
  s[order(s$station_number, method = "radix"), ]
}
