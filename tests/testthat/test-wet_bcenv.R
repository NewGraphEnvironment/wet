# A snapshot of two small files under a temporary cache, with a manifest of
# their md5s standing in for the tracked one.
local_bcenv_cache <- function(env = parent.frame()) {
  cache <- withr::local_tempdir(.local_envir = env)
  dir <- file.path(cache, "station_sources", "bcenv", "20261028")
  dir.create(dir, recursive = TRUE)
  writeLines("Location ID,Value\r\nA,1", file.path(dir, "Discharge.csv"))
  writeLines("Location ID,Value\r\nA,2", file.path(dir, "Discharge_Archive_Pre_20151001.csv"))
  f <- file.path(dir, c("Discharge.csv", "Discharge_Archive_Pre_20151001.csv"))
  man <- data.frame(file = basename(f), bytes = file.size(f), md5 = unname(tools::md5sum(f)))
  local_mocked_bindings(wet_bcenv_manifest = function(snapshot) man, .env = env)
  list(cache = cache, dir = dir)
}

test_that("a whole snapshot returns its files newest first", {
  s <- local_bcenv_cache()
  f <- wet_bcenv("20261028", cache_dir = s$cache)
  expect_equal(basename(f), c("Discharge.csv", "Discharge_Archive_Pre_20151001.csv"))
})

test_that("a cached file whose md5 differs from the manifest's is refused", {
  s <- local_bcenv_cache()
  # same size, one byte changed
  writeLines("Location ID,Value\r\nA,9", file.path(s$dir, "Discharge.csv"))
  expect_error(wet_bcenv("20261028", cache_dir = s$cache), "md5 .* not the manifest's")
  writeLines("Location ID,Value\r\nA,10", file.path(s$dir, "Discharge.csv"))
  expect_error(wet_bcenv("20261028", cache_dir = s$cache), "bytes, not the manifest's")
})

test_that("a missing file is never fetched: the error names the backup", {
  s <- local_bcenv_cache()
  unlink(file.path(s$dir, "Discharge.csv"))
  # no fetch path exists; any attempt to reach the network would fail loudly
  local_mocked_bindings(curl_download = function(...) stop("network"), curl_fetch_disk = function(...) stop("network"),
                        .package = "curl")
  err <- expect_error(wet_bcenv("20261028", cache_dir = s$cache), class = "wet_bcenv_unavailable")
  expect_match(conditionMessage(err), "s3://fresh-bc/station_sources/bcenv/20261028/", fixed = TRUE)
  expect_match(conditionMessage(err), "Discharge.csv")
  expect_no_match(conditionMessage(err), "network")
})

test_that("the tracked manifest of the default snapshot is read and checked for shape", {
  man <- wet_bcenv_manifest(wet_bcenv_snapshot)
  expect_named(man, c("file", "bytes", "md5"))
  expect_equal(nrow(man), 8)
  expect_true(all(grepl("^[0-9a-f]{32}$", man$md5)))
  expect_error(wet_bcenv_manifest("2026-10-28"), "YYYYMMDD")
  expect_error(wet_bcenv_manifest("19000101"), "no tracked manifest")
})

test_that("files are ordered by the period their names give, and an unknown name is refused", {
  files <- c("Discharge_Archive_Pre_20151001.csv", "Discharge_Archive_2015Oct_2017Oct.csv", "Discharge.csv",
             "Discharge_Archive_Post_20251001.csv", "Discharge_Archive_2023Oct_2025Oct.csv")
  expect_equal(files[wet_bcenv_order(files)],
               c("Discharge.csv", "Discharge_Archive_Post_20251001.csv", "Discharge_Archive_2023Oct_2025Oct.csv",
                 "Discharge_Archive_2015Oct_2017Oct.csv", "Discharge_Archive_Pre_20151001.csv"))
  expect_error(wet_bcenv_order(c("Discharge.csv", "Discharge_Archive_Recent.csv")), "cannot tell the period")
  expect_error(wet_bcenv_order(c("Discharge_Archive_2015Foo_2017Oct.csv")), "cannot tell the period")
})

test_that("live: the pinned snapshot in this machine's cache holds the manifest's files", {
  f <- tryCatch(wet_bcenv(), wet_bcenv_unavailable = function(e) skip(conditionMessage(e)))
  expect_equal(basename(f)[1], "Discharge.csv")
  expect_length(f, 8)
})
