# Hakai's package as wet reads it: the Hakai report (#192)
#
# Usage: Rscript scripts/station_sources_hakai.R
#
# On the pinned package (wet_hakai_version) and the pinned provincial snapshot
# (wet_bcenv_snapshot), under the rules registered in research/station_sources.md
# ("The Hakai package in wet"):
# - per watershed: hours read, hours dropped as SVD, the hours' code sets and
#   levels; complete days (>= 20 hours, not negative), days the 08K bound
#   drops, days kept before the provincial record begins (`continues_before`)
#   and on or after it, and the share of kept days "approved";
# - per continued provincial station, the complete Chinook-window years
#   (migration 05-01 to 08-01, spawning 08-01 to 09-15, the survey's windows,
#   inst/vignette-data/life_history_bulk.csv; wet_window_stats() means, its
#   default completeness) of the provincial record alone and with Hakai's days,
#   under the shipped rules (wet_station_daily(sources = c("bcenv", "hakai"))),
#   and whether each meets the survey's station test (>= 3 window-years outside
#   HYDAT; no HYDAT station sits at these sites);
# - the registry (inst/extdata/station_sources/hakai_<version>_hydat.csv) held
#   to the reader: `first` and `last` to the kept days before the cut,
#   `continues_before` to the first day the provincial files hold any usable
#   hour of the station. A difference fails the run (exit 1); rewrite the
#   registry with data-raw/station_sources_hakai.R.
#
# Report: data/checks/station_sources_hakai_<version>.txt (no timestamp; a rerun
# on the same package and snapshot reproduces it byte for byte).

devtools::load_all(quiet = TRUE)

version <- wet_hakai_version
snapshot <- wet_bcenv_snapshot
cache <- tools::R_user_dir("wet", "cache")
report <- file.path("data", "checks", sprintf("station_sources_hakai_%s.txt", version))
reg <- wet_hakai_stations(version)
path <- wet_hakai(version)

lh <- utils::read.csv("inst/vignette-data/life_history_bulk.csv")
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stopifnot(identical(windows$start, c("05-01", "08-01")), identical(windows$end, c("08-01", "09-15")))
min_years <- 3

# ---- the hours and days -----------------------------------------------------------------------
x <- utils::read.csv(path, colClasses = "character", na.strings = character())
x <- x[x$Watershed %in% reg$station_number, ]
h <- wet_hakai_hours(path, reg$station_number)
d <- wet_hakai_days(h)
complete <- d[d$hours >= 20 & d$q_m3s >= 0, ]
kept <- wet_hakai_shape(d)
cut <- reg$continues_before[match(kept$station_number, reg$station_number)]
before <- kept[kept$date < cut, ]

per <- lapply(reg$station_number, function(s) {
  c(station = s, continues = reg$continues[reg$station_number == s],
    hours = sum(x$Watershed == s), svd = sum(x$Watershed == s) - sum(h$station_number == s),
    days = sum(d$station_number == s), complete = sum(complete$station_number == s),
    bound = sum(complete$station_number == s) - sum(kept$station_number == s),
    before = sum(before$station_number == s), after = sum(kept$station_number == s) - sum(before$station_number == s),
    approved = sprintf("%.1f", 100 * mean(before$status[before$station_number == s] == "approved")))
})
per <- as.data.frame(do.call(rbind, per))
codes <- as.data.frame(table(station = h$station_number, codes = h$codes, level = h$level))
codes <- codes[codes$Freq > 0, ]
codes <- codes[order(codes$station, -codes$Freq, codes$codes, codes$level, method = "radix"), ]

# ---- the station test, provincial alone and with Hakai ----------------------------------------
wy <- function(q) {
  if (!nrow(q)) return(c(migration = 0L, spawning = 0L))
  ws <- wet_window_stats(q, windows, stats = "mean")
  ws <- ws[!is.na(ws$value), ]
  vapply(windows$window, function(w) length(unique(ws$year[ws$period == w])), 0L)
}
test <- lapply(reg$continues, function(p) {
  both <- suppressWarnings(wet_station_daily(p, sources = c("bcenv", "hakai"), to = NULL))
  prov <- both[both$source == "bcenv", ]
  a <- wy(prov)
  b <- wy(both)
  sprintf("    %s %4d %4d %3d -> %3d   %s -> %s   %s to %s", p, a[["migration"]], a[["spawning"]], max(a), max(b),
          max(a) >= min_years, max(b) >= min_years, format(min(both$date)), format(max(both$date)))
})

# ---- the registry held to the reader ----------------------------------------------------------
rng <- lapply(split(before$date, before$station_number), range)
pdays <- wet_bcenv_days_read(wet_bcenv_days(snapshot, cache), reg$continues)
pstart <- vapply(split(as.numeric(pdays$date), pdays$station_number), min, 0)
diffs <- character()
for (i in seq_len(nrow(reg))) {
  s <- reg$station_number[i]
  r <- rng[[s]]
  got <- c(first = if (is.null(r)) NA else format(r[1]), last = if (is.null(r)) NA else format(r[2]),
           continues_before = format(as.Date(unname(pstart[reg$continues[i]]), origin = "1970-01-01")))
  want <- c(first = format(reg$first[i]), last = format(reg$last[i]),
            continues_before = format(reg$continues_before[i]))
  bad <- names(want)[!mapply(identical, got, want)]
  for (b in bad) diffs <- c(diffs, sprintf("    %s %s: registry %s, reader %s", s, b, want[[b]], got[[b]]))
}

out <- c(
  sprintf("Hakai's package as wet reads it: the Hakai report (#192), package %s, provincial snapshot %s", version,
          snapshot),
  "Rules: research/station_sources.md, \"The Hakai package in wet\". No timestamp.",
  "",
  sprintf("The file: %s, %d bytes, md5 %s", basename(path), file.size(path), unname(tools::md5sum(path))),
  "",
  "Per watershed: station, continues, hours read, SVD hours dropped, PST days, complete days, days the bound drops,",
  "  days kept before the provincial record begins, days kept on or after it, % of kept days approved",
  sprintf("    %s %s %6s %3s %5s %5s %3s %5s %3s %5s", per$station, per$continues, per$hours, per$svd, per$days,
          per$complete, per$bound, per$before, per$after, per$approved),
  "",
  "The hours' first-tier codes and levels: station, codes, Qlevel, hours",
  sprintf("    %s %-12s %s %6d", codes$station, codes$codes, codes$level, codes$Freq),
  "",
  sprintf("The station test (>= %d complete Chinook-window years; no HYDAT station at these sites), shipped rules:",
          min_years),
  "  station, provincial migration and spawning window-years, most of either -> with Hakai, passes -> with Hakai,",
  "  first and last day with Hakai",
  unlist(test),
  "",
  if (length(diffs)) c("The registry against the reader: DIFFERS (rewrite it with data-raw/station_sources_hakai.R)",
                       diffs) else
    "The registry against the reader: first, last and continues_before equal for every watershed")
writeLines(out, report)
message("wrote ", report)
if (length(diffs)) quit(status = 1)
