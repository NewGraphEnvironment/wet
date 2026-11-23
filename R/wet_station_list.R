#' Hydrometric stations beyond HYDAT that wet reads
#'
#' One row per station of the networks [wet_station_daily()] reads outside
#' Water Survey of Canada's HYDAT, with where each sits, the days it holds, and
#' the HYDAT station at the same site where there is one. For HYDAT's own
#' stations, use [wet_station_select()].
#'
#' Two such networks: the province's non-integrated hydrometric network
#' (`"bcenv"`), stations run by the province and its partners whose hourly
#' discharge the province publishes beside HYDAT, and the third-party gauges
#' the BC Water Tool serves (`"bcwatertool"`): regional districts, industry,
#' BC Hydro, the Regulator and research projects, each `network` the Tool
#' names. Both lists come from pinned snapshots made with the package, so they
#' need no download.
#'
#' A station at a HYDAT site keeps its own number, and its days are never
#' joined to the HYDAT station's: `hydat_site` names that station (the same
#' stream name within 1 km) so a caller can join the two. A Water Tool gauge at
#' a provincial station's site is not listed: its days before the provincial
#' record begins continue that station's record under the provincial number
#' (see [wet_station_daily()]), and the provincial row's `first`, `licence` and
#' `credit` say so when both sources are listed. Regulation is known only where
#' a station's name says it (a dam, diversion, intake and similar); every other
#' station is `"unknown"`, not natural, and none is a donor until it is known.
#'
#' @param sources Which networks to list, from `"bcenv"` and `"bcwatertool"`.
#' @param snapshot The provincial snapshot, as `YYYYMMDD`. The Water Tool's is
#'   the one the package pins.
#' @return `data.frame(station_number, name, lon, lat, source, network,
#'   first, last, regulation, hydat_site, hydat_km, licence, credit)`, one row
#'   per station, ordered by source and number. `first` and `last` are the
#'   first and last days [wet_station_daily()] returns for the station (`NA`
#'   for one with no complete day), recorded when the snapshot was pinned and
#'   held to the reader's days by the package's harvest check whenever its
#'   rules change; `hydat_km` is the distance to `hydat_site`; `licence` and
#'   `credit` are the terms the source's data carry and the line to credit it
#'   with (a Water Tool file states no licence, so its `licence` is `NA`, and
#'   its `credit` is its file's own statement, its liability disclaimer left
#'   out).
#' @examples
#' s <- wet_station_list()
#' table(s$source)
#' # stations at a HYDAT station's site, carrying its record on in new years
#' head(s[!is.na(s$hydat_site), c("station_number", "name", "first", "last", "hydat_site", "hydat_km")])
#' # the Water Tool's networks
#' table(s$network[s$source == "bcwatertool"])
#' @export
wet_station_list <- function(sources = c("bcenv", "bcwatertool"), snapshot = wet_bcenv_snapshot) {
  if (!is.character(sources) || !length(sources) || anyNA(sources) ||
      length(setdiff(sources, c("bcenv", "bcwatertool")))) {
    stop("`sources` must be some of \"bcenv\" and \"bcwatertool\"", call. = FALSE)
  }
  out <- list()
  prov <- wet_bcenv_stations(snapshot)
  tool <- if ("bcwatertool" %in% sources) wet_bcwatertool_stations()
  if (!is.null(tool)) wet_registry_check(tool, prov, snapshot)
  if ("bcenv" %in% sources) {
    p <- data.frame(station_number = prov$station_number, name = prov$name, lon = prov$lon, lat = prov$lat,
                    source = "bcenv", network = "BC ENV non-integrated hydrometric network", first = prov$first,
                    last = prov$last, regulation = prov$regulation, hydat_site = prov$hydat_site,
                    hydat_km = prov$hydat_km, licence = "OGL-BC 2.0",
                    credit = "Contains information licensed under the Open Government Licence \u2013 British Columbia")
    if (!is.null(tool)) {
      cont <- tool[!is.na(tool$continues), ]
      i <- match(cont$continues, p$station_number)
      # a continuing listing's first and last are the days it adds, all before the provincial record
      # begins (continues_before); NA where it adds none
      added <- !is.na(i) & !is.na(cont$first)
      cont <- cont[added, ]
      i <- i[added]
      before <- ifelse(is.na(cont$continues_before), "all days",
                       paste("days before", format(cont$continues_before)))
      p$licence[i] <- paste0(p$licence[i], "; ", before, ": none stated")
      p$credit[i] <- paste0(p$credit[i], "; ", before, ": ", cont$credit)
      p$first[i] <- cont$first
      none <- is.na(p$last[i])  # a provincial station with no complete day: its days are the listing's
      p$last[i[none]] <- cont$last[none]
    }
    out$bcenv <- p
  }
  # data.frame() cannot recycle the scalar source onto zero rows
  if (!is.null(tool) && any(is.na(tool$continues))) {
    t <- tool[is.na(tool$continues), ]
    out$bcwatertool <- data.frame(station_number = t$station_number, name = t$name, lon = t$lon, lat = t$lat,
                                  source = "bcwatertool", network = t$network, first = t$first, last = t$last,
                                  regulation = t$regulation, hydat_site = t$hydat_site, hydat_km = t$hydat_km,
                                  licence = NA_character_, credit = t$credit)
  }
  out <- do.call(rbind, unname(out))
  rownames(out) <- NULL
  out
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
