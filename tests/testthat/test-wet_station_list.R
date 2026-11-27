test_that("the list is one row per station with the documented columns, provincial, Tool, then Hakai", {
  s <- wet_station_list()
  expect_named(s, c("station_number", "name", "lon", "lat", "source", "network", "first", "last", "regulation",
                    "hydat_site", "hydat_km", "licence", "credit"))
  expect_equal(as.vector(table(s$source)[c("bcenv", "bcwatertool", "hakai")]), c(211, 46, 4))
  expect_false(anyDuplicated(s$station_number) > 0)
  key <- paste(s$source, s$station_number)
  expect_identical(key, sort(key, method = "radix"))
  expect_s3_class(s$first, "Date")
  expect_true(all(s$first <= s$last, na.rm = TRUE))
  expect_true(all(s$regulation %in% c("natural", "regulated", "unknown")))
  # BC's longitudes and latitudes
  expect_true(all(s$lon > -140 & s$lon < -114 & s$lat > 48 & s$lat < 60.1))
})

test_that("the provincial list alone is the province's 211 stations under its licence", {
  s <- wet_station_list("bcenv")
  expect_equal(nrow(s), 211)
  expect_true(all(s$source == "bcenv") && all(s$licence == "OGL-BC 2.0"))
  expect_identical(s$station_number, sort(s$station_number, method = "radix"))
  expect_match(s$credit[1], "Open Government Licence \u2013 British Columbia", fixed = TRUE)
})

test_that("the Tool's gauges carry their network and their own credit, and state no licence", {
  s <- wet_station_list("bcwatertool")
  expect_equal(nrow(s), 46)
  expect_true(all(s$source == "bcwatertool") && all(is.na(s$licence)))
  expect_false(any(grepl("Any reliance|BC ENV", c(s$credit, s$network))))
  expect_true(all(grepl("^Data from ", s$credit)))
  # the listings at provincial sites continue those stations, and are not stations of their own
  expect_false(any(c("2601", "4601", "4602", "4603") %in% s$station_number))
  expect_true(all(c("HRB3142", "UC 5") %in% s$station_number))
})

test_that("a provincial station a Tool gauge continues says so when both sources are listed", {
  both <- wet_station_list()
  prov <- wet_station_list("bcenv")
  r <- both[both$station_number == "08HB0008", ]
  p <- prov[prov$station_number == "08HB0008", ]
  cut <- wet_bcwatertool_stations()$continues_before[wet_bcwatertool_stations()$station_number == "4602"]
  expect_lte(cut, p$first)
  expect_lt(r$first, p$first)
  expect_equal(format(r$first, "%Y"), "2012")
  expect_equal(r$last, p$last)
  expect_equal(r$licence, paste0("OGL-BC 2.0; days before ", cut, ": none stated"))
  expect_match(r$credit, paste0("; days before ", cut, ": Data from BC Conservation Foundation"), fixed = TRUE)
  # every other provincial row is as the provincial list gives it
  moved <- both$station_number[both$source == "bcenv"][
    both$first[both$source == "bcenv"] != prov$first | both$credit[both$source == "bcenv"] != prov$credit]
  # Tofino's four listings are the same gauges as 08HC0001-0004 and add no day; Hakai's package continues
  # its three Calvert and Hecate island watersheds
  expect_setequal(stats::na.omit(moved), c("08HB0008", "08HB0011", "08HB0012", "H08KC0626", "H08KC0703",
                                           "H08KC0844"))
})

test_that("a continued provincial station with no complete day takes the listing's first and last days", {
  local_mocked_bindings(
    wet_station_regulation = function(snapshot) {
      data.frame(station_number = "08ZZ0001", source = "bcenv", regulation = "unknown")
    },
    wet_bcenv_stations = function(snapshot) {
      data.frame(station_number = "08ZZ0001", name = "Alpha", lon = -124, lat = 49, first = as.Date(NA),
                 last = as.Date(NA), regulation = "unknown", hydat_site = NA_character_, hydat_km = NA_real_)
    },
    wet_bcwatertool_stations = function(snapshot = "20261028") {
      data.frame(station_number = "4601", name = "Alpha", network = "Test", lon = -124, lat = 49,
                 first = as.Date("2012-08-17"), last = as.Date("2015-11-10"), regulation = "unknown",
                 hydat_site = NA_character_, hydat_km = NA_real_, credit = "Data from BCCF.",
                 continues = "08ZZ0001", continues_before = as.Date("2021-09-30"), bcenv_snapshot = "20261028",
                 bcenv_days = wet_bcenv_days_key("20261028"))
    })
  s <- wet_station_list(c("bcenv", "bcwatertool"))
  expect_equal(nrow(s), 1)
  expect_equal(c(s$first, s$last), as.Date(c("2012-08-17", "2015-11-10")))
  expect_s3_class(s$last, "Date")
  expect_equal(s$credit, paste0("Contains information licensed under the Open Government Licence \u2013 British ",
                                "Columbia; days before 2021-09-30: Data from BCCF."))
})

