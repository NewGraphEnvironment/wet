# Data for vignettes/station-flow.Rmd (#27), which runs on these files and
# never touches HYDAT, S3 or the network at build.
#
#   Rscript data-raw/station_vignette_data.R
#
# Writes to inst/vignette-data/:
#   - station_daily.rds: wet_station_daily() for 08EE013 and 08EE003 (HYDAT,
#     then water-temp-bc provisional, then ECCC real-time), with a
#     "provenance" attribute the vignette's cached-inputs note reads.
#   - life_history_bulk.csv: the BULK rows of knowledge's
#     data/life_history_timing.csv at a pinned commit, one row per species and
#     life stage, keeping only rows with both a start and an end.
#
# HYDAT from WET_HYDAT, defaulting to data/hydat/20260717/Hydat.sqlite3 (as
# scripts/station_departure.R). knowledge is private, so its CSV is read with
# `gh api`, which needs a GitHub login with access to the repo.

devtools::load_all(quiet = TRUE)

stations <- c("08EE013", "08EE003")
hydat <- Sys.getenv("WET_HYDAT", file.path("data", "hydat", "20260717", "Hydat.sqlite3"))
knowledge_sha <- "c97c4d0e5443d4272ab9ac1a19a5cfa81135bbe0"
out_dir <- file.path("inst", "vignette-data")
fs::dir_create(out_dir)

# ---- daily series -------------------------------------------------------------
daily <- wet_station_daily(stations, hydat, to = Sys.Date() - 1)
rownames(daily) <- NULL
ranges <- do.call(rbind, lapply(split(daily, list(daily$station_number, daily$source), drop = TRUE),
                                function(d) data.frame(station_number = d$station_number[1],
                                                       source = d$source[1],
                                                       first = min(d$date), last = max(d$date),
                                                       days = nrow(d))))
rownames(ranges) <- NULL
attr(daily, "provenance") <- list(
  hydat = basename(dirname(hydat)),
  retrieved = Sys.Date(),
  knowledge_sha = knowledge_sha,
  ranges = ranges
)
saveRDS(daily, file.path(out_dir, "station_daily.rds"), compress = "xz")
print(ranges)

# ---- species windows ----------------------------------------------------------
csv <- system2("gh", c("api", "-H", shQuote("Accept: application/vnd.github.raw"),
                       sprintf("'repos/NewGraphEnvironment/knowledge/contents/data/life_history_timing.csv?ref=%s'",
                               knowledge_sha)),
               stdout = TRUE)
if (!is.null(attr(csv, "status"))) stop("gh api failed reading life_history_timing.csv")
lh <- utils::read.csv(text = csv, stringsAsFactors = FALSE, na.strings = "")
lh <- lh[lh$wsg_code == "BULK", ]

# The table has exact duplicate rows and rows missing an end; report both
# rather than pass them on.
dup <- duplicated(lh)
if (any(dup)) message("dropped duplicate rows: ",
                      paste(lh$species_code[dup], lh$life_stage[dup], collapse = ", "))
lh <- lh[!dup, ]
incomplete <- is.na(lh$start) | is.na(lh$end)
if (any(incomplete)) message("dropped rows without a start and an end: ",
                             paste(lh$species_code[incomplete], lh$life_stage[incomplete],
                                   collapse = ", "))
lh <- lh[!incomplete, ]
if (anyDuplicated(lh[c("species_code", "life_stage")])) {
  stop("two different windows for one species and life stage; resolve in knowledge first")
}
lh$wsg_code <- NULL
utils::write.csv(lh, file.path(out_dir, "life_history_bulk.csv"), row.names = FALSE, na = "")
message(nrow(lh), " species windows")

files <- list.files(out_dir, full.names = TRUE)
message("inst/vignette-data: ", round(sum(file.size(files)) / 1024), " KB")
