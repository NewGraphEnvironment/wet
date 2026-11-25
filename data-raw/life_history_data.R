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
# Chinook windows, asserted below row by row with their exact sources:
# - MORR: Bustard and Schell (2002) (migration 05-01..09-30, spawning
#   09-01..10-07).
# - UFRA: migration 04-01..08-10 (Bradford and Taylor 2023, citing COSEWIC
#   2018, for Fraser entry from April; NuSEDS), spawning 08-11..09-05
#   (NuSEDS median start and end of spawning; Candy et al. 2002).
# - COTR: migration 04-01..08-09 (Candy et al. 2002; NuSEDS), spawning
#   08-10..09-06 (NuSEDS; Candy et al. 2002).
# The UFRA and COTR spawning edges are medians of NuSEDS start and end dates,
# which are estimates rather than the first and last spawners seen; knowledge's
# notes on those rows say so (knowledge#256).
#
# Pin: knowledge_sha is the commit that last touched the table (#187); it holds
# the UFRA and COTR rows. data-raw/station_vignette_data.R pins the older
# c97c4d0 for BULK. lh_pin_guard() reads the table at that commit too and stops
# unless MORR's rows are unchanged in every column (life_history_morr.csv
# writes them all), BULK's in every column but `note`, and BULK's chinook
# migration and spawning rows equal life_history_bulk.csv's, so the move cannot
# shift a window the Bulkley or Morice readers use. When this file is
# sys.source()d (tests/testthat/test-life_history_pin.R), only the functions
# are defined.

lh_read <- function(sha) {
  csv <- system2("gh", c("api", "-H", shQuote("Accept: application/vnd.github.raw"),
                         sprintf("repos/NewGraphEnvironment/knowledge/contents/data/life_history_timing.csv?ref=%s",
                                 sha)),
                 stdout = TRUE)
  if (!is.null(attr(csv, "status"))) stop("gh api failed reading life_history_timing.csv at ", sha)
  utils::read.csv(text = csv, stringsAsFactors = FALSE, na.strings = "")
}

# `new` and `old`: the knowledge table at the pin and at station_vignette_data.R's
# pin; `bulk`: life_history_bulk.csv as read. Stops on any difference that moves
# a Bulkley or Morice window; returns TRUE otherwise.
lh_pin_guard <- function(new, old, bulk) {
  rows <- function(x, g, cols = names(x)) {
    x <- x[x$wsg_code == g, cols, drop = FALSE]
    rownames(x) <- NULL
    x
  }
  if (!nrow(rows(old, "MORR")) || !nrow(rows(old, "BULK"))) stop("the older table holds no MORR or BULK rows")
  if (!identical(rows(new, "MORR"), rows(old, "MORR"))) {
    stop("MORR's rows differ between the two knowledge commits; life_history_morr.csv would move")
  }
  keep <- setdiff(names(old), "note")
  if (!identical(rows(new, "BULK", keep), rows(old, "BULK", keep))) {
    stop("BULK's rows differ between the two knowledge commits in a column other than note")
  }
  ch <- function(x) {
    x <- x[x$species_code == "CH" & x$life_stage %in% c("migration", "spawning"),
           c("species_code", "life_stage", "start", "end", "source", "note"), drop = FALSE]
    rownames(x) <- NULL
    x
  }
  if (!identical(ch(rows(new, "BULK")), ch(bulk))) {
    stop("BULK's chinook migration and spawning rows at the pin differ from life_history_bulk.csv's")
  }
  TRUE
}

# each group's chinook migration and spawning rows: start, end and exact source
lh_chinook <- list(
  MORR = data.frame(life_stage = c("migration", "spawning"), start = c("05-01", "09-01"), end = c("09-30", "10-07"),
                    source = "bustard_schell2002ConservingMorice"),
  UFRA = data.frame(life_stage = c("migration", "spawning"), start = c("04-01", "08-11"), end = c("08-10", "09-05"),
                    source = c(paste("bradford_taylor2023Diversityfreshwater", "cosewic2018COSEWICAssessment",
                                     "fisheriesandoceanscanadaNuSEDSNewSalmon", sep = "; "),
                               "fisheriesandoceanscanadaNuSEDSNewSalmon; candy_etal2002discussionpaper")),
  COTR = data.frame(life_stage = c("migration", "spawning"), start = c("04-01", "08-10"), end = c("08-09", "09-06"),
                    source = c("candy_etal2002discussionpaper; fisheriesandoceanscanadaNuSEDSNewSalmon",
                               "fisheriesandoceanscanadaNuSEDSNewSalmon; candy_etal2002discussionpaper"))
)

if (sys.nframe() == 0L) {
  groups <- c("MORR", "UFRA", "COTR")
  knowledge_sha <- "a475dfe7b6d8923bdcfd67506f9f1c5573ffcde7"
  bulk_sha <- "c97c4d0e5443d4272ab9ac1a19a5cfa81135bbe0"   # data-raw/station_vignette_data.R's pin
  out_dir <- file.path("inst", "vignette-data")

  all_lh <- lh_read(knowledge_sha)
  lh_pin_guard(all_lh, lh_read(bulk_sha),
               utils::read.csv(file.path(out_dir, "life_history_bulk.csv"), stringsAsFactors = FALSE,
                               na.strings = "", colClasses = "character"))

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
    want <- lh_chinook[[g]]
    stopifnot(identical(ch$life_stage, want$life_stage), identical(ch$start, want$start),
              identical(ch$end, want$end), identical(ch$source, want$source))
    f <- file.path(out_dir, sprintf("life_history_%s.csv", tolower(g)))
    utils::write.csv(lh, f, row.names = FALSE, na = "")
    message(f, ": ", nrow(lh), " species windows")
  }
}
