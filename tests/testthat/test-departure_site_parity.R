# The Maxan site run against #120's and #121's tracked reports (#146): the
# pilot scripts are retired, so their reports are the record that
# scripts/departure_site.R and scripts/departure_site_snow.R must reproduce
# for the maxan row under the BULK windows. The helpers and the reports live
# in scripts/ and data/checks/, which R CMD check does not ship, so these run
# under devtools::test() only.

parity_lib <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "departure_site_lib.R"), envir = e)
  e
}

tracked_report <- function(f) {
  p <- testthat::test_path("..", "..", "data", "checks", f)
  testthat::skip_if_not(file.exists(p), "data/checks/ is not in the installed package")
  readLines(p)
}

# the row's last digit, moved by one
bump_last_digit <- function(x) {
  d <- as.integer(sub("^.*([0-9])[^0-9]*$", "\\1", x))
  sub("([0-9])([^0-9]*)$", paste0((d + 1) %% 10, "\\2"), x)
}

# the row of `x` after the first line matching `head`, so a fixture edits a row the reports share
row_after <- function(x, head, k = 1) {
  i <- grep(head, x)[1]
  stopifnot(!is.na(i))
  i + k
}

test_that("the tracked Maxan site reports reproduce the pilot's and the snow regression's", {
  e <- parity_lib()
  pilot <- tracked_report("departure_pilot_20260717.txt")
  site <- tracked_report("departure_site_maxan_bulk_20260717.txt")
  expect_identical(e$site_parity_pilot(site, pilot), character())
  snow <- tracked_report("departure_snow_20260717.txt")
  site_snow <- tracked_report("departure_site_snow_maxan_bulk_20260717.txt")
  expect_identical(e$site_parity_snow(site_snow, snow), character())
})

test_that("a changed digit, a missing row or a changed prose line in the site report is caught", {
  e <- parity_lib()
  pilot <- tracked_report("departure_pilot_20260717.txt")
  site <- tracked_report("departure_site_maxan_bulk_20260717.txt")

  # one digit of 1931's migration mean
  i <- grep("^  1931 ", site)[1]
  bad <- site
  bad[i] <- bump_last_digit(bad[i])
  expect_false(identical(bad[i], site[i]))
  expect_identical(e$site_parity_pilot(bad, pilot), sub(" +$", "", site[i]))

  # a row dropped
  j <- grep("^  08EE013 ", site)[1]
  expect_identical(e$site_parity_pilot(site[-j], pilot), sub(" +$", "", site[j]))

  # a prose line the old gate named
  h <- grep("^HEADLINE: ", site)
  bad <- site
  bad[h] <- sub("0\\.63", "0.64", bad[h])
  expect_identical(e$site_parity_pilot(bad, pilot), grep("^HEADLINE: ", pilot, value = TRUE))
})

test_that("the change table is compared without the site's carried interval columns, and nothing else", {
  e <- parity_lib()
  pilot <- tracked_report("departure_pilot_20260717.txt")
  site <- tracked_report("departure_site_maxan_bulk_20260717.txt")
  k <- row_after(site, "^  statistic window +pre post +change +% normal +90 % interval +carried +% normal")

  # the carried change itself (columns 74-82) is the pilot's too
  bad <- site
  substr(bad[k], 74, 82) <- formatC("-9.999", width = 9)
  expect_false(identical(bad[k], site[k]))
  expect_length(e$site_parity_pilot(bad, pilot), 1)

  # the carried % normal and interval (columns 83-111) are the site run's alone
  ok <- site
  substr(ok[k], 83, 111) <- strrep("z", 29)
  expect_identical(e$site_parity_pilot(ok, pilot), character())

  # a site report without the table: every one of the pilot's change rows is missing
  gone <- site[-(k - 1):-(k + 7)]
  expect_length(e$site_parity_pilot(gone, pilot), 9)
})

test_that("a tracked report without the parts the gate reads is refused, not passed", {
  e <- parity_lib()
  pilot <- tracked_report("departure_pilot_20260717.txt")
  site <- tracked_report("departure_site_maxan_bulk_20260717.txt")
  expect_error(e$site_parity_pilot(site, character()), "no table rows")
  no_change <- pilot[!grepl("^  statistic window +pre post +change", pilot)]
  expect_error(e$site_parity_pilot(site, no_change), "change table")
  # an exemption that no longer matches one line, or matches two, is refused
  expect_error(e$site_parity_pilot(site, pilot[!grepl("^USABLE ", pilot)]), "exemptions")
  expect_error(e$site_parity_pilot(site, c(pilot, "USABLE twice")), "exemptions")
  expect_error(e$site_parity_snow(site, character()), "no table rows")
})

test_that("a result in a prose line is caught, and an exempt line is not compared", {
  e <- parity_lib()
  pilot <- tracked_report("departure_pilot_20260717.txt")
  site <- tracked_report("departure_site_maxan_bulk_20260717.txt")
  # the donor chain, which no table row prints
  i <- grep("^Donor chain \\(nearest first\\): ", site)
  expect_length(i, 1)
  bad <- site
  bad[i] <- sub("08ED002, 08ED001", "08ED001, 08ED002", bad[i])
  expect_identical(e$site_parity_pilot(bad, pilot), grep("^Donor chain ", pilot, value = TRUE))
  # the snow report's cd provenance rows are exempt: a republish of the layers moves them alone
  snow <- tracked_report("departure_snow_20260717.txt")
  site_snow <- tracked_report("departure_site_snow_maxan_bulk_20260717.txt")
  j <- grep("^  swe_max: https://", site_snow)
  ok <- site_snow
  ok[j] <- sub("CD_SHA [0-9a-f]+", "CD_SHA 0000", ok[j])
  expect_identical(e$site_parity_snow(ok, snow), character())
})

test_that("a changed snow fit is caught", {
  e <- parity_lib()
  snow <- tracked_report("departure_snow_20260717.txt")
  site_snow <- tracked_report("departure_site_snow_maxan_bulk_20260717.txt")
  i <- grep("^  08EE018 carried spawning +doy ", site_snow)
  expect_length(i, 1)
  bad <- site_snow
  bad[i] <- bump_last_digit(bad[i])
  expect_false(identical(bad[i], site_snow[i]))
  expect_identical(e$site_parity_snow(bad, snow), sub(" +$", "", site_snow[i]))
})
