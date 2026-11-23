# Two provincial hourly files in the real format (#142): a header ending in
# CRLF, data rows ending in LF, a station name holding byte 0x96, UTC times,
# grades per hour, l/s and m^3/s, NaN. Days below are local standard time.
#
# 08ZZ0001 (Pacific, UTC-8), in Discharge.csv:
#   2020-06-02  24 graded hours of 2            -> 2, provisional
#   2020-06-03  20 hours of 3, one Undefined    -> 3, unchecked
#   2020-06-04  19 hours of 3                   -> too few hours
#   2020-06-05  23 hours of 4, one Unusable 1000 -> 4
#   2020-06-06  23 hours of 5, one NaN          -> 5
#   2020-06-07  24 hours of 1e6                 -> above any sane bound
#   2020-06-08  24 hours of -1                  -> negative
#   2020-06-09  24 hours of 6000 l/s            -> 6
# 07ZZ0001 (Peace, UTC-7), in Discharge.csv: 2020-06-02, its first hour 25 and 23 hours of 1 -> 2;
#   at UTC-8 the first hour would fall on 2020-06-01 and the day would read 1.
# The archive repeats 08ZZ0001's 2020-06-02 at 99 (the newer file wins), and
# alone holds 08ZZ0002's 2020-06-02 at 7 with Unspecified hours and 08ZZ0003's
# 2020-06-02 at 8 with one Unverified hour.
bcenv_fixture_rows <- function(id, name, day, hours, value, unit = "m^3/s", grade = "RISC A", offset = 8) {
  t <- as.POSIXct(paste(day, "00:00:00"), tz = "UTC") + (offset + hours) * 3600
  sprintf("%s,%s,Active,49.1,-123.1,%s,Discharge,%s,%s,%s", id, name, format(t, "%Y-%m-%d %H:%M:%S", tz = "UTC"),
          value, unit, grade)
}

bcenv_fixture <- function(dir) {
  a <- "08ZZ0001"
  na <- "Alpha Creek ~DASH~ upper"
  g3 <- rep("RISC A", 20)
  g3[5] <- "Undefined"
  g5 <- rep("RISC A", 24)
  g5[7] <- "Unusable"
  v5 <- rep("4.000", 24)
  v5[7] <- "1000.000"
  v6 <- rep("5.000", 24)
  v6[3] <- "NaN"
  new <- c(
    bcenv_fixture_rows(a, na, "2020-06-02", 0:23, "2.000"),
    bcenv_fixture_rows(a, na, "2020-06-03", 0:19, "3.000", grade = g3),
    bcenv_fixture_rows(a, na, "2020-06-04", 0:18, "3.000"),
    bcenv_fixture_rows(a, na, "2020-06-05", 0:23, v5, grade = g5),
    bcenv_fixture_rows(a, na, "2020-06-06", 0:23, v6),
    bcenv_fixture_rows(a, na, "2020-06-07", 0:23, "1000000.000"),
    bcenv_fixture_rows(a, na, "2020-06-08", 0:23, "-1.000"),
    bcenv_fixture_rows(a, na, "2020-06-09", 0:23, "6000.000", unit = "l/s"),
    bcenv_fixture_rows("07ZZ0001", "Peace Creek", "2020-06-02", 0:23, c("25.000", rep("1.000", 23)), grade = "RISC B",
                       offset = 7))
  old <- c(
    bcenv_fixture_rows(a, na, "2020-06-02", 0:23, "99.000"),
    bcenv_fixture_rows("08ZZ0002", "Beta Creek", "2020-06-02", 0:23, "7.000", grade = "Unspecified"),
    bcenv_fixture_rows("08ZZ0003", "Gamma Creek", "2020-06-02", 0:23, "8.000",
                       grade = c("Unverified", rep("Good", 23))))
  head <- "Location ID, Location Name, Status, Latitude, Longitude, Date/Time(UTC), Parameter, Value, Unit, Grade\r\n"
  write <- function(rows, file) {
    b <- charToRaw(paste0(head, paste0(rows, "\n", collapse = "")))
    # "~DASH~" becomes the single byte 0x96
    s <- rawToChar(b)
    parts <- strsplit(s, "~DASH~", fixed = TRUE)[[1]]
    out <- charToRaw(parts[1])
    for (p in parts[-1]) out <- c(out, as.raw(0x96), charToRaw(p))
    writeBin(out, file.path(dir, file))
  }
  write(new, "Discharge.csv")
  write(old, "Discharge_Archive_Pre_20151001.csv")
  file.path(dir, c("Discharge.csv", "Discharge_Archive_Pre_20151001.csv"))
}

# A temporary cache whose snapshot is the fixture: wet_bcenv() stands in.
local_bcenv_fixture <- function(env = parent.frame()) {
  cache <- withr::local_tempdir(.local_envir = env)
  raw <- withr::local_tempdir(.local_envir = env)
  paths <- bcenv_fixture(raw)
  local_mocked_bindings(wet_bcenv = function(snapshot = "20261028", cache_dir = NULL) paths, .env = env)
  list(cache = cache, paths = paths)
}
