# The one list of files the publish code's two guards exclude (#171):
# scripts/discharge_publish.R (the BUILD) and scripts/segment_daily_output.R
# source it rather than each holding a copy. scripts/ is not shipped to
# R CMD check, so these run under devtools::test() only.

scripts_dir <- function() {
  d <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(d), "scripts/ is not in the installed package")
  d
}

test_that("both guards source the one list and assign none of their own", {
  d <- scripts_dir()
  for (f in c("discharge_publish.R", "segment_daily_output.R")) {
    lines <- readLines(file.path(d, f))
    expect_true(any(grepl('source("scripts/discharge_publish_own.R")', lines, fixed = TRUE)), info = f)
    expect_false(any(grepl("^publish_own <-", lines)), info = f)
  }
  # the daily script adds only itself to the shared list
  daily <- readLines(file.path(d, "segment_daily_output.R"))
  expect_true('own <- c("scripts/segment_daily_output.R", publish_own)' %in% daily)
  # and the BUILD keeps the daily script out of the list, so its daily check still sees it
  build <- readLines(file.path(d, "discharge_publish.R"))
  expect_true('daily_own <- "scripts/segment_daily_output.R"' %in% build)
})

test_that("the list names itself, the readers, and only files that exist", {
  d <- scripts_dir()
  e <- new.env()
  sys.source(file.path(d, "discharge_publish_own.R"), envir = e)
  own <- e$publish_own
  expect_type(own, "character")
  expect_false(anyDuplicated(own) > 0)
  expect_true(all(c("scripts/discharge_publish_own.R", "R/wet_segment_monthly.R", "R/wet_segment_daily.R",
                    "scripts/discharge_publish_lib.R", "scripts/discharge_publish.R") %in% own))
  # the daily script is not in the shared list
  expect_false("scripts/segment_daily_output.R" %in% own)
  root <- dirname(d)
  missing <- own[!file.exists(file.path(root, own))]
  expect_true(all(file.exists(file.path(root, own))), info = paste(missing, collapse = ", "))
  # and no file a table is built from: the scripts that build them, and the routed table's code
  expect_false(any(c("scripts/segment_output.R", "scripts/wb_output.R", "scripts/pcic_routed_lib.R",
                     "scripts/wb_fit_lib.R") %in% own))
})
