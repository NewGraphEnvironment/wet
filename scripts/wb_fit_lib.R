# Where a water-balance fit lives, and which one ships (#43). Sourced by the
# wb_* scripts after devtools::load_all(); not run on its own.
#
# A fit is the province run (data/wb/<key>/, keyed on the input rasters and
# their code, scripts/wb_province.R) plus one HYDAT release: the stations
# snapped from that release, and the scores, fits and output made from them.
# Each release has its own stations file and fit directory, so a newer HYDAT
# never overwrites the fit an older one produced.
#
# Not in scripts/wb_score_md5.R's score_files on purpose: this file says where a
# fit is and which one ships, not how a fit is scored, so switching the shipped
# release does not stale every fit's scores.

# the fit the province output, the map and the vignette use: HYDAT 2026-07-17
# since #43 (data/checks/wb_fit_accept_20260717.txt; the gate dropped the zone
# adjustment, and the user chose to ship it raw, 2026-10-06)
wb_shipped_release <- "20260717"

# the release a script works on: WET_HYDAT_RELEASE, or the shipped one
wb_release <- function() {
  r <- Sys.getenv("WET_HYDAT_RELEASE", wb_shipped_release)
  if (!grepl("^[0-9]{8}$", r)) stop("WET_HYDAT_RELEASE must be YYYYMMDD, not ", r, call. = FALSE)
  r
}

# The HYDAT file to read, which must hold the release being worked on. There
# is no default: tidyhydat's default directory holds whatever release was
# last downloaded on that machine, which is how a fit would change silently.
wb_hydat <- function(release) {
  f <- Sys.getenv("WET_HYDAT")
  if (!nzchar(f)) stop("set WET_HYDAT to the Hydat.sqlite3 of release ", release, call. = FALSE)
  got <- wet:::wet_hydat_release(f)
  if (!identical(got, release)) stop(f, " holds HYDAT ", got, ", not ", release, call. = FALSE)
  f
}

# the one complete province run under data/wb
wb_key_dir <- function() {
  keys <- list.dirs("data/wb", recursive = FALSE, full.names = TRUE)
  keys <- keys[file.exists(file.path(keys, "upstream", "_complete"))]
  if (length(keys) != 1) stop("expected one complete province run under data/wb, found ", length(keys), call. = FALSE)
  keys
}

wb_stations_path <- function(release) file.path("data", "wb", sprintf("stations_%s.rds", release))
wb_fit_dir <- function(key_dir, release) file.path(key_dir, paste0("fit_", release))

# Tracked reports. The 2025-10-14 fit keeps the names it was published and
# cited under (research/, CLAUDE.md); a later fit's reports carry its release.
wb_report <- function(stem, release) {
  file.path("data", "checks", paste0(stem, if (release == "20251014") "" else paste0("_", release), ".txt"))
}
