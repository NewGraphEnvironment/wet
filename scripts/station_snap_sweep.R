# What fwapg's fwa_indexpoint() rework (fwapg#41) changes on wet's own path
# (#127): the station snap (wet_station_snap()) and the catchment cut at the
# snapped measure (fwa_watershedatmeasure(), as scripts/vignette_map_lib.R
# does), over the shipped release's calibration and test stations and the
# stations the vignette maps draw.
#
#   WET_FWAPG_MIGRATION_COMMIT=b088b43 Rscript scripts/station_snap_sweep.R <migration.sql>
#
# The migration file is fwapg's, e.g.
#   git -C <fwapg> show b088b43:db/migrations/202610240132__indexpoint_tiebreak.sql > <file>
# and WET_FWAPG_MIGRATION_COMMIT names the commit it came from, for the report.
#
# The sweep runs twice, each on its own connection and in its own transaction:
# on the database as it is, then with the migration applied inside a
# transaction that is rolled back (wet_pg_trial()), so the database is never
# migrated. The run refuses to start on a database that already has the
# migration, and checks after the rollback, on a third connection, that the old
# fwa_indexpoint() is back. Every database call runs under its own savepoint
# and a statement timeout, so a call that errors or hangs is counted and the
# sweep goes on; an error outside a savepoint stops the run.
#
# Writes the tracked report wb_report("station_snap_sweep", release), and both
# sweeps to data/snap_sweep/station_snap_sweep_<release>.rds (gitignored).
# HYDAT (for the vignette stations) is the release WET_HYDAT_RELEASE names, as
# for the stations file. Connection from the WET_PG* env vars.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat(), wb_stations_path(), wb_report()
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)

migration <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(migration) || !file.exists(migration)) stop("usage: station_snap_sweep.R <migration.sql>", call. = FALSE)
# one copy, read once: the trial, the md5 and the report's check all use it, so
# a file rewritten during the run cannot be credited with the counts
migration_name <- basename(migration)
migration <- file.path(tempdir(), migration_name)
stopifnot(file.copy(commandArgs(trailingOnly = TRUE)[1], migration))
migration_md5 <- unname(tools::md5sum(migration))
commit <- Sys.getenv("WET_FWAPG_MIGRATION_COMMIT")
if (!grepl("^[0-9a-f]{7,40}$", commit)) {
  stop("set WET_FWAPG_MIGRATION_COMMIT to the fwapg commit the migration file came from", call. = FALSE)
}
tolerance <- 1000
num_features <- 5
timeout <- "300s"  # per statement; the largest catchments take about 11 s
vignette <- c("08EE013", "08EE003", "08EE004")  # station-flow and monthly-flow maps
release <- wb_release()
out_txt <- wb_report("station_snap_sweep", release)
out_rds <- file.path("data", "snap_sweep", sprintf("station_snap_sweep_%s.rds", release))

# ---- stations ------------------------------------------------------------------------------
need <- c("station_number", "lon", "lat", "drainage_area_gross_km2")
sts <- readRDS(wb_stations_path(release))
st <- rbind(cbind(sts$stations[, need], set = "calibration"), cbind(sts$test[, need], set = "test"))
extra <- setdiff(vignette, st$station_number)
if (length(extra)) {
  con <- wet_hydat_connect(wb_hydat(release))
  v <- DBI::dbGetQuery(con, sprintf("
    SELECT STATION_NUMBER AS station_number, LONGITUDE AS lon, LATITUDE AS lat,
           DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
    FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", extra, "'", collapse = ", ")))
  DBI::dbDisconnect(con)
  stopifnot(setequal(v$station_number, extra))
  st <- rbind(st, cbind(v[, need], set = "vignette"))
}
st <- st[order(st$station_number), ]
stopifnot(!anyDuplicated(st$station_number))
rownames(st) <- NULL

connect <- function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("WET_PGHOST", "localhost"),
    port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
    dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
    user = Sys.getenv("WET_PGUSER", "postgres"),
    password = Sys.getenv("WET_PGPASSWORD", "postgres")
  )
}
# `conn` is the connection the sweep functions below use: one per run
conn <- connect()
indexpoint_args <- function() {
  DBI::dbGetQuery(conn, "SELECT pg_get_function_arguments('whse_basemapping.fwa_indexpoint'::regproc) AS a")$a
}
old_args <- indexpoint_args()
if (grepl("include_disconnected", old_args)) {
  stop("this database already has the reworked fwa_indexpoint(): there is no before to measure", call. = FALSE)
}
# the base the trial is applied on: does fwa_watershedatmeasure() still read
# hydrosheds and NHD (fwapg's migration 202610131654 not applied)?
exbc <- grepl("exbc", DBI::dbGetQuery(conn, "SELECT pg_get_functiondef(
  'whse_basemapping.fwa_watershedatmeasure(integer, double precision)'::regprocedure) AS d")$d)

# One query under a savepoint: its rows, or the error's message as a string
try_sql <- function(sql) {
  DBI::dbExecute(conn, "SAVEPOINT sweep")
  r <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) conditionMessage(e))
  DBI::dbExecute(conn, if (is.character(r)) "ROLLBACK TO SAVEPOINT sweep" else "RELEASE SAVEPOINT sweep")
  r
}
pt_sql <- function(i) sprintf("ST_Transform(ST_SetSRID(ST_MakePoint(%.10f, %.10f), 4326), 3005)", st$lon[i], st$lat[i])
first_line <- function(x) sub("\n.*", "", x)

