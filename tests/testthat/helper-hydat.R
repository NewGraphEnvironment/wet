# A tiny HYDAT with the three tables the station functions read.
# Station flows are constant within a month and equal to the month number,
# except where a test knocks days out. Symbols are NA except the ones set below.
local_hydat <- function(env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".sqlite3", .local_envir = env)
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  on.exit(DBI::dbDisconnect(con))
  DBI::dbWriteTable(con, "STATIONS", data.frame(
    STATION_NUMBER = c("08AA001", "08AA002", "08AA003", "08AA004", "09AA001"),
    STATION_NAME = c("NATURAL", "REGULATED", "NO RECORD", "SEASONAL", "YUKON"),
    PROV_TERR_STATE_LOC = c("BC", "BC", "BC", "BC", "YT"),
    LATITUDE = c(54, 54.1, 54.2, 54.3, 60.5), LONGITUDE = c(-127, -127.1, -127.2, -127.3, -135),
    DRAINAGE_AREA_GROSS = c(100, 200, 300, 400, 500)))
  DBI::dbWriteTable(con, "STN_REGULATION", data.frame(
    STATION_NUMBER = c("08AA001", "08AA002", "08AA004", "09AA001"),
    YEAR_FROM = NA_integer_, YEAR_TO = NA_integer_, REGULATED = c(0L, 1L, 0L, 0L)))
  dim_of <- function(y, m) as.integer(format(as.Date(sprintf("%d-%02d-01", y, m %% 12 + 1)) - 1, "%d"))
  rows <- list()
  add <- function(st, y, months) {
    for (m in months) {
      r <- data.frame(STATION_NUMBER = st, YEAR = y, MONTH = m)
      fl <- rep(NA_real_, 31)
      fl[seq_len(dim_of(y, m))] <- m
      r[sprintf("FLOW%d", 1:31)] <- as.list(fl)
      r[sprintf("FLOW_SYMBOL%d", 1:31)] <- as.list(rep(NA_character_, 31))
      rows[[length(rows) + 1]] <<- r
    }
  }
  for (st in c("08AA001", "08AA002", "08AA003", "09AA001")) for (y in 1980:1984) add(st, y, 1:12)
  for (y in 1980:1984) add("08AA004", y, 5:10)
  d <- do.call(rbind, rows)
  # 08AA001 in 1984: July keeps only 19 days, so 1984 is not a complete year
  i <- d$STATION_NUMBER == "08AA001" & d$YEAR == 1984 & d$MONTH == 7
  d[i, sprintf("FLOW%d", 20:31)] <- NA
  # 08AA001 in 1982: March loses 5 days, still complete (26 >= 20)
  i <- d$STATION_NUMBER == "08AA001" & d$YEAR == 1982 & d$MONTH == 3
  d[i, sprintf("FLOW%d", 1:5)] <- NA
  # 08AA001: January 1981 is under ice, and 15 June 1983 is estimated
  i <- d$STATION_NUMBER == "08AA001" & d$YEAR == 1981 & d$MONTH == 1
  d[i, sprintf("FLOW_SYMBOL%d", 1:31)] <- "B"
  i <- d$STATION_NUMBER == "08AA001" & d$YEAR == 1983 & d$MONTH == 6
  d[i, "FLOW_SYMBOL15"] <- "E"
  # a value in FLOW30 of February 1983, a day that does not exist
  i <- d$STATION_NUMBER == "08AA001" & d$YEAR == 1983 & d$MONTH == 2
  d[i, "FLOW30"] <- 99
  DBI::dbWriteTable(con, "DLY_FLOWS", d)
  path
}
