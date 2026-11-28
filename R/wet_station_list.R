#' Hydrometric stations beyond HYDAT that wet reads
#'
#' One row per station of the networks [wet_station_daily()] reads outside
#' Water Survey of Canada's HYDAT, with where each sits, the days it holds, and
#' the HYDAT station at the same site where there is one. For HYDAT's own
#' stations, use [wet_station_select()].
#'
#' Three such sources: the province's non-integrated hydrometric network
#' (`"bcenv"`), stations run by the province and its partners whose hourly
#' discharge the province publishes beside HYDAT; the third-party gauges the
#' BC Water Tool serves (`"bcwatertool"`): regional districts, industry, BC
#' Hydro, the Regulator and research projects, each `network` the Tool names;
#' and Hakai Institute's published package (`"hakai"`) for seven small Calvert
#' and Hecate island watersheds, 2013-2019. All three lists come from pinned
#' copies made with the package, so they need no download.
#'
#' A station at a HYDAT site keeps its own number, and its days are never
#' joined to the HYDAT station's: `hydat_site` names that station (the same
#' stream name within 1 km) so a caller can join the two. A Water Tool gauge at
#' a provincial station's site is not listed: its days before the provincial
#' record begins continue that station's record under the provincial number
#' (see [wet_station_daily()]), and the provincial row's `first`, `licence` and
#' `credit` say so when both sources are listed. Three of Hakai's watersheds
#' continue provincial stations the same way; its other four are stations of
#' their own, listed under the package's numbers (`"WTS693"`, ...).
#'
#' `regulation` is each station's status from what sits upstream of it, one
#' for the year as a whole, under a rule registered before it was applied:
#' `"regulated"` where the name says so (a dam, diversion, intake and
#' similar), an active dam in the provincial register's regulated classes
#' sits upstream, or licensed consumptive use or licensed storage upstream is
#' at least 10 % of the segment's published mean annual flow;
#' `"unknown"` where the station could not be placed on the Freshwater Atlas
#' stream its name or drainage area gives, part of its basin lies outside BC,
#' a power licence or a licence that states no volume draws upstream, or its
#' segment has no published flow; and
#' `"natural"` otherwise. No natural station holds the 10 years of 1981–2010
#' record a baseline needs, and on a baseline estimated from HYDAT gauges they made departures
#' carried from donors worse at held-out HYDAT gauges, so they serve as records
#' and held-out tests, not donors. The status, its reasons and the shares are in
#' the package's `extdata/station_sources/regulation_<snapshot>.csv`. They
#' use BC's dam register (contains information licensed under the Open
#' Government Licence - British Columbia) and are computed from the
#' Province of British Columbia's water rights licences, whose terms are
#' "Access Only": no licence record is reproduced.
#'
#' @param sources Which networks to list, from `"bcenv"`, `"bcwatertool"` and
#'   `"hakai"`. `"hakai"` lists Hakai's own stations, and changes the
#'   provincial stations it continues when `"bcenv"` is listed too.
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
wet_station_list <- function(sources = c("bcenv", "bcwatertool", "hakai"), snapshot = wet_bcenv_snapshot) {
  known <- c("bcenv", "bcwatertool", "hakai")
  if (!is.character(sources) || !length(sources) || anyNA(sources) || length(setdiff(sources, known))) {
    stop("`sources` must be some of \"bcenv\", \"bcwatertool\" and \"hakai\"", call. = FALSE)
  }
  out <- list()
  prov <- wet_bcenv_stations(snapshot)
  tool <- if ("bcwatertool" %in% sources) wet_bcwatertool_against(wet_bcwatertool_stations(), snapshot)
  hakai <- if ("hakai" %in% sources) {
    wet_registry_against(wet_hakai_stations(), snapshot, "Hakai", "data-raw/station_sources_hakai.R")
  }
  if (!is.null(tool) || !is.null(hakai)) wet_registry_check(tool, prov, snapshot, hakai = hakai)
  status <- wet_station_regulation(snapshot)
  if ("bcenv" %in% sources) {
    p <- data.frame(station_number = prov$station_number, name = prov$name, lon = prov$lon, lat = prov$lat,
                    source = "bcenv", network = "BC ENV non-integrated hydrometric network", first = prov$first,
                    last = prov$last, regulation = wet_regulation_of(status, prov$station_number, "bcenv"),
                    hydat_site = prov$hydat_site,
                    hydat_km = prov$hydat_km, licence = "OGL-BC 2.0",
                    credit = "Contains information licensed under the Open Government Licence \u2013 British Columbia")
    if (!is.null(tool)) p <- wet_continue_list(p, tool, "none stated")
    if (!is.null(hakai)) p <- wet_continue_list(p, hakai, hakai$licence)
    out$bcenv <- p
  }
  # data.frame() cannot recycle the scalar source onto zero rows
  if (!is.null(tool) && any(is.na(tool$continues))) {
    t <- tool[is.na(tool$continues), ]
    out$bcwatertool <- data.frame(station_number = t$station_number, name = t$name, lon = t$lon, lat = t$lat,
                                  source = "bcwatertool", network = t$network, first = t$first, last = t$last,
                                  regulation = wet_regulation_of(status, t$station_number, "bcwatertool"),
                                  hydat_site = t$hydat_site, hydat_km = t$hydat_km,
                                  licence = NA_character_, credit = t$credit)
  }
  if (!is.null(hakai) && any(is.na(hakai$continues))) {
    k <- hakai[is.na(hakai$continues), ]
    out$hakai <- data.frame(station_number = k$station_number, name = k$name, lon = k$lon, lat = k$lat,
                            source = "hakai", network = "Hakai Institute", first = k$first, last = k$last,
                            regulation = wet_regulation_of(status, k$station_number, "hakai"),
                            hydat_site = NA_character_, hydat_km = NA_real_, licence = k$licence, credit = k$credit)
  }
  out <- do.call(rbind, c(list(wet_station_list_empty()), unname(out)))
  rownames(out) <- NULL
  out
}

