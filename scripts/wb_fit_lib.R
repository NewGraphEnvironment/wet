# Where a water-balance fit lives, and which one ships (#43), and the HYDAT
# release a script reads (#46). Sourced after devtools::load_all() by the wb_*
# scripts, and by the station-flow scripts and mad_basin.R for wb_hydat(); not
# run on its own.
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
# since #43 (data/checks/wb_fit_accept_20260717.txt). Its headwater gate is a
# 0.03-point tie, kept by a recorded override (<fit>/adjust_override.txt,
# scripts/wb_validate.R), the user's decision of 2026-10-06
wb_shipped_release <- "20260717"

# the release a script works on: WET_HYDAT_RELEASE, or the shipped one
wb_release <- function() {
  r <- Sys.getenv("WET_HYDAT_RELEASE", wb_shipped_release)
  if (!grepl("^[0-9]{8}$", r)) stop("WET_HYDAT_RELEASE must be YYYYMMDD, not ", r, call. = FALSE)
  r
}

# The HYDAT file of the release being worked on, from wet's per-user cache
# (wet_hydat(), #46), never tidyhydat's default directory, which holds whatever
# release was last downloaded on that machine. WET_HYDAT, the path these
# scripts read before #46, is refused rather than ignored, so an old run line
# cannot read one release while believing it reads another.
wb_hydat <- function(release) {
  if (nzchar(Sys.getenv("WET_HYDAT"))) {
    stop("WET_HYDAT is retired (#46): name the release with WET_HYDAT_RELEASE, and put a copy of it in ",
         file.path(tools::R_user_dir("wet", "cache"), "hydat", release), call. = FALSE)
  }
  wet:::wet_hydat(release)
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
