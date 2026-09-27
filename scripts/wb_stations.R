# HYDAT stations for the open water balance (#11): select, summarise, snap.
#
#   Rscript scripts/wb_stations.R
#
# Writes data/wb/stations.rds (gitignored; the station table later phases
# read) and the tracked report data/checks/stations_wb.txt.
# Connection from WET_PG* env vars.

devtools::load_all(quiet = TRUE)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
years <- 1981:2010
min_years <- 10
dir.create("data/wb", recursive = TRUE, showWarnings = FALSE)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)

# ---- selection, and what it leaves out -----------------------------------------------
hydat <- wet:::wet_hydat_path()
st <- wet_station_select(hydat, years = years, min_years = min_years)
con <- wet:::wet_hydat_connect(hydat)
flag <- DBI::dbGetQuery(con, "
  SELECT s.STATION_NUMBER station_number, r.REGULATED regulated
  FROM STATIONS s LEFT JOIN STN_REGULATION r USING (STATION_NUMBER)
  WHERE s.PROV_TERR_STATE_LOC = 'BC'")
# stations with any daily flow in the window, to count what the rules drop
active <- DBI::dbGetQuery(con, sprintf("
  SELECT DISTINCT STATION_NUMBER station_number FROM DLY_FLOWS
  WHERE YEAR BETWEEN %d AND %d", min(years), max(years)))$station_number
hydat_release <- DBI::dbGetQuery(con, "SELECT Date FROM VERSION")$Date[1]
DBI::dbDisconnect(con)
flag <- flag[flag$station_number %in% active, ]
n_reg <- sum(flag$regulated %in% 1)
n_unknown <- sum(is.na(flag$regulated))
natural <- flag$station_number[flag$regulated %in% 0]
# natural stations with a record in the window but no complete year (seasonal
# gauges and gappy records), or too few
loose <- wet_station_select(hydat, years = years, min_years = 1)
n_seasonal <- sum(!natural %in% loose$station_number)
n_short <- sum(natural %in% loose$station_number & !natural %in% st$station_number)
stamp(nrow(st), " stations selected")

# ---- monthly climatology and snapping ------------------------------------------------------
mon <- wet_station_monthly(st, hydat)
sn <- wet_station_snap(conn, st)
DBI::dbDisconnect(conn)
st <- merge(st, sn, by = "station_number", sort = TRUE)
st$subsubdrainage <- substr(st$station_number, 1, 4)  # WSC sub-sub-drainage, e.g. 08MF
saveRDS(list(stations = st, monthly = mon, years = years), "data/wb/stations.rds")
stamp(sum(st$accepted), " snapped within 10 %")

# ---- report --------------------------------------------------------------------------------
acc <- st[st$accepted, ]
q <- stats::quantile(acc$area_ratio, c(0, 0.1, 0.5, 0.9, 1))
tab <- function(x) paste(sprintf("%s %d", names(x), as.integer(x)), collapse = ", ")
con <- file("data/checks/stations_wb.txt", "w")
writeLines(c(
  "# HYDAT stations for the open water balance (#11)", "",
  sprintf("HYDAT release: %s", hydat_release),
  sprintf("window %d-%d; complete year = 12 months each with >= 20 days of flow; >= %d complete years",
          min(years), max(years), min_years), "",
  "## Selection (BC stations with daily flow in the window)",
  sprintf("regulated (flag 1): %d", n_reg),
  sprintf("no regulation record (left out): %d", n_unknown),
  sprintf("natural, no complete year in the window (seasonal or gappy record): %d", n_seasonal),
  sprintf("natural, fewer than %d complete years: %d", min_years, n_short),
  sprintf("selected: %d", nrow(st)), "",
  "## Snapping (fwa_indexpoint, 5 candidates within 1 km, picked by drainage area)",
  sprintf("accepted (area within +/- 10 %%): %d", nrow(acc)),
  sprintf("rejected: %d", sum(!st$accepted)),
  sprintf("area ratio of accepted, min / p10 / median / p90 / max: %s",
          paste(sprintf("%.3f", q), collapse = " / ")),
  sprintf("accepted lake outlets (lake >= 100 ha within 3 km, upstream on the network, draining 50-110 %% of the gauge's area): %d",
          sum(acc$lake, na.rm = TRUE)),
  "", sprintf("## Accepted by WSC sub-sub-drainage (%d; in %d sub-drainages)",
              length(unique(acc$subsubdrainage)), length(unique(substr(acc$station_number, 1, 3)))),
  tab(table(acc$subsubdrainage)),
  "", "## Rejected snaps (station, gross km2, reason)",
  sprintf("%s  %9.1f  %s", st$station_number[!st$accepted],
          st$drainage_area_gross_km2[!st$accepted], st$reason[!st$accepted])
), con)
close(con)
stamp("report written")
