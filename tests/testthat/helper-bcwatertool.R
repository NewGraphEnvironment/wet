# Water Tool CSVs in the real format (#144): a block of "# key,value" lines
# with blank lines between, then Analysis,Datetime,Value,Units,QA.
#
# Listing 101 (registry number "TST1"):
#   Primary Water Level 2020-06-01         -> ignored, not discharge
#   2020-06-01  2      QA 1                -> 2, provisional
#   2020-06-02  3      QA 0                -> 3, unchecked
#   2020-06-03  blank  QA 1                -> no value, as the survey read it
#   2020-06-04  -1     QA 1                -> negative, dropped
#   2020-06-05  1e6    QA 1                -> above any sane bound, dropped
#   2020-06-06  4      QA 1                -> 4, provisional
# Listing 102 (registry number "4601", continuing provincial 08ZZ0001, whose
# record begins 2021-10-01):
#   2012-08-17 .. 2012-08-19 at 1, 2, 3, QA 1; 2021-10-02 at 5, QA 1
bcwatertool_fixture_lines <- function(rows, licence = "Data from Test District. https://example.org/.") {
  disclaimer <- "Any reliance you place upon the information contained here is your sole responsibility."
  c(sprintf('# Data Licence Information,"%s %s"', licence, disclaimer),
    "",
    "# Name,Alpha Creek",
    "# Network,Test Network",
    '# QA,"1 - Quality Checked, 0 - Unchecked Quality"',
    "",
    "Analysis,Datetime,Value,Units,QA",
    rows)
}

bcwatertool_fixture_101 <- c(
  "Primary Water Level,2020-06-01,5.135,m,1",
  "Preliminary Discharge,2020-06-01,2.0,m3/s,1",
  "Preliminary Discharge,2020-06-02,3.0,m3/s,0",
  "Preliminary Discharge,2020-06-03,,m3/s,1",
  "Preliminary Discharge,2020-06-04,-1.0,m3/s,1",
  "Preliminary Discharge,2020-06-05,1000000,m3/s,1",
  "Preliminary Discharge,2020-06-06,4.0,m3/s,1")

bcwatertool_fixture_102 <- c(
  "Preliminary Discharge,2012-08-17,1,m3/s,1",
  "Preliminary Discharge,2012-08-18,2,m3/s,1",
  "Preliminary Discharge,2012-08-19,3,m3/s,1",
  "Preliminary Discharge,2021-10-02,5,m3/s,1")

# A snapshot of two listings, a station list and one .status listing under a
# temporary cache, with a manifest of their md5s standing in for the tracked
# one, and a registry standing in for the tracked one.
local_bcwatertool_cache <- function(env = parent.frame()) {
  cache <- withr::local_tempdir(.local_envir = env)
  dir <- file.path(cache, "station_sources", "bcwatertool", "20261028")
  dir.create(dir, recursive = TRUE)
  writeLines(bcwatertool_fixture_lines(bcwatertool_fixture_101), file.path(dir, "101.csv"))
  writeLines(bcwatertool_fixture_lines(bcwatertool_fixture_102), file.path(dir, "102.csv"))
  writeLines("HTTP 500", file.path(dir, "103.csv.status"))
  writeLines("{}", file.path(dir, "bcwatertool_streamflow_stations_20261028.geojson"))
  f <- list.files(dir, full.names = TRUE)
  man <- data.frame(file = basename(f), bytes = file.size(f), md5 = unname(tools::md5sum(f)))
  reg <- data.frame(station_number = c("4601", "TST1"), id = c("102", "101"), name = c("Grandon", "Alpha Creek"),
                    network = "Test Network", lon = -124, lat = 49.5, subdrainage = "08H",
                    nearest_hydat = "08HB001", nearest_km = 1, first = as.Date(c("2012-08-17", "2020-06-01")),
                    last = as.Date(c("2012-08-19", "2020-06-06")), regulation = "unknown", hydat_site = NA_character_,
                    hydat_km = NA_real_, credit = c("Data from BCCF.", "Data from Test District."),
                    continues = c("08ZZ0001", NA), continues_before = as.Date(c("2021-10-01", NA)),
                    bcenv_snapshot = "20261028", bcenv_days = wet_bcenv_days_key("20261028"))
  local_mocked_bindings(wet_bcwatertool_manifest = function(snapshot) man,
                        wet_bcwatertool_stations = function(snapshot = "20261028") reg, .env = env)
  list(cache = cache, dir = dir, man = man, reg = reg)
}
