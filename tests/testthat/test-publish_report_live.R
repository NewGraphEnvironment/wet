# The publish report's live-build line (#117, #94): PUBLISH writes it only once
# its upload verifies, and vd_published() takes it only for the live parts.
# Both live in scripts/, which R CMD check does not ship, so these run under
# devtools::test() only.

publish_libs <- function() {
  scripts <- test_path("..", "..", "scripts")
  skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "discharge_publish_lib.R"), envir = e)
  sys.source(file.path(scripts, "vignette_data_lib.R"), envir = e)
  e
}

# the shipped manifest's parts, as the live build at commit abc1234
live_catalog <- function() {
  cat <- wet_catalog(system.file("extdata", "discharge_manifest.json", package = "wet"))
  attr(cat, "manifest") <- wet_catalog_url
  attr(cat, "provenance") <- list(wet_version = "fixture", wet_commit = "abc1234")
  cat
}

# a passing BUILD report of abc1234, whose tree is `tree` and whose live-build
# line is `line`
local_report <- function(line, tree = live_catalog(), env = parent.frame()) {
  f <- withr::local_tempfile(fileext = ".txt", .local_envir = env)
  writeLines(c(
    "# Published discharge, build (#7)", "",
    "wet commit abc1234 (segment table built at def5678); fit 20260717, province run x; crate 0.0.0",
    sprintf("tree parts md5 %s", wet_catalog_digest(tree)), "",
    "## Cross-checks against the segment report, and value by value",
    "segment_rows    ok", "",
    "## Against the published tree", line, "",
    "## What a reader sees (duckdb, hive_partitioning = true, over the local tree)",
    "historical PNWNAmet  pcic_routed           26 rows         2 fresh-subquery rows",
    "historical climr     wet_balance           26 rows         2 fresh-subquery rows"
  ), f)
  f
}

ok_verify <- function(cat) data.frame(key = cat$key, ok = TRUE, reason = "", stringsAsFactors = FALSE)

test_that("PUBLISH leaves the report as it was unless its upload verified", {
  e <- publish_libs()
  cat <- live_catalog()
  f <- local_report("parts identical to the published build 0000000: 0 of 5 here, 5 published (u)")
  before <- unname(tools::md5sum(f))
  bad <- ok_verify(cat)
  bad$ok[3] <- FALSE
  expect_error(e$publish_report_live(f, cat, cat, bad), "did not all verify")
  expect_error(e$publish_report_live(f, cat, cat, ok_verify(cat)[-1, ]), "did not all verify")
  expect_error(e$publish_report_live(f, cat, cat, ok_verify(cat)[0, ]), "did not all verify")
  other <- cat
  other$md5[2] <- sprintf("%032d", 0)
  expect_error(e$publish_report_live(f, cat, other, ok_verify(other)), "not the local ones")
  expect_identical(unname(tools::md5sum(f)), before)
})

test_that("PUBLISH refuses a report of another build, a failed one, or one with no single live line", {
  e <- publish_libs()
  cat <- live_catalog()
  line <- "parts identical to the published build 0000000: 0 of 5 here, 5 published (u)"
  f <- local_report(line)
  other <- cat
  attr(other, "provenance")$wet_commit <- "abc123"
  expect_error(e$publish_report_live(f, other, other, ok_verify(other)), "not a passing report")
  writeLines(sub("segment_rows    ok", "segment_rows    FAIL", readLines(f)), f)
  expect_error(e$publish_report_live(f, cat, cat, ok_verify(cat)), "not a passing report")
  f <- local_report("something else")
  expect_error(e$publish_report_live(f, cat, cat, ok_verify(cat)), "no single live-build line")
  # #94 through PUBLISH: a tree rebuilt at the report's commit from other
  # inputs, uploaded, must not get the old report certified for it
  rebuilt <- cat
  rebuilt$md5[1] <- sprintf("%032d", 0)
  f <- local_report(line)
  before <- unname(tools::md5sum(f))
  expect_error(e$publish_report_live(f, rebuilt, rebuilt, ok_verify(rebuilt)), "not a passing report")
  expect_identical(unname(tools::md5sum(f)), before)
  f <- local_report(line)
  writeLines(c(readLines(f), "## Against the published tree", line), f)
  expect_error(e$publish_report_live(f, cat, cat, ok_verify(cat)), "no single live-build line")
})

test_that("a verified upload rewrites only the live-build line, and vd_published() takes it", {
  e <- publish_libs()
  cat <- live_catalog()
  f <- local_report("parts identical to the published build 0000000: 1 of 5 here, 5 published (u); live parts md5 x")
  before <- readLines(f)
  line <- e$publish_report_live(f, cat, cat, ok_verify(cat))
  after <- readLines(f)
  i <- which(before != after)
  expect_identical(i, which(before == "## Against the published tree") + 1L)
  expect_identical(after[i], line)
  expect_identical(line, sprintf(
    "parts identical to the published build abc1234: 5 of 5 here, 5 published (%s); live parts md5 %s",
    wet_catalog_url, wet_catalog_digest(cat)))
  e$wet_catalog <- function(...) cat
  e$wb_report <- function(stem, release) f
  pb <- e$vd_published("20260717")
  expect_identical(pb$build_commit, "abc1234")
  expect_identical(pb$segment_commit, "def5678")
  expect_setequal(pb$reader$source, c("pcic_routed", "wet_balance"))
})

test_that("vd_published() refuses a line naming the live commit and count over other parts (#94)", {
  e <- publish_libs()
  cat <- live_catalog()
  # the line a rebuild at the live commit, from other inputs, would have
  # written: same commit, same count, another digest
  rebuilt <- cat
  rebuilt$md5[1] <- sprintf("%032d", 0)
  f <- local_report(e$publish_live_line(rebuilt, rebuilt))
  e$wet_catalog <- function(...) cat
  e$wb_report <- function(stem, release) f
  expect_error(e$vd_published("20260717"), "not a passing value check of the live build abc1234")
  # the line before #94, with no digest
  f <- local_report(sprintf("parts identical to the published build abc1234: 5 of 5 here, 5 published (%s)",
                            wet_catalog_url))
  expect_error(e$vd_published("20260717"), "not a passing value check")
  # the right line, but a check failed
  f <- local_report(e$publish_live_line(cat, cat))
  expect_no_error(e$vd_published("20260717"))
  writeLines(sub("segment_rows    ok", "segment_rows    FAIL", readLines(f)), f)
  expect_error(e$vd_published("20260717"), "not a passing value check")
  # a BUILD's line with parts still to upload
  f <- local_report(e$publish_live_line(rebuilt, cat), tree = rebuilt)
  expect_error(e$vd_published("20260717"), "not a passing value check")
  # a report of another tree, whose live-build line was certified for the
  # live parts: its value checks describe parts that are not live
  f <- local_report(e$publish_live_line(cat, cat), tree = rebuilt)
  expect_error(e$vd_published("20260717"), "not a passing value check")
  # a republish of identical bytes: the BUILD's own line already reads N of N
  f <- local_report(e$publish_live_line(cat, cat))
  expect_no_error(e$vd_published("20260717"))
})
