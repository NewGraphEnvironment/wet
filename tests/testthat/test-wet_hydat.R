# wet_hydat() against a temporary cache. The two network calls are mocked to
# fail unless a test says otherwise, so no test reaches ECCC.
version_file <- function(path, date) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  DBI::dbWriteTable(con, "VERSION", data.frame(Version = "1.0", Date = date))
  DBI::dbDisconnect(con)
  invisible(path)
}

local_no_network <- function(env = parent.frame()) {
  local_mocked_bindings(
    wet_hydat_remote = function() stop("network: hy_remote called"),
    wet_hydat_download = function(dir) stop("network: download_hydat called"),
    .env = env
  )
}

test_that("a cached release is returned without asking ECCC", {
  local_no_network()
  cache <- withr::local_tempdir()
  f <- version_file(file.path(cache, "hydat", "20260717", "Hydat.sqlite3"), "2026-07-17 08:08:08")
  expect_equal(wet:::wet_hydat("20260717", cache_dir = cache), f)
})

test_that("a cached file holding another release is refused", {
  local_no_network()
  cache <- withr::local_tempdir()
  version_file(file.path(cache, "hydat", "20260717", "Hydat.sqlite3"), "2025-10-14 15:09:54")
  err <- expect_error(wet:::wet_hydat("20260717", cache_dir = cache), "holds HYDAT 20251014, not 20260717")
  # a broken cache is not "unavailable": a live test must fail on it, not skip
  expect_false(inherits(err, "wet_hydat_unavailable"))
})

test_that("ECCC's current release is downloaded into the cache", {
  local_no_network()
  cache <- withr::local_tempdir()
  calls <- character()
  local_mocked_bindings(
    wet_hydat_remote = function() "20260717",
    wet_hydat_download = function(dir) {
      # tidyhydat creates its directory without parents: wet makes it
      stopifnot(dir.exists(dir))
      calls <<- c(calls, dir)
      version_file(file.path(dir, "Hydat.sqlite3"), "2026-07-17 08:08:08")
    }
  )
  f <- wet:::wet_hydat("20260717", cache_dir = cache)
  expect_equal(f, file.path(cache, "hydat", "20260717", "Hydat.sqlite3"))
  expect_true(file.exists(f))
  expect_length(calls, 1)
  # the download went to a partial directory, and none is left behind
  expect_false(dirname(calls) == dirname(f))
  expect_equal(list.files(file.path(cache, "hydat"), all.files = TRUE, no.. = TRUE), "20260717")
  # a second call reads the cache
  local_no_network()
  expect_equal(wet:::wet_hydat("20260717", cache_dir = cache), f)
})

test_that("a superseded release is not downloaded, and the error names the backup", {
  local_no_network()
  cache <- withr::local_tempdir()
  local_mocked_bindings(wet_hydat_remote = function() "20260717")
  err <- expect_error(wet:::wet_hydat("20251014", cache_dir = cache), "ECCC serves only HYDAT 20260717",
                      class = "wet_hydat_unavailable")
  expect_match(conditionMessage(err), "s3://fresh-bc/hydat/20251014/", fixed = TRUE)
  expect_match(conditionMessage(err), file.path(cache, "hydat", "20251014", "Hydat.sqlite3"), fixed = TRUE)
  expect_false(dir.exists(file.path(cache, "hydat", "20251014")))
})

test_that("a download holding another release is refused and leaves nothing", {
  local_no_network()
  cache <- withr::local_tempdir()
  # ECCC moved on between the two calls
  local_mocked_bindings(
    wet_hydat_remote = function() "20260717",
    wet_hydat_download = function(dir) version_file(file.path(dir, "Hydat.sqlite3"), "2026-10-20 08:08:08")
  )
  expect_error(wet:::wet_hydat("20260717", cache_dir = cache), "holds HYDAT 20261020, not 20260717")
  expect_length(list.files(file.path(cache, "hydat"), all.files = TRUE, no.. = TRUE), 0)
})

