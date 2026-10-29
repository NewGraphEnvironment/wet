# Species windows for other watershed groups than the Bulkley, for the Chinook
# pilot sites (#126; scripts/departure_sites.csv names which groups' windows
# each site runs under).
#
#   Rscript data-raw/life_history_data.R
#
# Writes inst/vignette-data/life_history_<group>.csv for each group below: the
# group's rows of knowledge's data/life_history_timing.csv at a pinned commit,
# one row per species and life stage, keeping only rows with both a start and
# an end, in life_history_bulk.csv's columns (data-raw/station_vignette_data.R
# writes that one and is not touched here). knowledge is private, so its CSV
# is read with `gh api`, which needs a GitHub login with access to the repo.
#
# MORR: Bustard and Schell (2002) for the Chinook windows (migration
# 05-01..09-30, spawning 09-01..10-07), asserted below.

groups <- "MORR"
knowledge_sha <- "c97c4d0e5443d4272ab9ac1a19a5cfa81135bbe0"   # as data-raw/station_vignette_data.R
out_dir <- file.path("inst", "vignette-data")

csv <- system2("gh", c("api", "-H", shQuote("Accept: application/vnd.github.raw"),
                       sprintf("repos/NewGraphEnvironment/knowledge/contents/data/life_history_timing.csv?ref=%s",
                               knowledge_sha)),
               stdout = TRUE)
if (!is.null(attr(csv, "status"))) stop("gh api failed reading life_history_timing.csv")
all_lh <- utils::read.csv(text = csv, stringsAsFactors = FALSE, na.strings = "")

for (g in groups) {
  lh <- all_lh[all_lh$wsg_code == g, ]
  if (!nrow(lh)) stop("knowledge holds no rows for ", g)
  dup <- duplicated(lh)
  if (any(dup)) message(g, ": dropped duplicate rows: ", paste(lh$species_code[dup], lh$life_stage[dup], collapse = ", "))
  lh <- lh[!dup, ]
  incomplete <- is.na(lh$start) | is.na(lh$end)
  if (any(incomplete)) message(g, ": dropped rows without a start and an end: ",
                               paste(lh$species_code[incomplete], lh$life_stage[incomplete], collapse = ", "))
  lh <- lh[!incomplete, ]
  if (anyDuplicated(lh[c("species_code", "life_stage")])) {
    stop(g, ": two different windows for one species and life stage; resolve in knowledge first")
  }
  lh$wsg_code <- NULL
  ch <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
  if (g == "MORR") {
    stopifnot(identical(ch$start, c("05-01", "09-01")), identical(ch$end, c("09-30", "10-07")),
              all(ch$source == "bustard_schell2002ConservingMorice"))
  }
  f <- file.path(out_dir, sprintf("life_history_%s.csv", tolower(g)))
  utils::write.csv(lh, f, row.names = FALSE, na = "")
  message(f, ": ", nrow(lh), " species windows")
}
