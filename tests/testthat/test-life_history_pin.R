# data-raw/life_history_data.R reads knowledge's life history table at a newer
# commit than data-raw/station_vignette_data.R (#187), and lh_pin_guard() stops
# unless the move leaves every Bulkley and Morice window where it was. The
# guard is handed tables built from the committed CSVs, then copies with one
# value moved. data-raw/ is not in the installed package, so these run under
# devtools::test() only.

lh_lib <- function() {
  f <- testthat::test_path("..", "..", "data-raw", "life_history_data.R")
  testthat::skip_if_not(file.exists(f), "data-raw/ is not in the installed package")
  e <- new.env()
  sys.source(f, envir = e)
  e
}

lh_csv <- function(g) {
  f <- testthat::test_path("..", "..", "inst", "vignette-data", sprintf("life_history_%s.csv", g))
  testthat::skip_if_not(file.exists(f), "the life history CSVs are not in the source tree")
  utils::read.csv(f, stringsAsFactors = FALSE, na.strings = "", colClasses = "character")
}

lh_table <- function() {
  rbind(cbind(wsg_code = "BULK", lh_csv("bulk")), cbind(wsg_code = "MORR", lh_csv("morr")))
}

test_that("the guard passes tables that agree", {
  e <- lh_lib()
  expect_true(e$lh_pin_guard(lh_table(), lh_table(), lh_csv("bulk")))
})

test_that("the guard passes a BULK note that moved, as knowledge's coho note did", {
  e <- lh_lib()
  new <- lh_table()
  new$note[new$wsg_code == "BULK"][1] <- "a rewritten note"
  bulk <- lh_csv("bulk")
  bulk$note[1] <- "a rewritten note"
  expect_true(e$lh_pin_guard(new, lh_table(), bulk))
})

test_that("the guard stops on a MORR window or note that moved", {
  e <- lh_lib()
  new <- lh_table()
  i <- which(new$wsg_code == "MORR" & new$species_code == "CH" & new$life_stage == "spawning")
  new$start[i] <- "09-02"
  expect_error(e$lh_pin_guard(new, lh_table(), lh_csv("bulk")), "MORR's rows differ")
  new <- lh_table()
  new$note[i] <- "a note life_history_morr.csv would write"
  expect_error(e$lh_pin_guard(new, lh_table(), lh_csv("bulk")), "MORR's rows differ")
})

test_that("the guard stops on a BULK window that moved", {
  e <- lh_lib()
  new <- lh_table()
  i <- which(new$wsg_code == "BULK" & new$species_code == "CO" & new$life_stage == "spawning")
  expect_length(i, 1)
  new$end[i] <- "12-31"
  expect_error(e$lh_pin_guard(new, lh_table(), lh_csv("bulk")), "BULK's rows differ")
})

test_that("the guard stops when the pinned chinook rows are not life_history_bulk.csv's", {
  e <- lh_lib()
  bulk <- lh_csv("bulk")
  bulk$source[bulk$species_code == "CH" & bulk$life_stage == "migration"] <- "another_source"
  expect_error(e$lh_pin_guard(lh_table(), lh_table(), bulk), "differ from life_history_bulk.csv")
  bulk <- lh_csv("bulk")
  bulk$note[bulk$species_code == "CH" & bulk$life_stage == "migration"] <- "another note"
  expect_error(e$lh_pin_guard(lh_table(), lh_table(), bulk), "differ from life_history_bulk.csv")
})

test_that("the committed UFRA and COTR CSVs carry the asserted chinook rows", {
  e <- lh_lib()
  for (g in c("UFRA", "COTR")) {
    x <- lh_csv(tolower(g))
    ch <- x[x$species_code == "CH" & x$life_stage %in% c("migration", "spawning"), ]
    want <- e$lh_chinook[[g]]
    expect_identical(ch$life_stage, want$life_stage)
    expect_identical(ch$start, want$start)
    expect_identical(ch$end, want$end)
    expect_identical(ch$source, want$source)
  }
})