test_that("stations at a HYDAT site name it, within 1 km", {
  s <- wet_station_list("bcenv")
  at <- s[!is.na(s$hydat_site), ]
  # the survey's 57 same-site stations and 1 duplicate (#123)
  expect_equal(nrow(at), 58)
  expect_true(all(grepl("^[0-9]{2}[A-Z]{2}[0-9]{3}$", at$hydat_site)))
  expect_true(all(at$hydat_km <= 1))
  expect_true(all(is.na(s$hydat_km[is.na(s$hydat_site)])))
  expect_equal(s$hydat_site[s$station_number == "08NM0015"], "08NM116")
  t <- wet_station_list("bcwatertool")
  expect_true(all(t$hydat_km[!is.na(t$hydat_site)] <= 1))
})

test_that("bad arguments are refused", {
  expect_error(wet_station_list("usgs"), "some of")
  expect_error(wet_station_list(character()), "some of")
  expect_error(wet_station_list(snapshot = "19000101"), "no tracked manifest")
})

# The regulation status (#196): every station has one, from the status file shipped beside the registries.
status_file <- function() {
  utils::read.csv(system.file("extdata", "station_sources", "regulation_20261028.csv", package = "wet"),
                  na.strings = "", colClasses = "character")
}

test_that("every station's regulation comes from the status file, and a natural one was snapped", {
  s <- wet_station_list()
  r <- status_file()
  expect_setequal(r$station_number, s$station_number)
  expect_equal(s$regulation, r$regulation[match(s$station_number, r$station_number)])
  expect_equal(r$source[match(s$station_number, r$station_number)], s$source)
  expect_false(anyNA(r$why) || any(!nzchar(r$why)))
  # a natural station sits on an accepted snap, with flow, no regulating dam and shares under 10 %
  nat <- r[r$regulation == "natural", ]
  expect_gt(nrow(nat), 0)
  expect_false(anyNA(nat$linear_feature_id) || anyNA(nat$snap_leg))
  expect_true(all(nat$dams_up == "0" & as.numeric(nat$L_share) < 0.1 & as.numeric(nat$S_share) < 0.1))
  expect_true(all(nat$outside_bc == "FALSE" & nat$power_up == "FALSE" & nat$novol_up == "FALSE"))
  # no licence record rides in the file: only computed columns
  expect_false(any(grepl("LICENCE|POD|QUANTITY", names(r), ignore.case = FALSE)))
})

test_that("a station regulated by name stays regulated", {
  s <- wet_station_list()
  named <- grepl("\\b(dam|diversions?|reservoir|intake|spillway|pump|canal|ditch|pumphouse)\\b", tolower(s$name))
  expect_gt(sum(named), 0)
  expect_true(all(s$regulation[named] == "regulated"))
})

