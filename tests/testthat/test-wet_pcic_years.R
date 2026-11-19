# wet_pcic_years() against a temporary cache (#135). The download is mocked to
# fail unless a test says otherwise, so no test reaches the bucket.
local_no_download <- function(env = parent.frame()) {
  local_mocked_bindings(wet_pcic_years_download = function(url, dest) stop("network: download called"),
                        .env = env)
  withr::local_envvar(WET_PCIC_YEARS = NA, .local_envir = env)
}

year_file <- function(dir, year, n, series = "PNWNAmet_historical") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  f <- file.path(dir, sprintf("pcic.subbasin_days.%s.%d.parquet", series, year))
  writeBin(as.raw(rep(1L, n)), f)
  f
}

test_that("cached years are used without a download", {
  local_no_download()
  cache <- withr::local_tempdir()
  d <- file.path(cache, "pcic_years", "PNWNAmet_historical")
  year_file(d, 1951, 10)
  year_file(d, 1952, 12)
  expect_equal(wet:::wet_pcic_years(1951:1952, c(10, 12), cache_dir = cache), d)
})

test_that("a missing year is downloaded into the cache, through a partial file", {
  local_no_download()
  cache <- withr::local_tempdir()
  calls <- list()
  local_mocked_bindings(wet_pcic_years_download = function(url, dest) {
    calls[[length(calls) + 1]] <<- c(url = url, dest = dest)
    writeBin(as.raw(rep(1L, 7)), dest)
  })
  d <- wet:::wet_pcic_years(1960, 7, cache_dir = cache)
  f <- file.path(d, "pcic.subbasin_days.PNWNAmet_historical.1960.parquet")
  expect_equal(file.size(f), 7)
  expect_length(calls, 1)
  expect_equal(calls[[1]][["url"]], paste0("https://fresh-bc.s3.us-west-2.amazonaws.com/fwapg/extras/",
                                           "pcic.subbasin_days.PNWNAmet_historical.1960.parquet"))
  # the download went to another name, and no partial is left behind
  expect_false(calls[[1]][["dest"]] == f)
  expect_equal(list.files(d, all.files = TRUE, no.. = TRUE), basename(f))
  # a second call reads the cache
  local_no_download()
  expect_equal(wet:::wet_pcic_years(1960, 7, cache_dir = cache), d)
})

test_that("a cut-off download never lands under the year's name", {
  local_no_download()
  cache <- withr::local_tempdir()
  local_mocked_bindings(wet_pcic_years_download = function(url, dest) writeBin(as.raw(rep(1L, 3)), dest))
  expect_error(wet:::wet_pcic_years(1960, 7, cache_dir = cache), "3 bytes, not the 7")
  d <- file.path(cache, "pcic_years", "PNWNAmet_historical")
  expect_length(list.files(d, all.files = TRUE, no.. = TRUE), 0)
})

test_that("a download that fails leaves nothing", {
  local_no_download()
  cache <- withr::local_tempdir()
  local_mocked_bindings(wet_pcic_years_download = function(url, dest) {
    writeBin(as.raw(1L), dest)
    stop("HTTP 503")
  })
  expect_error(wet:::wet_pcic_years(1960, 7, cache_dir = cache), "HTTP 503")
  d <- file.path(cache, "pcic_years", "PNWNAmet_historical")
  expect_length(list.files(d, all.files = TRUE, no.. = TRUE), 0)
})

test_that("a cached year of the wrong size is refused, not fetched again", {
  local_no_download()
  cache <- withr::local_tempdir()
  f <- year_file(file.path(cache, "pcic_years", "PNWNAmet_historical"), 1951, 10)
  expect_error(wet:::wet_pcic_years(1951, 11, cache_dir = cache), "10 bytes, not the 11")
  expect_equal(file.size(f), 10)
})

test_that("WET_PCIC_YEARS names a directory that is read and never written", {
  local_no_download()
  cache <- withr::local_tempdir()
  own <- withr::local_tempdir()
  withr::local_envvar(WET_PCIC_YEARS = own)
  # a year missing there is left for the caller's own check to refuse
  expect_equal(wet:::wet_pcic_years(1951, 10, cache_dir = cache), own)
  expect_length(list.files(own, all.files = TRUE, no.. = TRUE), 0)
  expect_false(dir.exists(file.path(cache, "pcic_years")))
})

test_that("its arguments are checked", {
  local_no_download()
  cache <- withr::local_tempdir()
  expect_error(wet:::wet_pcic_years(1951:1952, 10, cache_dir = cache), "one byte count per year")
  expect_error(wet:::wet_pcic_years(c(1951, 1951), c(1, 1), cache_dir = cache), "distinct years")
  expect_error(wet:::wet_pcic_years(1951, NA, cache_dir = cache), "one byte count per year")
  expect_error(wet:::wet_pcic_years(1951, 1, series = "../x", cache_dir = cache), "`series`")
})