test_that("a failed download leaves nothing", {
  local_no_network()
  cache <- withr::local_tempdir()
  local_mocked_bindings(
    wet_hydat_remote = function() "20260717",
    wet_hydat_download = function(dir) {
      writeBin(as.raw(1:10), file.path(dir, "Hydat.sqlite3"))
      stop("connection reset")
    }
  )
  expect_error(wet:::wet_hydat("20260717", cache_dir = cache), "connection reset")
  expect_length(list.files(file.path(cache, "hydat"), all.files = TRUE, no.. = TRUE), 0)
})

test_that("ECCC unreachable names the backup", {
  local_no_network()
  cache <- withr::local_tempdir()
  err <- expect_error(wet:::wet_hydat("20251014", cache_dir = cache), "could not ask ECCC",
                      class = "wet_hydat_unavailable")
  expect_match(conditionMessage(err), "s3://fresh-bc/hydat/20251014/", fixed = TRUE)
  expect_match(conditionMessage(err), "hy_remote called", fixed = TRUE)
})

test_that("a release must be YYYYMMDD", {
  local_no_network()
  cache <- withr::local_tempdir()
  expect_error(wet:::wet_hydat("2026-07-17", cache_dir = cache), "YYYYMMDD")
  expect_error(wet:::wet_hydat(20260717, cache_dir = cache), "YYYYMMDD")
  expect_error(wet:::wet_hydat(c("20260717", "20251014"), cache_dir = cache), "YYYYMMDD")
  expect_error(wet:::wet_hydat(NA_character_, cache_dir = cache), "YYYYMMDD")
})

test_that("a truncated cached file is refused, not read", {
  local_no_network()
  cache <- withr::local_tempdir()
  f <- file.path(cache, "hydat", "20260717", "Hydat.sqlite3")
  version_file(f, "2026-07-17 08:08:08")
  con <- DBI::dbConnect(RSQLite::SQLite(), f)
  DBI::dbWriteTable(con, "BIG", data.frame(x = seq_len(2e5) / 7))
  DBI::dbDisconnect(con)
  writeBin(readBin(f, "raw", file.size(f))[seq_len(4096 * 20)], f)
  err <- expect_error(wet:::wet_hydat("20260717", cache_dir = cache), "is not a whole HYDAT")
  expect_false(inherits(err, "wet_hydat_unavailable"))
})

test_that("a partial left by a killed run is swept once stale; another run's is left", {
  local_no_network()
  cache <- withr::local_tempdir()
  root <- file.path(cache, "hydat")
  old <- file.path(root, ".20260717.partial-old")
  live <- file.path(root, ".20260717.partial-live")
  dir.create(old, recursive = TRUE)
  dir.create(live)
  Sys.setFileTime(old, Sys.time() - 3 * 86400)
  local_mocked_bindings(
    wet_hydat_remote = function() "20260717",
    wet_hydat_download = function(dir) version_file(file.path(dir, "Hydat.sqlite3"), "2026-07-17 08:08:08")
  )
  wet:::wet_hydat("20260717", cache_dir = cache)
  expect_false(dir.exists(old))
  expect_true(dir.exists(live))
})

test_that("when another run lands the release first, its copy is used", {
  local_no_network()
  cache <- withr::local_tempdir()
  target <- file.path(cache, "hydat", "20260717", "Hydat.sqlite3")
  local_mocked_bindings(
    wet_hydat_remote = function() "20260717",
    wet_hydat_download = function(dir) {
      version_file(file.path(dir, "Hydat.sqlite3"), "2026-07-17 08:08:08")
      # the other run renames its download into place meanwhile
      version_file(target, "2026-07-17 08:08:08")
    }
  )
  expect_equal(wet:::wet_hydat("20260717", cache_dir = cache), target)
  expect_equal(list.files(file.path(cache, "hydat"), all.files = TRUE, no.. = TRUE), "20260717")
})

test_that("an answer from ECCC that is not a release is an error, not a skip", {
  local_no_network()
  cache <- withr::local_tempdir()
  local_mocked_bindings(wet_hydat_remote = function() "<html>")
  err <- expect_error(wet:::wet_hydat("20260717", cache_dir = cache), "not YYYYMMDD")
  expect_false(inherits(err, "wet_hydat_unavailable"))
})
