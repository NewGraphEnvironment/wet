# The Chinook pilot sites (#126): one row per place in
# scripts/departure_sites.csv, read by scripts/departure_site.R,
# scripts/departure_site_snow.R and the comparison article's data scripts, so a
# stream or station swaps in by editing the table. Sourced, not run.
#
# Columns: site_id; name; wsg_code (the target's watershed group); kind,
# "extend" (a short-record gauge, extended and carried) or "ungauged" (carried
# departures only, on a published normal); target_station (HYDAT, extend only);
# blue_line_key (the target's stream); target_lon, target_lat (ungauged only:
# the stream's mouth, the downstream end of its blue line); the donor box,
# lon_min..lat_max; windows, the watershed groups whose Chinook windows the
# site runs under, space-separated, BULK first, each one an
# inst/vignette-data/life_history_<group>.csv; snow_gauges, the observed gauges
# the snow regression fits beside the target, space-separated, or empty for the
# rule in scripts/departure_site_snow.R's header; places, the named places
# its map labels (BC Geographic Names), separated by semicolons; map, the
# regional map it shares with its neighbours in the article.

site_file <- file.path("scripts", "departure_sites.csv")

# One site's row as a list, validated
site_get <- function(id, file = site_file) {
  x <- utils::read.csv(file, colClasses = "character", na.strings = character(), strip.white = FALSE)
  cols <- c("site_id", "name", "wsg_code", "kind", "target_station", "blue_line_key", "target_lon",
            "target_lat", "lon_min", "lon_max", "lat_min", "lat_max", "windows", "snow_gauges", "places", "map")
  if (!identical(names(x), cols)) stop(file, " must have the columns ", paste(cols, collapse = ", "), call. = FALSE)
  if (anyDuplicated(x$site_id)) stop(file, ": duplicate site_id", call. = FALSE)
  if (length(id) != 1 || !id %in% x$site_id) {
    stop("no site '", paste(id, collapse = " "), "' in ", file, "; sites: ", paste(x$site_id, collapse = ", "), call. = FALSE)
  }
  r <- as.list(x[x$site_id == id, ])
  for (k in c("name", "wsg_code", "kind", "blue_line_key", "lon_min", "lon_max", "lat_min", "lat_max", "windows", "map")) {
    if (!nzchar(r[[k]])) stop(id, ": ", k, " is empty", call. = FALSE)
  }
  if (!r$kind %in% c("extend", "ungauged")) stop(id, ": kind must be extend or ungauged, not ", r$kind, call. = FALSE)
  if (r$kind == "extend" && !grepl("^[0-9]{2}[A-Z]{2}[0-9]{3}$", r$target_station)) {
    stop(id, ": an extend site needs a HYDAT target_station", call. = FALSE)
  }
  if (r$kind == "ungauged" && (nzchar(r$target_station) || !nzchar(r$target_lon) || !nzchar(r$target_lat))) {
    stop(id, ": an ungauged site has no target_station and needs target_lon and target_lat", call. = FALSE)
  }
  num <- function(v) {
    out <- suppressWarnings(as.numeric(v))
    if (is.na(out)) stop(id, ": '", v, "' is not a number", call. = FALSE)
    out
  }
  r$box <- c(lon_min = num(r$lon_min), lon_max = num(r$lon_max), lat_min = num(r$lat_min), lat_max = num(r$lat_max))
  if (r$box[["lon_min"]] >= r$box[["lon_max"]] || r$box[["lat_min"]] >= r$box[["lat_max"]]) {
    stop(id, ": the box's minimum must be below its maximum", call. = FALSE)
  }
  r$blue_line_key <- as.integer(num(r$blue_line_key))
  if (r$kind == "ungauged") {
    r$target_lon <- num(r$target_lon)
    r$target_lat <- num(r$target_lat)
    site_in_box(r, r$target_lon, r$target_lat)
  }
  r$windows <- strsplit(r$windows, " ", fixed = TRUE)[[1]]
  if (!identical(r$windows[1], "BULK") || anyDuplicated(r$windows)) {
    stop(id, ": windows must start with BULK and name each group once", call. = FALSE)
  }
  r$snow_gauges <- if (nzchar(r$snow_gauges)) strsplit(r$snow_gauges, " ", fixed = TRUE)[[1]] else character()
  r$places <- if (nzchar(r$places)) strsplit(r$places, ";", fixed = TRUE)[[1]] else character()
  r[c("lon_min", "lon_max", "lat_min", "lat_max")] <- NULL
  r
}

# Refuses a target outside its own box
site_in_box <- function(site, lon, lat) {
  b <- site$box
  if (!(lon >= b[["lon_min"]] && lon <= b[["lon_max"]] && lat >= b[["lat_min"]] && lat <= b[["lat_max"]])) {
    stop(site$site_id, ": the target (", lon, ", ", lat, ") lies outside its box", call. = FALSE)
  }
  invisible(TRUE)
}