wet_station_list_empty <- function() {
  data.frame(station_number = character(), name = character(), lon = numeric(), lat = numeric(),
             source = character(), network = character(), first = as.Date(character()), last = as.Date(character()),
             regulation = character(), hydat_site = character(), hydat_km = numeric(), licence = character(),
             credit = character())
}

# Provincial rows `p` with the first and last days, licence and credit of each
# continuing row of registry `reg` (station_number, continues,
# continues_before, first, last, credit) spliced in: a continuing row's first
# and last are the days it adds, all before the provincial record begins; a
# row that adds none changes nothing. `licence` is what the publisher's data
# state, one for all rows or one per row of `reg`.
wet_continue_list <- function(p, reg, licence) {
  licence <- rep_len(licence, nrow(reg))
  keep <- !is.na(reg$continues)
  cont <- reg[keep, ]
  licence <- licence[keep]
  i <- match(cont$continues, p$station_number)
  added <- !is.na(i) & !is.na(cont$first)
  cont <- cont[added, ]
  licence <- licence[added]
  i <- i[added]
  before <- ifelse(is.na(cont$continues_before), "all days", paste("days before", format(cont$continues_before)))
  p$licence[i] <- paste0(p$licence[i], "; ", before, ": ", licence)
  p$credit[i] <- paste0(p$credit[i], "; ", before, ": ", cont$credit)
  p$first[i] <- cont$first
  none <- is.na(p$last[i])  # a provincial station with no complete day: its days are the listing's
  p$last[i[none]] <- cont$last[none]
  p
}

# Each station's regulation status, written by scripts/station_regulation.R
# for a provincial snapshot and shipped with the package (#196):
# data.frame(station_number, source, regulation, why, ...), one row per station
# of the three registries (a continuing row counted as the station it
# continues). Refused unless it was built from the registries shipped beside it
# (their snapshots or version and md5s) and every status is in the vocabulary.
wet_station_regulation <- function(snapshot) {
  path <- wet_station_sources_path(sprintf("regulation_%s.csv", snapshot))
  if (!nzchar(path)) {
    stop("no regulation status for the provincial snapshot ", snapshot,
         "; write it with scripts/station_regulation.R", call. = FALSE)
  }
  r <- utils::read.csv(path, na.strings = "", encoding = "UTF-8", colClasses = "character")
  reg <- c(bcenv = sprintf("bcenv_%s_hydat.csv", snapshot),
           bcwatertool = sprintf("bcwatertool_%s_hydat.csv", wet_bcwatertool_snapshot),
           hakai = sprintf("hakai_%s_hydat.csv", wet_hakai_version))
  md5 <- vapply(reg, function(f) {
    p <- wet_station_sources_path(f)
    if (nzchar(p)) unname(tools::md5sum(p)) else NA_character_
  }, "")
  built <- c(unique(r$bcenv_snapshot), unique(r$bcwatertool_snapshot), unique(r$hakai_version),
             unique(r$bcenv_registry_md5), unique(r$bcwatertool_registry_md5), unique(r$hakai_registry_md5))
  if (!identical(built, c(snapshot, wet_bcwatertool_snapshot, wet_hakai_version, unname(md5)))) {
    stop("the regulation status ", path, " was built from other station registries than those shipped beside it",
         "; rewrite it with scripts/station_regulation.R", call. = FALSE)
  }
  if (anyNA(r$station_number) || anyDuplicated(r$station_number) || !all(r$regulation %in% wet_regulation_vocab)) {
    stop("the regulation status ", path, " does not hold one row per station, each natural, regulated or unknown",
         call. = FALSE)
  }
  r
}

wet_regulation_vocab <- c("natural", "regulated", "unknown")

# A file shipped under extdata/station_sources/, "" when there is none.
wet_station_sources_path <- function(f) system.file("extdata", "station_sources", f, package = "wet")

# The status of each of `numbers` from `source`, refused unless the status file
# holds every one of them under that source.
wet_regulation_of <- function(status, numbers, source) {
  i <- match(numbers, status$station_number)
  miss <- numbers[is.na(i) | status$source[i] != source]
  if (length(miss)) {
    stop("the regulation status has no ", source, " row for ", paste(utils::head(miss, 5), collapse = ", "),
         if (length(miss) > 5) sprintf(" and %d more", length(miss) - 5),
         "; rewrite it with scripts/station_regulation.R", call. = FALSE)
  }
  status$regulation[i]
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