# ---- one sweep ------------------------------------------------------------------------------
sweep <- function(label) {
  stamp(label, ": candidates")
  cand <- list()
  idx_err <- character()
  for (i in seq_len(nrow(st))) {
    r <- try_sql(sprintf("
      SELECT c.linear_feature_id::double precision AS linear_feature_id, c.blue_line_key,
             c.downstream_route_measure AS measure, c.distance_to_stream AS distance_m
      FROM whse_basemapping.fwa_indexpoint(%s, %f, %d) c", pt_sql(i), tolerance, num_features))
    if (is.character(r)) {
      idx_err[st$station_number[i]] <- first_line(r)
      next
    }
    if (nrow(r)) cand[[length(cand) + 1]] <- cbind(station_number = st$station_number[i], r)
  }
  cand <- do.call(rbind, cand)
  # fwa_locatealong() at every candidate's measure
  loc <- vapply(seq_len(nrow(cand)), function(k) {
    r <- try_sql(sprintf("SELECT count(*)::integer AS n FROM whse_basemapping.fwa_locatealong(%d, %.17g)",
                         cand$blue_line_key[k], cand$measure[k]))
    if (is.character(r)) paste("error:", first_line(r)) else as.character(r$n)
  }, "")
  cand$locatealong <- loc

  stamp(label, ": wet_station_snap()")
  snap <- try_sql_snap(st[, need])

  stamp(label, ": picked positions")
  i <- match(paste(snap$station_number, snap$linear_feature_id), paste(cand$station_number, cand$linear_feature_id))
  pick <- data.frame(station_number = snap$station_number, linear_feature_id = snap$linear_feature_id,
                     blue_line_key = cand$blue_line_key[i], measure = cand$measure[i],
                     gross_km2 = st$drainage_area_gross_km2[match(snap$station_number, st$station_number)])
  pick <- pick[!is.na(pick$blue_line_key), ]
  pick$locatealong <- cand$locatealong[match(paste(pick$station_number, pick$linear_feature_id),
                                             paste(cand$station_number, cand$linear_feature_id))]
  ws <- lapply(seq_len(nrow(pick)), function(k) {
    r <- try_sql(sprintf("SELECT count(*)::integer AS n, sum(area_ha)::double precision / 100 AS km2
                          FROM whse_basemapping.fwa_watershedatmeasure(%d, %.17g)",
                         pick$blue_line_key[k], pick$measure[k]))
    if (is.character(r)) data.frame(ws_rows = NA_integer_, ws_km2 = NA_real_, ws_error = first_line(r))
    else data.frame(ws_rows = r$n, ws_km2 = r$km2, ws_error = "")
  })
  pick <- cbind(pick, do.call(rbind, ws))
  # the border crossing fwa_watershedatmeasure()'s area outside BC hangs on,
  # where the base still reads it (A1 in the plan review)
  pick$border <- vapply(seq_len(nrow(pick)), function(k) {
    r <- try_sql(sprintf("SELECT whse_basemapping.fwa_upstreambordercrossings(%d, %.17g) AS b",
                         pick$blue_line_key[k], pick$measure[k]))
    if (is.character(r)) paste("error:", first_line(r)) else if (is.na(r$b)) "" else r$b
  }, "")
  list(cand = cand, idx_err = idx_err, snap = snap, pick = pick)
}

# wet_station_snap() on some stations, or the message of the first error it
# raised: its on.exit() drops a temp table, which fails in the aborted
# transaction and would otherwise replace the real cause
snap_or_message <- function(x) {
  first <- NULL
  tryCatch(withCallingHandlers(wet_station_snap(conn, x), error = function(e) {
    if (is.null(first)) first <<- conditionMessage(e)
  }), error = function(e) if (is.null(first)) conditionMessage(e) else first)
}

# wet_station_snap() on every station at once, as wb_stations.R runs it; if
# that errors, one station at a time, so the error is placed and counted
try_sql_snap <- function(x) {
  DBI::dbExecute(conn, "SAVEPOINT snap")
  r <- snap_or_message(x)
  if (!is.character(r)) {
    DBI::dbExecute(conn, "RELEASE SAVEPOINT snap")
    r$error <- ""
    return(r)
  }
  DBI::dbExecute(conn, "ROLLBACK TO SAVEPOINT snap")
  stamp("  wet_station_snap() on all stations errored (", first_line(r), "); one at a time")
  do.call(rbind, lapply(seq_len(nrow(x)), function(i) {
    DBI::dbExecute(conn, "SAVEPOINT snap")
    s <- snap_or_message(x[i, ])
    if (is.character(s)) {
      DBI::dbExecute(conn, "ROLLBACK TO SAVEPOINT snap")
      none <- data.frame(station_number = character(), linear_feature_id = numeric(), distance_m = numeric(),
                         watershed_feature_id = integer(), wscode = character(), localcode = character(),
                         upstream_area_km2 = numeric())
      s <- cbind(wet:::wet_snap_pick(x[i, ], none, 0.1), lake = NA, error = first_line(s))
    } else {
      DBI::dbExecute(conn, "RELEASE SAVEPOINT snap")
      s$error <- ""
    }
    s
  }))
}

# Ties: two segments of one candidate stream at exactly that stream's least
# distance from the station (and within 1e-6 m, for float noise), over the
# segments fwa_indexpoint() considers (not edge type 6010) and the streams it
# returned, with the raw distance (it returns distance rounded to 3 decimals).
# Geometry only, so the migration cannot change it; measured once.
ties <- function(cand) {
  do.call(rbind, lapply(seq_len(nrow(st)), function(i) {
    blk <- unique(cand$blue_line_key[cand$station_number == st$station_number[i]])
    if (!length(blk)) return(NULL)
    r <- try_sql(sprintf("
      WITH d AS (
        SELECT s.blue_line_key, s.linear_feature_id, ST_Distance(s.geom, %s) AS dist
        FROM whse_basemapping.fwa_stream_networks_sp s
        WHERE s.blue_line_key IN (%s) AND s.edge_type != 6010 AND ST_DWithin(s.geom, %s, %f)),
      m AS (SELECT blue_line_key, min(dist) AS dmin FROM d GROUP BY 1)
      SELECT d.blue_line_key, count(*) FILTER (WHERE d.dist = m.dmin)::integer AS n_exact,
             count(*) FILTER (WHERE d.dist - m.dmin <= 1e-6)::integer AS n_near,
             string_agg(d.linear_feature_id::text, ' ' ORDER BY d.linear_feature_id)
               FILTER (WHERE d.dist - m.dmin <= 1e-6) AS segments
      FROM d JOIN m USING (blue_line_key)
      GROUP BY 1 HAVING count(*) FILTER (WHERE d.dist - m.dmin <= 1e-6) > 1",
      pt_sql(i), paste(blk, collapse = ", "), pt_sql(i), tolerance))
    if (is.character(r)) stop("tie query failed for ", st$station_number[i], ": ", r, call. = FALSE)
    if (nrow(r)) cbind(station_number = st$station_number[i], r)
  }))
}

# A captured message saying the transaction is aborted means an error escaped a
# savepoint and every later call failed for that reason: the counts are wrong
check_aborted <- function(s) {
  m <- c(s$idx_err, s$cand$locatealong, s$pick$ws_error, s$pick$border, s$snap$error)
  if (any(grepl("current transaction is aborted", m))) stop("the run's transaction was aborted", call. = FALSE)
  s
}

DBI::dbBegin(conn)
DBI::dbExecute(conn, sprintf("SET LOCAL statement_timeout = '%s'", timeout))
before <- check_aborted(sweep("before"))
tie <- ties(before$cand)
DBI::dbRollback(conn)
DBI::dbDisconnect(conn)

run_trial <- function() {
  wet_pg_trial(conn, migration)  # rolled back when run_trial() returns
  DBI::dbExecute(conn, sprintf("SET LOCAL statement_timeout = '%s'", timeout))
  stopifnot(grepl("include_disconnected", indexpoint_args()))
  check_aborted(sweep("after"))
}
conn <- connect()
after <- run_trial()
DBI::dbDisconnect(conn)
conn <- connect()
back_args <- indexpoint_args()
DBI::dbDisconnect(conn)
if (!identical(back_args, old_args)) {
  stop("after the rollback fwa_indexpoint() reads (", back_args, "), not the old (", old_args, ")", call. = FALSE)
}
stamp("rolled back; fwa_indexpoint() is the old one again")

dir.create(dirname(out_rds), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(stations = st, before = before, after = after, ties = tie, migration = migration_name,
             release = release,
             migration_md5 = migration_md5, commit = commit, exbc = exbc), out_rds)

# ---- report --------------------------------------------------------------------------------
count_cand <- function(s) {
  c(n = nrow(s$cand), empty = sum(s$cand$locatealong == "0"), error = sum(startsWith(s$cand$locatealong, "error")))
}
count_pick <- function(s) {
  c(n = nrow(s$pick), loc_empty = sum(s$pick$locatealong == "0"),
    loc_error = sum(startsWith(s$pick$locatealong, "error")),
    ws_empty = sum(s$pick$ws_rows %in% 0L), ws_error = sum(nzchar(s$pick$ws_error)),
    ws_10 = sum(abs(s$pick$ws_km2 / s$pick$gross_km2 - 1) <= 0.1, na.rm = TRUE))
}
cb <- count_cand(before)
ca <- count_cand(after)
pb <- count_pick(before)
pa <- count_pick(after)
row <- function(lab, b, a) sprintf("%-78s %7s %7s", lab, b, a)

# the same candidate (station, segment) on both sides: how far its measure moved
same <- merge(before$cand, after$cand, by = c("station_number", "linear_feature_id"), suffixes = c("_b", "_a"))
dm <- abs(same$measure_a - same$measure_b)

cols <- c("linear_feature_id", "watershed_feature_id", "upstream_area_km2", "accepted", "lake")
sb <- before$snap[order(before$snap$station_number), ]
sa <- after$snap[order(after$snap$station_number), ]
stopifnot(identical(sb$station_number, sa$station_number))
moved <- lapply(cols, function(k) which(!mapply(identical, sb[[k]], sa[[k]])))
names(moved) <- cols
changed <- sort(unique(unlist(moved)))

pk <- merge(before$pick, after$pick, by = "station_number", suffixes = c("_b", "_a"), all = TRUE)
ws_state <- function(rows, err, km2, gross) {
  state <- ifelse(rows == 0L, "empty", sprintf("%.1f km2 (%.3f)", km2, km2 / gross))
  state[is.na(rows)] <- "no pick"
  state[!is.na(err) & nzchar(err)] <- "error"
  state
}
pk$ws_b <- ws_state(pk$ws_rows_b, pk$ws_error_b, pk$ws_km2_b, pk$gross_km2_b)
pk$ws_a <- ws_state(pk$ws_rows_a, pk$ws_error_a, pk$ws_km2_a, pk$gross_km2_a)
pk$loc_b <- pk$locatealong_b
pk$loc_a <- pk$locatealong_a
pk$border <- ifelse(is.na(pk$border_b), "", pk$border_b)
pk_moved <- pk[pk$ws_b != pk$ws_a | !mapply(identical, pk$loc_b, pk$loc_a) |
                 !mapply(identical, pk$linear_feature_id_b, pk$linear_feature_id_a), ]
err_msgs <- function(s) {
  m <- c(unname(s$idx_err), sub("^error: ", "", s$cand$locatealong[startsWith(s$cand$locatealong, "error")]),
         s$pick$ws_error[nzchar(s$pick$ws_error)], s$snap$error[nzchar(s$snap$error)])
  if (!length(m)) return("none")
  t <- table(m)
  sprintf("%d x %s", as.integer(t), names(t))
}
tie_pick <- function(s) {
  if (is.null(tie) || !nrow(tie)) return(character())
  x <- merge(tie, s$cand[, c("station_number", "blue_line_key", "linear_feature_id", "locatealong")],
             by = c("station_number", "blue_line_key"))
  x <- x[order(x$station_number, x$blue_line_key), ]
  picked <- paste(x$station_number, x$blue_line_key) %in% paste(s$pick$station_number, s$pick$blue_line_key)
  sprintf("%s blk %d: segments %s -> %.0f (locatealong %s)%s", x$station_number, x$blue_line_key,
          x$segments, x$linear_feature_id, x$locatealong, ifelse(picked, ", the picked stream", ""))
}
n_tie_picked <- function(s) {
  if (is.null(tie)) return(0L)
  length(unique(intersect(paste(tie$station_number, tie$blue_line_key),
                          paste(s$pick$station_number, s$pick$blue_line_key))))
}

# stations whose returned streams differ: the outer order is now the raw
# distance and then the segment id, not the rounded distance (G12)
streams <- function(s) tapply(s$cand$blue_line_key, s$cand$station_number, function(b) paste(sort(b), collapse = " "))
stb <- streams(before)
sta <- streams(after)
ids <- sort(union(names(stb), names(sta)))
stream_moved <- ids[!mapply(identical, stb[ids], sta[ids])]

# the before run against the stations file wb_stations.R wrote: whether the
# database moved since, which would mix with the migration's effect (AC2)
filed <- rbind(sts$stations[, c("station_number", "linear_feature_id", "watershed_feature_id", "accepted")],
               sts$test[, c("station_number", "linear_feature_id", "watershed_feature_id", "accepted")])
filed <- filed[filed$station_number %in% sb$station_number, ]
j <- match(filed$station_number, sb$station_number)
same_value <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
drift <- filed$station_number[!(same_value(filed$linear_feature_id, sb$linear_feature_id[j]) &
                                  same_value(filed$watershed_feature_id, sb$watershed_feature_id[j]) &
                                  same_value(filed$accepted, sb$accepted[j]))]

border_err <- before$pick$border[startsWith(before$pick$border, "error")]
border_b <- before$pick$border[!startsWith(before$pick$border, "error")]

# the issue's own check on the body the trial ran
stripped <- strsplit(wet_pg_trial_sql(paste(readLines(migration, warn = FALSE), collapse = "\n")), "\n")[[1]]
grep_hits <- grep("^(BEGIN|COMMIT|ROLLBACK);", stripped)
fmt_snap <- function(s, i) {
  sprintf("%.0f / %s / %.1f km2 / %s / lake %s%s", s$linear_feature_id[i], s$watershed_feature_id[i],
          s$upstream_area_km2[i], ifelse(s$accepted[i], "accepted", "rejected"), s$lake[i],
          ifelse(nzchar(s$error[i]), paste0(" / error ", s$error[i]), ""))
}

lines <- c(
  "# wet_station_snap() before and after fwapg's fwa_indexpoint() rework (#127)", "",
  sprintf("Migration: %s (md5 %s), fwapg commit %s (fwapg#41, PR fwapg#43)", migration_name,
          migration_md5, commit),
  "Applied inside a transaction and rolled back; fwa_indexpoint() read the old signature after the rollback.",
  sprintf("Base: fwa_watershedatmeasure() %s.", if (exbc) {
    "still reads hydrosheds and NHD for area outside BC (fwapg's migration 202610131654 not applied)"
  } else {
    "has no exbc branch (fwapg's migration 202610131654 applied)"
  }),
  sprintf("Issue's check, grep -nE '^(BEGIN|COMMIT|ROLLBACK);' on the body the trial ran: %s.",
          if (length(grep_hits)) paste("lines", paste(grep_hits, collapse = ", ")) else "no lines"),
  sprintf(paste("Stations: HYDAT %s calibration %d and test %d (%s), and %d more the vignette maps draw (%s);",
                "snapped with tolerance %d m, %d candidates."),
          release, sum(st$set == "calibration"), sum(st$set == "test"), wb_stations_path(release),
          sum(st$set == "vignette"), paste(st$station_number[st$set == "vignette"], collapse = ", "),
          tolerance, num_features),
  sprintf("Before run against the stations file (segment, watershed, accepted): %d of %d differ%s.",
          length(drift), nrow(filed), if (length(drift)) paste0(" (", paste(drift, collapse = ", "), ")") else ""),
  sprintf("Picked positions with an upstream border crossing, where the base's area outside BC applies: %d (%s).",
          sum(nzchar(border_b)), paste(sort(unique(border_b[nzchar(border_b)])), collapse = ", ")),
  sprintf(paste("fwa_upstreambordercrossings(), run for that flag on the database as it is, errored at %d picked",
                "positions%s."), length(border_err),
          if (length(border_err)) paste0(": ", paste(sprintf("%d x %s", as.integer(table(border_err)),
                                                            sub("^error: ", "", names(table(border_err)))),
                                                    collapse = "; ")) else ""),
  "", "## Counts", "",
  row("", "before", "after"),
  row("fwa_indexpoint() calls that error", length(before$idx_err), length(after$idx_err)),
  row("candidates", cb["n"], ca["n"]),
  row("candidates where fwa_locatealong() at the measure returns nothing", cb["empty"], ca["empty"]),
  row("candidates where fwa_locatealong() errors", cb["error"], ca["error"]),
  row("wet_station_snap() stations with a pick", pb["n"], pa["n"]),
  row("  picked position: fwa_locatealong() returns nothing", pb["loc_empty"], pa["loc_empty"]),
  row("  picked position: fwa_locatealong() errors", pb["loc_error"], pa["loc_error"]),
  row("  picked position: fwa_watershedatmeasure() returns nothing", pb["ws_empty"], pa["ws_empty"]),
  row("  picked position: fwa_watershedatmeasure() errors", pb["ws_error"], pa["ws_error"]),
  row("  picked position: watershed within 10 % of HYDAT's gross area", pb["ws_10"], pa["ws_10"]),
  row("wet_station_snap() accepted", sum(sb$accepted), sum(sa$accepted)),
  "",
  sprintf("Stations whose %d returned streams changed: %d%s.", num_features, length(stream_moved),
          if (length(stream_moved)) paste0(" (", paste(stream_moved, collapse = ", "), ")") else ""),
  sprintf("Same candidate (station, segment) on both sides: %d; its measure moved by at most %.3g m (median %.3g m).",
          nrow(same), max(dm), stats::median(dm)),
  "", "## Errors by message", "", "before:", paste0("  ", err_msgs(before)), "after:", paste0("  ", err_msgs(after)),
  "", sprintf(paste("## Streams tied on two segments at the station (geometry; %d exact, %d within 1e-6 m,",
                    "at %d stations; on the picked stream: %d before, %d after)"),
              if (is.null(tie)) 0L else sum(tie$n_exact > 1), if (is.null(tie)) 0L else nrow(tie),
              if (is.null(tie)) 0L else length(unique(tie$station_number)), n_tie_picked(before), n_tie_picked(after)),
  "", "before:", paste0("  ", tie_pick(before)), "after:", paste0("  ", tie_pick(after)),
  "", sprintf("## wet_station_snap() output that changed (%d stations)", length(changed)), "",
  sprintf("%s: %d", names(moved), lengths(moved)),
  "", "station   segment / watershed / upstream area / accepted / lake, before -> after",
  if (length(changed)) sprintf("%s  %s\n          -> %s", sb$station_number[changed], fmt_snap(sb, changed),
                               fmt_snap(sa, changed)),
  "", sprintf("## Picked positions whose segment, fwa_locatealong() or watershed changed (%d)", nrow(pk_moved)), "",
  paste("station   segment before -> after; locatealong before -> after; watershed (share of gross)",
        "before -> after; upstream border crossing (before)"),
  if (nrow(pk_moved)) sprintf("%s  %.0f -> %.0f; %s -> %s; %s -> %s; %s", pk_moved$station_number,
                              pk_moved$linear_feature_id_b, pk_moved$linear_feature_id_a, pk_moved$loc_b,
                              pk_moved$loc_a, pk_moved$ws_b, pk_moved$ws_a,
                              ifelse(nzchar(pk_moved$border), pk_moved$border, "none"))
)
writeLines(lines, out_txt)
stamp("wrote ", out_txt, " and ", out_rds)