test_that("the status file is refused when it does not match the registries or the vocabulary", {
  path <- system.file("extdata", "station_sources", "regulation_20261028.csv", package = "wet")
  r <- utils::read.csv(path, na.strings = "", colClasses = "character")
  local_status <- function(x) {
    dir <- withr::local_tempdir(.local_envir = parent.frame())
    dir.create(file.path(dir, "extdata", "station_sources"), recursive = TRUE)
    for (f in c("bcenv_20261028_hydat.csv", "bcwatertool_20261028_hydat.csv", "hakai_8318556d2baf.csv",
                "hakai_8318556d2baf_hydat.csv")) {
      file.copy(system.file("extdata", "station_sources", f, package = "wet"),
                file.path(dir, "extdata", "station_sources", f))
    }
    utils::write.csv(x, file.path(dir, "extdata", "station_sources", "regulation_20261028.csv"),
                     row.names = FALSE, na = "")
    dir
  }
  read_with <- function(x) {
    dir <- local_status(x)
    local_mocked_bindings(wet_station_sources_path = function(f) {
      p <- file.path(dir, "extdata", "station_sources", f)
      if (file.exists(p)) p else ""
    })
    wet_station_list()
  }
  expect_no_error(read_with(r))
  # a station missing
  expect_error(read_with(r[r$station_number != "08HB0008", ]), "no bcenv row for 08HB0008")
  # a status left empty, or outside the vocabulary
  x <- r
  x$regulation[1] <- NA
  expect_error(read_with(x), "each natural, regulated or unknown")
  x$regulation[1] <- "regulated by name"
  expect_error(read_with(x), "each natural, regulated or unknown")
  # built from another registry
  x <- r
  x$bcenv_registry_md5 <- "00000000000000000000000000000000"
  expect_error(read_with(x), "built from other station registries")
  x <- r
  x$bcenv_snapshot[2] <- "20261027"
  expect_error(read_with(x), "built from other station registries")
  # the Hakai registry is held too
  x <- r
  x$hakai_registry_md5 <- "00000000000000000000000000000000"
  expect_error(read_with(x), "built from other station registries")
  x <- r
  x$hakai_version <- "000000000000"
  expect_error(read_with(x), "built from other station registries")
  # no status file for the snapshot
  local_mocked_bindings(wet_station_sources_path = function(f) "")
  expect_error(wet_station_regulation("20261028"), "write it with scripts/station_regulation.R")
})

test_that("Hakai's own watersheds are listed as stations, and a continued station says so", {
  local_mocked_bindings(
    wet_station_regulation = function(snapshot) {
      data.frame(station_number = c("08ZZ0001", "WTS9002"), source = c("bcenv", "hakai"),
                 regulation = c("unknown", "natural"))
    },
    wet_bcenv_stations = function(snapshot) {
      data.frame(station_number = "08ZZ0001", name = "Alpha", lon = -128, lat = 51.6,
                 first = as.Date("2021-10-01"), last = as.Date("2026-10-27"), regulation = "unknown",
                 hydat_site = NA_character_, hydat_km = NA_real_)
    },
    wet_hakai_stations = function(version = "8318556d2baf") {
      data.frame(station_number = c("WTS9001", "WTS9002"), watershed = c("9001", "9002"), name = c("Test", "Own"),
                 lon = c(-128, -128.1), lat = c(51.6, 51.7), continues = c("08ZZ0001", NA),
                 continues_before = as.Date(c("2021-10-01", NA)), first = as.Date(c("2014-08-02", "2014-09-01")),
                 last = as.Date(c("2019-09-30", "2019-09-29")), licence = "CC-BY 4.0",
                 credit = "Hakai Institute et al.", bcenv_snapshot = "20261028",
                 bcenv_days = wet_bcenv_days_key("20261028"))
    })
  s <- wet_station_list("hakai")
  expect_equal(s$station_number, "WTS9002")
  expect_named(s, names(wet_station_list("bcenv")))
  expect_equal(s$source, "hakai")
  expect_equal(s$network, "Hakai Institute")
  expect_equal(c(s$first, s$last), as.Date(c("2014-09-01", "2019-09-29")))
  expect_equal(s$regulation, "natural")
  expect_true(is.na(s$hydat_site) && is.na(s$hydat_km))
  expect_equal(s$licence, "CC-BY 4.0")
  expect_equal(s$credit, "Hakai Institute et al.")
  expect_s3_class(s$first, "Date")
  p <- wet_station_list(c("bcenv", "hakai"))
  expect_equal(p$station_number, c("08ZZ0001", "WTS9002"))
  expect_equal(p$source, c("bcenv", "hakai"))
  expect_equal(c(p$first[1], p$last[1]), as.Date(c("2014-08-02", "2026-10-27")))
  expect_equal(p$licence[1], "OGL-BC 2.0; days before 2021-10-01: CC-BY 4.0")
  expect_match(p$credit[1], "; days before 2021-10-01: Hakai Institute et al.", fixed = TRUE)
  # an own station the status file does not hold under "hakai" is refused
  wrong_source <- function(snapshot) {
    data.frame(station_number = c("08ZZ0001", "WTS9002"), source = "bcenv", regulation = "unknown")
  }
  local_mocked_bindings(wet_station_regulation = wrong_source)
  expect_error(wet_station_list("hakai"), "no hakai row for WTS9002")
})
