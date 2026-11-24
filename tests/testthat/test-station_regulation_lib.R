# The guards in scripts/station_regulation_lib.R (#196), with a stand-in for the WFS. scripts/ is
# not in the installed package, so these run from the source tree only.
local_lib <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  for (f in c("station_sources_lib.R", "station_regulation_rule.R", "station_regulation_lib.R")) {
    sys.source(file.path(scripts, f), envir = e)
  }
  e
}
# a WFS stand-in for the dams layer: `pages` is a list of id vectors, one per page request in turn
local_wfs <- function(e, n_hits, pages) {
  calls <- 0L
  function(url, dest) {
    if (grepl("resultType=hits", url, fixed = TRUE)) {
      writeLines(sprintf('<wfs:FeatureCollection numberMatched="%d"/>', n_hits), dest)
      return(invisible(dest))
    }
    calls <<- calls + 1L
    ids <- pages[[min(calls, length(pages))]]
    utils::write.csv(data.frame(WRIS_DP_SYSID = ids, DAM_NAME = paste("dam", ids)), dest, row.names = FALSE)
    invisible(dest)
  }
}

test_that("a layer is read only when it holds the server's count, once each", {
  e <- local_lib()
  e$rg_page_size <- 3
  dir <- withr::local_tempdir()
  f <- e$rg_wfs_snapshot("dams", dir, local_wfs(e, 5, list(1:3, 4:5)), msg = function(...) NULL)
  expect_length(f, 2)
  expect_equal(nrow(e$rg_wfs_read("dams", f, dir)), 5)
  # one row short of the server's count
  writeLines("6", file.path(dir, "dams_hits.txt"))
  expect_error(e$rg_wfs_read("dams", f, dir), "5 rows \\(0 duplicated ids\\) against the server's 6")
  # an id twice
  writeLines("5", file.path(dir, "dams_hits.txt"))
  utils::write.csv(data.frame(WRIS_DP_SYSID = c(3, 4), DAM_NAME = "x"), f[2], row.names = FALSE)
  expect_error(e$rg_wfs_read("dams", f, dir), "1 duplicated ids")
})

test_that("a page out of sequence is fetched again, and refused the third time", {
  e <- local_lib()
  e$rg_page_size <- 3
  dir <- withr::local_tempdir()
  # the second page first comes back as the first (a malformed startIndex), then right
  f <- e$rg_wfs_snapshot("dams", dir, local_wfs(e, 5, list(1:3, 1:3, 4:5)), msg = function(...) NULL)
  expect_equal(nrow(e$rg_wfs_read("dams", f, dir)), 5)
  dir2 <- withr::local_tempdir()
  expect_error(e$rg_wfs_snapshot("dams", dir2, local_wfs(e, 5, list(1:3, 1:3)), msg = function(...) NULL),
               "dams page 2 out of sequence 3 times")
})

licence_rows <- function(...) {
  base <- data.frame(WLS_WRL_SYSID = c("1", "2"), POD_NUMBER = c("PD1", "PD2"), POD_SUBTYPE = "POD",
                     LICENCE_NUMBER = "100", LICENCE_STATUS = "Current", PURPOSE_USE_CODE = "03B",
                     REDIVERSION_IND = "N", QUANTITY = "1000", QUANTITY_UNITS = "m3/year ", QUANTITY_FLAG = "M",
                     SHAPE = "POINT (1 1)")
  for (k in names(list(...))) base[[k]] <- list(...)[[k]]
  base
}

test_that("a shared quantity is split over the PODs that are not rediversions", {
  e <- local_lib()
  x <- e$rg_licence_rows(licence_rows())
  expect_equal(x$v, c(500, 500))
  expect_true(all(x$candidate))
  # a licence whose second POD rediverts: the first carries the whole quantity
  x <- e$rg_licence_rows(licence_rows(REDIVERSION_IND = c("N", "Y")))
  expect_equal(x$v[x$POD_NUMBER == "PD1"], 1000)
  expect_equal(x$candidate, c(TRUE, FALSE))
  # rows not Current never count; a status outside the rule's set stops
  x <- e$rg_licence_rows(licence_rows(LICENCE_STATUS = c("Current", "Cancelled")))
  expect_equal(nrow(x), 1)
  expect_equal(x$v, 1000)
  expect_error(e$rg_licence_rows(licence_rows(LICENCE_STATUS = c("Current", "Pending"))), "LICENCE_STATUS")
})

test_that("a surface licence that would count but states no volume is flagged (Amendment 2)", {
  e <- local_lib()
  x <- e$rg_licence_rows(licence_rows(QUANTITY_UNITS = c("m3/year", "Total Flow"), QUANTITY_FLAG = "T"))
  expect_equal(x$novol, c(FALSE, TRUE))
  expect_equal(x$candidate, c(TRUE, FALSE))
  x <- e$rg_licence_rows(licence_rows(QUANTITY = c("1000", "0"), QUANTITY_FLAG = "T"))
  expect_equal(x$novol, c(FALSE, TRUE))
  # not on groundwater, not a power purpose, not a rediversion
  x <- e$rg_licence_rows(licence_rows(QUANTITY = c("0", "0"), QUANTITY_FLAG = "T", POD_SUBTYPE = c("POD", "PWD")))
  expect_equal(x$novol, c(TRUE, FALSE))
  x <- e$rg_licence_rows(licence_rows(QUANTITY = c("0", "0"), QUANTITY_FLAG = "T", PURPOSE_USE_CODE = "07A"))
  expect_equal(x$novol, c(FALSE, FALSE))
  expect_true(all(x$power))
  x <- e$rg_licence_rows(licence_rows(QUANTITY = c("0", "0"), QUANTITY_FLAG = "T", REDIVERSION_IND = c("N", "Y")))
  expect_equal(x$novol, c(TRUE, FALSE))
})

test_that("a split over a POD that cannot count stops", {
  e <- local_lib()
  # under #53's split (rediversions included), a licence with a rediversion POD loses half its quantity
  rows <- licence_rows(REDIVERSION_IND = c("N", "Y"))
  expect_no_error(e$rg_licence_rows(rows))
  e$rg_split_pods <- function(located, kept, shared, redivert) located & kept & shared
  expect_error(e$rg_licence_rows(rows), "1 located PODs of shared licence-purposes are not counted")
})

test_that("own-reach points below the station are dropped from the upstream pairs", {
  e <- local_lib()
  up <- data.frame(station_number = c("A", "A", "B"), pid = c("L1", "D2", "L1"), own = c(TRUE, FALSE, TRUE))
  own <- data.frame(station_number = c("A", "B"), pid = c("L1", "L1"), indexed = c(TRUE, TRUE),
                    upstream = c(FALSE, TRUE))
  x <- e$rg_upstream_pairs(up, own)
  expect_equal(paste(x$station_number, x$pid), c("A D2", "B L1"))
  # an own-reach pair with no stream-position result is a broken placement
  expect_error(e$rg_upstream_pairs(up, own[2, ]))
})
