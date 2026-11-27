# The pin (#235): manifest shape, md5s, fetching only where allowed.

pin_readings <- function() logger_readings("01XX001", "2020-07-01 08:00", 96, 12)

test_that("a cached file and its members are held to the manifest", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  expect_equal(wet_logger("tst", "1", "01_Data.zip"), fx$zip)
  p <- wet_logger_members("tst", "1", "01_Data.zip/01_Data/01XX001_Site.csv")
  expect_true(file.exists(p))
  expect_equal(unname(tools::md5sum(p)), fx$manifest$md5[2])
})

test_that("a file whose bytes differ from the manifest is refused", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  cat("x", file = fx$zip, append = TRUE)
  expect_error(wet_logger("tst", "1", "01_Data.zip"), "not the manifest's")
})

test_that("a member whose md5 differs from the manifest is refused", {
  fx <- logger_fixture(pin_readings())
  man <- fx$manifest
  man$md5[2] <- strrep("0", 32)
  utils::write.csv(man, file.path(fx$ext, "tst_1.csv"), row.names = FALSE, na = "")
  local_logger_fixture(fx)
  expect_error(wet_logger_members("tst", "1", "01_Data.zip/01_Data/01XX001_Site.csv"), "not the manifest's")
})

test_that("a missing file with fetch FALSE is never requested", {
  fx <- logger_fixture(pin_readings(), fetch = FALSE)
  local_logger_fixture(fx)
  asked <- FALSE
  local_mocked_bindings(curl_download = function(...) {
    asked <<- TRUE
    stop("network")
  }, .package = "curl")
  unlink(fx$zip)
  expect_error(wet_logger("tst", "1", "01_Data.zip"), class = "wet_logger_unavailable")
  expect_error(wet_logger("tst", "1", "01_Data.zip"), "wet does not fetch it.*s3://fresh-bc/temp_loggers/tst/1/")
  expect_false(asked)
})

test_that("a missing file with fetch TRUE is fetched, and a failed fetch is classed", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  keep <- file.path(fx$dir, "keep.zip")
  file.copy(fx$zip, keep)
  unlink(fx$zip)
  expect_error(suppressMessages(wet_logger("tst", "1", "01_Data.zip")), class = "wet_logger_unavailable")
  local_mocked_bindings(curl_download = function(url, destfile, ...) {
    expect_match(url, "/records/1/")
    file.copy(keep, destfile, overwrite = TRUE)
  }, .package = "curl")
  expect_message(p <- wet_logger("tst", "1", "01_Data.zip"), "once per machine")
  expect_equal(unname(tools::md5sum(p)), fx$manifest$md5[1])
})

test_that("a fetched file with the wrong md5 is refused and not kept", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  unlink(fx$zip)
  local_mocked_bindings(curl_download = function(url, destfile, ...) {
    writeLines(strrep("x", 10), destfile)
  }, .package = "curl")
  expect_error(suppressMessages(wet_logger("tst", "1", "01_Data.zip")), "not the manifest's")
  expect_false(file.exists(fx$zip))
})

test_that("a manifest whose URL is not its record's, or of the wrong shape, is refused", {
  fx <- logger_fixture(pin_readings())
  local_logger_fixture(fx)
  path <- file.path(fx$ext, "tst_1.csv")
  bad <- function(man) {
    utils::write.csv(man, path, row.names = FALSE, na = "")
    expect_error(wet_logger_manifest("tst", "1"), "is not a list of files")
  }
  man <- fx$manifest
  bad(transform(man, url = sub("/records/1/", "/records/2/", url)))
  bad(transform(man, fetch = c(NA, NA)))
  bad(transform(man, url = c(man$url[1], man$url[1])))
  bad(man[2, ])
  bad(transform(man, md5 = c("abc", man$md5[2])))
  bad(rbind(man, man[2, ]))
  utils::write.csv(man, path, row.names = FALSE, na = "")
  expect_error(wet_logger_manifest("tst", "1a"), "digits only")
  expect_error(wet_logger_manifest("TST", "1"), "lower-case")
  expect_error(wet_logger_manifest("tst", "2"), "no tracked manifest")
  expect_error(wet_logger("tst", "1", "other.zip"), "not a file of tst 1")
})

test_that("the registry holds one row per site, each id the series' own", {
  fx <- logger_fixture(rbind(pin_readings(), logger_readings("01XX002", "2020-07-01 08:00", 4, 10)))
  local_logger_fixture(fx)
  s <- wet_logger_sites("tst")
  expect_equal(s$station_number, c("TST_01XX001", "TST_01XX002"))
  path <- file.path(fx$ext, "tst_1_sites.csv")
  bad <- function(reg) {
    utils::write.csv(reg, path, row.names = FALSE, na = "")
    expect_error(wet_logger_sites("tst"), "does not hold one row per site")
  }
  reg <- fx$registry
  bad(transform(reg, station_number = c("TST_01XX001", "TST_01XX001")))
  bad(transform(reg, station_number = c("08EE013", "TST_01XX002")))
  bad(transform(reg, subdrainage = c("08J", NA)))
  bad(transform(reg, subdrainage = c("08", "08J")))
  bad(transform(reg, record = "2"))
  bad(reg[, -2])
})

test_that("the shipped Nechako manifests and registry pass their own checks", {
  for (v in c("15053907", "6426024")) {
    man <- wet_logger_manifest("nhg", v)
    expect_true(all(grepl("^https://zenodo.org/records/", man$url[!is.na(man$url)])))
    expect_true(all(man$fetch[!is.na(man$fetch)]))
  }
  s <- wet_logger_sites("nhg")
  expect_equal(nrow(s), 32L)
  expect_true(all(grepl("^NHG_[0-9]{2}[A-Z]{2}[0-9]{3}$", s$station_number)))
  expect_false(any(grepl(wet_hydat_number, s$station_number)))
  man <- wet_logger_manifest("nhg", "15053907")
  expect_true(all(s$member %in% man$file))
  expect_true(all(stats::na.omit(s$prior_member) %in% wet_logger_manifest("nhg", "6426024")$file))
})