# The site's Chinook window sets: a named list, one per group in `windows`,
# each a data.frame(window, start, end) of the CH migration and spawning rows
site_windows <- function(site, dir = file.path("inst", "vignette-data")) {
  out <- lapply(site$windows, function(g) {
    f <- file.path(dir, sprintf("life_history_%s.csv", tolower(g)))
    if (!file.exists(f)) stop(site$site_id, ": no ", f, " for the ", g, " windows", call. = FALSE)
    lh <- utils::read.csv(f, stringsAsFactors = FALSE)
    lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
    if (!identical(lh$life_stage, c("migration", "spawning"))) stop(f, " must hold one CH migration and one CH spawning row", call. = FALSE)
    data.frame(window = lh$life_stage, start = lh$start, end = lh$end, source = lh$source)
  })
  names(out) <- site$windows
  out
}

# ---- parity with #120's and #121's tracked reports (#146) ---------------------------------------
#
# The pilot scripts are retired; their tracked reports are the record the
# maxan row under the BULK windows must reproduce. Each helper returns the
# tracked lines a run's output lacks (character() when it reproduces them):
# every non-blank line, trailing spaces stripped, so at the precision the
# reports print, except the lines named below, which the site report words
# differently (titles, provenance, the pilot's own naming). Each exemption
# must match exactly one tracked line, so the list cannot grow silently. The
# comparison is by set, not by order. It refuses a tracked report without
# the parts it compares rather than passing it.

site_parity_exempt <- list(
  pilot = c("^# ", "^HYDAT 20260717, ", "^Windows \\(CH, ", "^Pilot gauges, complete ",
            "^The rule: the highest median ", "^Sensitivities \\(median over gauges", "^Leave-one-year-out at ", "^USABLE ", "^## 4\\. ",
            "^08EE018 extended by ", "^90 % interval from 2000 draws ", "^\\(% normal: ",
            "^The two routes as centred departures"),
  # the cd rows name the layers' run, which a republish moves without moving a value
  snow = c("^# ", "^HYDAT 20260717\\. ", "^Pilot series: ", "^Its window statistics for ", "^Snow: wet_snow_annual",
           "^Houston \\(08EE003\\) contains ", "^Response: ", "^## 3\\. ", "^The pilot's change at ",
           "^  swe_max: https://", "^  snowmelt_doy_50: https://", "^  snowmelt_rate_peak: https://")
)

# the tracked lines the gate compares: non-blank, stripped, less each exemption (one line apiece)
site_parity_lines <- function(tracked, exempt, what) {
  x <- sub(" +$", "", tracked)
  x <- x[nzchar(x)]
  if (!any(startsWith(x, "  "))) stop("the tracked ", what, " report has no table rows", call. = FALSE)
  hit <- vapply(exempt, function(e) sum(grepl(e, x)), 0L)
  if (any(hit != 1)) {
    stop("the tracked ", what, " report: exemptions matching other than one line: ",
         paste(exempt[hit != 1], collapse = ", "), call. = FALSE)
  }
  x[!Reduce(`|`, lapply(exempt, grepl, x = x))]
}

# The pilot report (data/checks/departure_pilot_20260717.txt): section 4's
# change table, whose site rows add the carried change's % normal and interval
# in characters 83-111, is compared with those removed.
site_parity_pilot <- function(out, tracked) {
  out <- sub(" +$", "", out)
  want <- site_parity_lines(tracked, site_parity_exempt$pilot, "pilot")
  # the change table: its header, then rows to the first blank line
  table_of <- function(x, head) {
    i <- grep(head, x)
    if (length(i) != 1) return(NULL)
    end <- which(x == "" & seq_along(x) > i)[1]
    x[i:(if (is.na(end)) length(x) else end - 1)]
  }
  change <- table_of(sub(" +$", "", tracked),
                     "^  statistic window +pre post +change +% normal +90 % interval +carried +pre post$")
  if (is.null(change)) stop("the tracked pilot report has no single change table", call. = FALSE)
  site_change <- table_of(out, "^  statistic window +pre post +change +% normal +90 % interval +carried +% normal")
  site_change <- if (is.null(site_change)) character() else
    sub(" +$", "", paste0(substr(site_change, 1, 82), substring(site_change, 112)))
  c(setdiff(setdiff(want, change), out), setdiff(change, site_change))
}

# The snow report (data/checks/departure_snow_20260717.txt)
site_parity_snow <- function(out, tracked) {
  setdiff(site_parity_lines(tracked, site_parity_exempt$snow, "snow"), sub(" +$", "", out))
}
