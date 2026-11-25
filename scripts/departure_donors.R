# Natural stations outside HYDAT as departure donors (#211, #202): the held-out
# test of scripts/departure_donors_rule.R, whose header is the rule. That file
# was committed before this one existed, and this script refuses to run when
# it differs from its registering commit (an amendment moves rule_commit).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_donors.R
#
# Run a frozen copy (cp scripts/departure_donors.R "$TMPDIR/d.R" && Rscript
# "$TMPDIR/d.R") from the repository root. Reads HYDAT 20260717 (approved
# days), the provincial and BC Water Tool snapshots 20261028 from wet's cache
# (provisional and unchecked days), and fwapg through the WET_PG* variables
# (connect_timeout 10 s; no fwapg, no run): each station's upstream area and
# watershed codes at the segment the regulation run placed it on, and the
# HYDAT gauges' snaps behind the leak-free pool. Inputs are cached under
# <WET_DATA_ROOT>/departure_donors/<key>/ (WET_DATA_ROOT defaults to data/),
# the key the md5 of the release, the snapshot, the rule file, the running
# script, the windows file, the station registries and regulation file, and
# wet's R code. It does not cover the fwapg database or the installed
# packages: after either changes, remove the cache before a rerun. Extensions
# are fitted per held-out gauge and never cached.
#
# Writes the tracked report data/checks/departure_donors_20260717_20261028.txt
# (no timestamp, so a rerun writes it byte for byte) and
# <cache>/results.rds. Nothing is published, no site report or fit is read or
# touched.
#
# Stops, beyond the rule's own refusals, when: a scored year carries a
# station's extended value; a gauge whose box holds no candidate gets two
# different carries; the held-out gauge, or in the leak-free pool a gauge or
# station related to it, reaches an extension chain or a carry's donors; or
# the pools at 08KA012 and 08KE014 differ from the counts lines of the Swift
# and Naver site reports (so the box and pools are scripts/departure_site.R's).

pkgload::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/departure_donors_rule.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S "), ...)

# ---- the rule as registered ---------------------------------------------------------------------
rule_file <- "scripts/departure_donors_rule.R"
rule_commit <- "a7455e45363078872ccc0a2a3ae564120b718a43"
rule_md5 <- local({
  tmp <- tempfile()
  st <- system2("git", c("show", paste0(rule_commit, ":", rule_file)), stdout = tmp, stderr = FALSE)
  if (!identical(st, 0L)) stop("cannot read ", rule_file, " at the rule's registering commit ", rule_commit, call. = FALSE)
  reg <- unname(tools::md5sum(tmp))
  now <- unname(tools::md5sum(rule_file))
  if (!identical(reg, now)) {
    stop(rule_file, " differs from the rule's registering commit ", substr(rule_commit, 1, 8),
         ": an amendment is dated in the rule file and this commit moved with it", call. = FALSE)
  }
  now
})

release <- wb_release()
if (release != dd_release) stop("the rule names HYDAT ", dd_release, ", not ", release, call. = FALSE)
if (wet_bcenv_snapshot != dd_snapshot || wet_bcwatertool_snapshot != dd_snapshot) {
  stop("the rule names station snapshot ", dd_snapshot, call. = FALSE)
}
hydat <- wb_hydat(release)
report <- file.path("data", "checks", sprintf("departure_donors_%s_%s.txt", release, dd_snapshot))
# the key: the release (HYDAT's file, whose VERSION wb_hydat() checks), the snapshot, the rule,
# the running script (its SQL, day status and gauge selection), the windows file, the station
# registries and regulation file, and wet's R code (the readers, window statistics and snap).
# Not fwapg or the installed packages (the header says so). Rscript writes a space as ~+~.
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || !file.exists(self)) stop("run with Rscript, so the running script can be hashed", call. = FALSE)
key_files <- c(self, file.path("inst", "vignette-data", "life_history_bulk.csv"),
               sort(list.files(file.path("inst", "extdata", "station_sources"), full.names = TRUE), method = "radix"),
               sort(list.files("R", pattern = "[.]R$", full.names = TRUE), method = "radix"))
key <- substr(digest::digest(paste(c(release, dd_snapshot, rule_md5, unname(tools::md5sum(key_files))),
                                   collapse = " "),
                             algo = "md5", serialize = FALSE), 1, 10)
cache <- file.path(Sys.getenv("WET_DATA_ROOT", "data"), "departure_donors", key)
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
cached <- function(name, expr) {
  f <- file.path(cache, paste0(name, ".rds"))
  if (file.exists(f)) return(readRDS(f))
  v <- expr
  tmp <- paste0(f, ".tmp")
  saveRDS(v, tmp)
  if (!file.rename(tmp, f)) stop("cannot write ", f, call. = FALSE)
  v
}
fmt <- function(x, d = 3) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
rsort <- function(x) sort(x, method = "radix")

# ---- windows (the Bulkley chinook migration and spawning windows) -------------------------------
lh <- utils::read.csv(file.path("inst", "vignette-data", "life_history_bulk.csv"), stringsAsFactors = FALSE)
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
stopifnot(identical(lh$life_stage, c("migration", "spawning")))
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stats <- c("mean", "min7", "max", "cov_day")
# wet_station_daily() turns a failing source into a warning and no rows: stop on that, so a
# missing or altered cache file cannot drop a network silently; its other warnings are muffled
daily_or_stop <- function(...) {
  withCallingHandlers(wet_station_daily(...), warning = function(w) {
    if (grepl("^source \".*\" skipped", conditionMessage(w))) {
      stop("a source failed: ", conditionMessage(w), call. = FALSE)
    }
    invokeRestart("muffleWarning")
  })
}
cols <- c("station_number", "variable", "period", "year", "value")

# ---- HYDAT: natural BC gauges, approved days ----------------------------------------------------
hy <- cached("hydat_stations", local({   # local(): on.exit() needs a frame
  con <- wet:::wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con))
  DBI::dbGetQuery(con, "
    SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.LONGITUDE lon,
           s.LATITUDE lat, s.DRAINAGE_AREA_GROSS drainage_area_gross_km2, r.REGULATED regulated
    FROM STATIONS s JOIN STN_REGULATION r USING (STATION_NUMBER)
    WHERE s.PROV_TERR_STATE_LOC = 'BC'
    ORDER BY s.STATION_NUMBER")
}))
nat <- hy[hy$regulated == 0 & !is.na(hy$lon) & !is.na(hy$lat) & !is.na(hy$drainage_area_gross_km2), ]
ws_h <- cached("hydat_window_stats", {
  stamp("reading HYDAT days for ", nrow(nat), " natural BC gauges")
  d <- daily_or_stop(nat$station_number, hydat, to = NULL, sources = "hydat")
  w <- wet_window_stats(d, windows, stats = stats)
  w[order(w$station_number, w$variable, w$period, w$year, method = "radix"), cols]
})
ws_h_by <- split(ws_h, ws_h$station_number)
n_mig_h <- vapply(nat$station_number, function(s) {
  w <- ws_h_by[[s]]
  if (is.null(w)) 0L else sum(w$variable == "q_mean" & w$period == "migration")
}, 0L)

# ---- outside HYDAT: natural stations, provisional and unchecked days ----------------------------
sl <- wet_station_list()
st_o <- sl[sl$regulation %in% "natural", c("station_number", "name", "lon", "lat", "source", "regulation", "hydat_site")]
st_o <- st_o[order(st_o$station_number, method = "radix"), ]
rownames(st_o) <- NULL
o_data <- cached("outside_window_stats", {
  stamp("reading days for ", nrow(st_o), " natural stations outside HYDAT")
  d <- daily_or_stop(st_o$station_number, hydat, to = NULL, sources = c("bcenv", "bcwatertool"))
  w <- wet_window_stats(d, windows, stats = stats)
  # a window-year's day status: any and every day with a value inside the window unchecked
  d$unchk <- ifelse(is.na(d$q_m3s), NA_real_, as.numeric(d$status %in% "unchecked"))
  u <- wet_window_stats(d[c("station_number", "date", "unchk")], windows, stats = c("min", "max"), value = "unchk")
  u <- stats::reshape(u[c("station_number", "period", "year", "variable", "value")], direction = "wide",
                      idvar = c("station_number", "period", "year"), timevar = "variable")
  names(u) <- sub("^value\\.", "", names(u))
  w <- merge(w[cols], u, by = c("station_number", "period", "year"), all.x = TRUE, sort = FALSE)
  w <- w[order(w$station_number, w$variable, w$period, w$year, method = "radix"), ]
  rownames(w) <- NULL
  list(ws = w, days = data.frame(table(source = d$source, status = d$status, useNA = "ifany")),
       n_days = nrow(d), first = tapply(d$date, d$station_number, min))
})
ws_o <- o_data$ws
if (anyNA(ws_o$q_max) || anyNA(ws_o$q_min)) stop("a station window-year has no day status", call. = FALSE)
ws_o$any_unchecked <- ws_o$q_max == 1
ws_o$all_unchecked <- ws_o$q_min == 1

# ---- fwapg: station areas and codes, HYDAT snaps ------------------------------------------------
reg <- utils::read.csv(file.path("inst", "extdata", "station_sources", sprintf("regulation_%s.csv", dd_snapshot)),
                       stringsAsFactors = FALSE, colClasses = c(station_number = "character"))
st_o$linear_feature_id <- reg$linear_feature_id[match(st_o$station_number, reg$station_number)]
connect <- function() {
  DBI::dbConnect(RPostgres::Postgres(),
                 host = Sys.getenv("WET_PGHOST", "localhost"),
                 port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                 dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                 user = Sys.getenv("WET_PGUSER", "postgres"),
                 password = Sys.getenv("WET_PGPASSWORD", "postgres"),
                 connect_timeout = 10)
}
fw <- cached("fwapg", local({
  conn <- connect()
  on.exit(DBI::dbDisconnect(conn))
  ids <- st_o$linear_feature_id[!is.na(st_o$linear_feature_id)]
  lk <- DBI::dbGetQuery(conn, sprintf("
    SELECT l.linear_feature_id::double precision AS linear_feature_id,
           w.wscode_ltree::text AS wscode, w.localcode_ltree::text AS localcode,
           u.upstream_area_ha / 100 AS upstream_area_km2
    FROM whse_basemapping.fwa_streams_watersheds_lut l
    JOIN whse_basemapping.fwa_watersheds_poly w USING (watershed_feature_id)
    LEFT JOIN whse_basemapping.fwa_watersheds_upstream_area u USING (watershed_feature_id)
    WHERE l.linear_feature_id IN (%s)
    ORDER BY l.linear_feature_id", paste(sprintf("%.0f", ids), collapse = ",")))
  if (anyDuplicated(lk$linear_feature_id)) stop("a station segment has two watershed polygons", call. = FALSE)
  pool_ids <- nat$station_number[n_mig_h >= dd_min_years]
  stamp("snapping ", length(pool_ids), " HYDAT gauges")
  sn <- wet_station_snap(conn, nat[nat$station_number %in% pool_ids, c("station_number", "lon", "lat",
                                                                       "drainage_area_gross_km2")])
  list(lookup = lk, snap = sn[order(sn$station_number, method = "radix"),
                              c("station_number", "wscode", "localcode", "accepted")])
}))
lk <- fw$lookup[match(st_o$linear_feature_id, fw$lookup$linear_feature_id), ]
st_o$drainage_area_gross_km2 <- lk$upstream_area_km2
st_o$wscode <- lk$wscode
st_o$localcode <- lk$localcode
sn <- fw$snap
st_o$hydat_flag <- hy$regulated[match(st_o$hydat_site, hy$station_number)]
st_o$n_mig <- vapply(st_o$station_number, function(s) {
  sum(ws_o$station_number == s & ws_o$variable == "q_mean" & ws_o$period == "migration")
}, 0L)

# ---- one test run -------------------------------------------------------------------------------
combos <- expand.grid(variable = c("q_mean", "q_min7", "q_cov_day", "q_max"), period = c("migration", "spawning"),
                      stringsAsFactors = FALSE)
combos <- combos[order(match(combos$variable, c("q_mean", "q_min7", "q_cov_day", "q_max")), combos$period), ]
held_ids <- nat$station_number[n_mig_h >= dd_min_years]   # only these can be in their own box pool

# related to g: box-pool gauges with accepted snaps and stations, upstream or downstream of g
related_of <- function(g, box_ids, cand_st) {
  sg <- sn[sn$station_number == g, ]
  if (!nrow(sg) || !isTRUE(sg$accepted)) return(character())
  rel <- function(ws, lc) {
    wet:::wet_fwa_upstream(sg$wscode, sg$localcode, ws, lc) |
      vapply(seq_along(ws), function(i) wet:::wet_fwa_upstream(ws[i], lc[i], sg$wscode, sg$localcode), TRUE)
  }
  sb <- sn[sn$station_number %in% setdiff(box_ids, g) & sn$accepted %in% TRUE, ]
  out <- sb$station_number[rel(sb$wscode, sb$localcode) %in% TRUE]
  if (nrow(cand_st)) out <- c(out, cand_st$station_number[rel(cand_st$wscode, cand_st$localcode) %in% TRUE])
  rsort(out)
}

# The whole test under one configuration. `xo` the stations' window statistics,
# `combos_run` the statistics and windows, `k` the carry's, `min_fit5` the
# sensitivity's fit-year floor, `exclude` a function(st, box) returning the
# stations to leave out of candidacy, `all_gauges` whether a gauge whose box holds
# no candidate is run (the main run, for the identity assertion) or only counted.
run_test <- function(xo, combos_run, k = dd_k, min_fit5 = FALSE, exclude = NULL, all_gauges = TRUE, label = "") {
  st <- st_o
  st$n_mig <- vapply(st$station_number, function(s) {
    sum(xo$station_number == s & xo$variable == "q_mean" & xo$period == "migration")
  }, 0L)
  xo_by <- split(xo[cols], xo$station_number)
  out <- list()
  n_g <- 0
  for (g in held_ids) {
    n_g <- n_g + 1
    if (n_g %% 100 == 0) stamp(label, ": gauge ", n_g, " of ", length(held_ids))
    gi <- nat[nat$station_number == g, ]
    box <- dd_box(gi$lon, gi$lat)
    ids <- nat$station_number[dd_in_box(nat$lon, nat$lat, box)]
    wsb <- do.call(rbind, ws_h_by[intersect(ids, names(ws_h_by))])
    pools <- dd_pools(wsb, ids)
    if (!g %in% pools$box) stop(g, " has 3 migration years but is not in its own box pool", call. = FALSE)
    is_cand <- dd_candidate(st, g, box)
    # dd_candidate() reads these columns, and a missing one gives a zero-length answer, not an error
    if (length(is_cand) != nrow(st) ||
        !all(c("regulation", "lon", "lat", "drainage_area_gross_km2", "n_mig", "hydat_site") %in% names(st))) {
      stop("dd_candidate() was not given its columns", call. = FALSE)
    }
    if (!is.null(exclude)) is_cand <- is_cand & !st$station_number %in% exclude(st, pools$box)
    cand_st <- st[is_cand, ]
    cand <- cand_st$station_number
    st_tab <- rbind(nat[nat$station_number %in% pools$box, c("station_number", "lon", "lat", "drainage_area_gross_km2")],
                    cand_st[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
    xh <- wsb[wsb$station_number %in% pools$box, ]
    xo_g <- if (length(cand)) do.call(rbind, xo_by[intersect(cand, names(xo_by))]) else xo[0, cols]
    if (is.null(xo_g)) xo_g <- xo[0, cols]
    rel <- related_of(g, pools$box, cand_st)
    for (i in seq_len(nrow(combos_run))) {
      v <- combos_run$variable[i]
      p <- combos_run$period[i]
      if (!g %in% pools$dep(v, p)) next
      xo_v <- xo_g
      if (min_fit5 && nrow(xo_v)) {
        keep <- vapply(split(xo_v, xo_v$station_number), function(d) {
          d <- d[d$variable == v & d$period == p, ]
          length(dd_fit_years(d$year, d$value, v)) >= 5
        }, TRUE)
        xo_v <- xo_v[!(xo_v$variable == v & xo_v$period == p & xo_v$station_number %in% names(keep)[!keep]), ]
      }
      for (pool in c("loo", "leakfree")) {
        drop <- if (pool == "loo") character() else rel
        id <- paste(g, v, p, pool, sep = "|")
        if (!length(cand) && !all_gauges) {
          out[[id]] <- list(gauge = g, variable = v, period = p, pool = pool, scored = FALSE, reason = "no candidate",
                            years = integer(0), rmse = c(without = NA_real_, with = NA_real_), diff = NA_real_,
                            n_cand = 0L)
          next
        }
        r <- dd_gauge(g, v, p, xh, xo_v, st_tab, cand, pools$ext, pools$dep(v, p), drop = drop, k = k)
        r$pool <- pool
        r$n_cand <- length(cand)
        r$drop <- drop
        r$ext_chains <- r$eligible$chain[!is.na(r$eligible$chain)]
        # ---- the asserted invariants -------------------------------------------------------------
        if (!length(cand) && !identical(r$without, r$with)) {
          stop(id, ": no candidate, yet the two carries differ", call. = FALSE)
        }
        names_used <- c(unlist(strsplit(r$ext_chains, " ", fixed = TRUE)),
                        unlist(lapply(c(r$without$donors, r$with$donors), dd_donor_ids)))
        if (g %in% names_used) stop(id, ": the held-out gauge reaches a chain or a donor list", call. = FALSE)
        if (length(drop) && any(drop %in% names_used)) {
          stop(id, ": a related gauge or station reaches a chain or a donor list", call. = FALSE)
        }
        for (y in r$years) {
          used <- intersect(dd_donor_ids(r$with$donors[r$with$year == y]), cand)
          src <- r$rows$source[r$rows$station_number %in% used & r$rows$year == y]
          if (length(src) != length(used) || any(src != "observed")) {
            stop(id, ": a scored year ", y, " carries a station value that is not observed", call. = FALSE)
          }
        }
        if (!length(cand)) r$without <- r$with <- r$obs <- NULL   # identical and unscored: not kept
        out[[id]] <- r
      }
    }
  }
  out
}

# ---- parity with the site script's pools --------------------------------------------------------
parity_gauges <- c(swift = "08KA012", naver = "08KE014")
parity <- vapply(names(parity_gauges), function(site) {
  g <- parity_gauges[[site]]
  line <- grep("^Box pool \\(>= 3 complete migration years\\)",
               readLines(file.path("data", "checks", sprintf("departure_site_%s_bulk_%s.txt", site, release))),
               value = TRUE)
  if (length(line) != 1) stop("no single counts line in the ", site, " site report", call. = FALSE)
  # "...years): 30. Extension pool (>= 30 and a 5-year run): 11. Departure pool (...): 13. ..."
  want <- as.integer(regmatches(line, regexec(
    "\\): ([0-9]+)\\. Extension pool[^:]*: ([0-9]+)\\. Departure pool[^:]*: ([0-9]+)\\.", line))[[1]][2:4])
  gi <- nat[nat$station_number == g, ]
  box <- dd_box(gi$lon, gi$lat)
  ids <- nat$station_number[dd_in_box(nat$lon, nat$lat, box)]
  pools <- dd_pools(do.call(rbind, ws_h_by[intersect(ids, names(ws_h_by))]), ids)
  got <- c(length(pools$box), length(pools$ext), length(pools$dep("q_mean", "migration")))
  if (!identical(got, want)) {
    stop(g, ": pools ", paste(got, collapse = ", "), " differ from the ", site, " site report's ",
         paste(want, collapse = ", "), call. = FALSE)
  }
  paste(got, collapse = ", ")
}, "")

# ---- the runs -----------------------------------------------------------------------------------
stamp("main run")
main <- run_test(ws_o, combos, label = "main")
mig <- combos[combos$variable == "q_mean" & combos$period == "migration", ]
sens_defs <- list(
  list(label = "stations with at least 5 fit years only", args = list(min_fit5 = TRUE)),
  list(label = "window-years with no unchecked day only", args = list(xo = ws_o[!ws_o$any_unchecked, ])),
  list(label = "the carry's k = 3", args = list(k = 3)),
  list(label = "the carry's k = 8", args = list(k = 8)),
  list(label = "without the stations at a HYDAT site whose gauge is in the box pool or regulated",
       args = list(exclude = function(st, box_ids) {
         st$station_number[!is.na(st$hydat_site) & (st$hydat_site %in% box_ids | st$hydat_flag %in% 1)]
       })))
sens <- lapply(sens_defs, function(s) {
  stamp("sensitivity: ", s$label)
  a <- list(xo = ws_o, combos_run = mig, all_gauges = FALSE, label = s$label)
  a[names(s$args)] <- s$args   # not modifyList(), which merges a data frame column by column
  do.call(run_test, a)
})
saveRDS(list(main = main, sens = sens, rule_commit = rule_commit, rule_md5 = rule_md5), file.path(cache, "results.rds"))

# ---- summaries ----------------------------------------------------------------------------------
as_rows <- function(res) {
  if (!length(res)) return(data.frame(gauge = character(), variable = character(), period = character(),
                                      pool = character(), scored = logical(), reason = character(),
                                      n_years = integer(), rmse_without = numeric(), rmse_with = numeric(),
                                      diff = numeric(), n_cand = integer()))
  d <- do.call(rbind, lapply(res, function(r) {
    data.frame(gauge = r$gauge, variable = r$variable, period = r$period, pool = r$pool, scored = r$scored,
               reason = r$reason, n_years = length(r$years), rmse_without = r$rmse[["without"]],
               rmse_with = r$rmse[["with"]], diff = r$diff, n_cand = r$n_cand)
  }))
  rownames(d) <- NULL
  d[order(d$variable, d$period, d$pool, d$gauge, method = "radix"), ]
}
boot_ci <- function(d) {
  if (length(d) < 2) return(c(NA_real_, NA_real_))
  set.seed(dd_seed)
  m <- vapply(seq_len(dd_n_boot), function(i) stats::median(sample(d, length(d), replace = TRUE)), 0)
  stats::quantile(m, c(0.05, 0.95), names = FALSE)
}
q3 <- function(x) if (length(x)) stats::quantile(x, c(0.25, 0.5, 0.75), names = FALSE) else rep(NA_real_, 3)
verdict_of <- function(rows) {
  s <- rows[rows$variable == "q_mean" & rows$period == "migration" & rows$scored, ]
  loo <- s$diff[s$pool == "loo"]
  lf <- s$diff[s$pool == "leakfree"]
  c(dd_ship(if (length(loo)) stats::median(loo) else NA_real_, if (length(lf)) stats::median(lf) else NA_real_,
            length(loo), length(lf)), list(n_loo = length(loo), n_lf = length(lf),
                                           med_loo = if (length(loo)) stats::median(loo) else NA_real_,
                                           med_lf = if (length(lf)) stats::median(lf) else NA_real_))
}
mrows <- as_rows(main)
verdict <- verdict_of(mrows)
srows <- lapply(sens, as_rows)

out <- character()
say <- function(...) out <<- c(out, ...)
lab <- function(v, p) sprintf("%s %s", p, sub("^q_", "", v))

say("# Natural stations outside HYDAT as departure donors: the held-out test (#211, #202)", "",
    sprintf("HYDAT %s (approved days); station snapshot %s (provisional and unchecked days alike).", release, dd_snapshot),
    sprintf("Rule: the header of %s, registered at %s; rule file md5 %s.", rule_file, substr(rule_commit, 1, 8), rule_md5),
    "Windows: the Bulkley chinook migration (05-01..08-01) and spawning (08-01..09-15) windows; a complete window-year at min_frac 0.8; baseline 1981-2010.",
    "")

# ---- 1. the population ------------------------------------------------------------------------
mw <- ws_o[ws_o$variable == "q_mean" & ws_o$period == "migration", ]
n_by <- table(factor(mw$station_number, levels = st_o$station_number))
n_by24 <- table(factor(mw$station_number[mw$year <= dd_fit_last], levels = st_o$station_number))
n_base <- table(factor(mw$station_number[mw$year %in% dd_baseline], levels = st_o$station_number))
returns_days <- sum(st_o$station_number %in% names(o_data$first))
hist_line <- function(tab) {
  h <- table(as.integer(tab))
  paste(sprintf("%s at %d", names(h), as.integer(h)), collapse = ", ")
}
seen <- c(stations = 75, ge3 = 36, ge3_2024 = 33, base10 = 0, window_years = 185, all_unchecked = 58)
here <- c(stations = nrow(st_o), ge3 = sum(n_by >= 3), ge3_2024 = sum(n_by24 >= 3), base10 = sum(n_base >= 10),
          window_years = nrow(mw), all_unchecked = sum(mw$all_unchecked))
dec <- table(paste0(floor(mw$year / 10) * 10, "s"))
wb <- ws_o[ws_o$year %in% dd_baseline & dd_usable(ws_o$value, ws_o$variable), ]
base_all <- if (nrow(wb)) as.vector(table(paste(wb$station_number, wb$variable, wb$period))) else 0L
max_base_all <- max(c(0L, base_all))
say("## 1. The population", "",
    sprintf("Natural stations outside HYDAT (wet_station_list(), regulation \"natural\"): %d (provincial %d, Water Tool %d); %d return days.",
            nrow(st_o), sum(st_o$source == "bcenv"), sum(st_o$source == "bcwatertool"), returns_days),
    sprintf("Days returned: %d. By source and status: %s.", o_data$n_days,
            paste(sprintf("%s %s %d", o_data$days$source, o_data$days$status, o_data$days$Freq)[o_data$days$Freq > 0],
                  collapse = "; ")),
    sprintf("Complete migration window-years (mean) per station: %s. At least 3: %d; at least 5: %d; at least 10: %d.",
            hist_line(n_by), sum(n_by >= 3), sum(n_by >= 5), sum(n_by >= 10)),
    sprintf("Through %d: at least 3: %d; at least 5: %d.", dd_fit_last, sum(n_by24 >= 3), sum(n_by24 >= 5)),
    sprintf("In 1981-2010, per station: %s. With at least 10 (a baseline): %d.", hist_line(n_base), sum(n_base >= 10)),
    sprintf("In 1981-2010, over every statistic and window: the most usable window-years any station holds is %d; with at least 10: %d.",
            max_base_all, sum(base_all >= 10)),
    sprintf("Window-years: %d; by decade %s. Every day unchecked in %d, every day provisional in %d, mixed in %d.",
            nrow(mw), paste(sprintf("%s %d", names(dec), as.integer(dec)), collapse = ", "), sum(mw$all_unchecked),
            sum(!mw$any_unchecked), sum(mw$any_unchecked & !mw$all_unchecked)),
    sprintf("With an upstream area at the placed segment (fwapg): %d of %d.",
            sum(!is.na(st_o$drainage_area_gross_km2) & st_o$drainage_area_gross_km2 > 0), nrow(st_o)),
    sprintf("At a HYDAT site: %d; HYDAT's flag there natural at %d, regulated at %d, absent at %d.",
            sum(!is.na(st_o$hydat_site)), sum(st_o$hydat_flag %in% 0), sum(st_o$hydat_flag %in% 1),
            sum(!is.na(st_o$hydat_site) & is.na(st_o$hydat_flag))),
    "",
    "Against the rule header's counts as seen before registration (named where they differ, not corrected there):")
for (nm in names(seen)) {
  say(sprintf("  %-14s as seen %4d, here %4d%s", nm, seen[[nm]], here[[nm]], if (seen[[nm]] != here[[nm]]) "  DIFFERS" else ""))
}
mm <- mrows[mrows$variable == "q_mean" & mrows$period == "migration" & mrows$pool == "loo", ]
near5 <- vapply(main[paste(mm$gauge, "q_mean", "migration", "loo", sep = "|")], function(r) {
  !is.null(r$with) && any(unlist(lapply(r$with$donors, dd_donor_ids)) %in% st_o$station_number)
}, TRUE)
n_with_cand <- length(unique(mrows$gauge[mrows$n_cand > 0]))
say(sprintf("Held-out gauges (under any statistic and window) whose box holds at least one candidate: %d of %d.", n_with_cand, length(unique(mrows$gauge))))
say(sprintf("  The header's proxy (44 of 274 HYDAT gauges with a station among their 5 nearest) is measured here on the migration mean: %d of %d held-out gauges have a station among the carry's donors.",
            sum(near5), nrow(mm)), "")
say(sprintf("Site parity: the pools (box, extension, migration-mean departure) at 08KA012 are %s and at 08KE014 %s, the Swift and Naver site reports' counts lines.",
            parity[["swift"]], parity[["naver"]]), "")

# ---- 2. the held-out scores -------------------------------------------------------------------
say("## 2. Held-out scores", "",
    "Per statistic and window and pool: gauges held out, scored, and not scored by reason; each carry's RMSE (log departure, days for cov_day) and the paired difference (with minus without; negative is better), quartiles; gauges better and worse; a 90 % interval on the median difference from 2,000 resamples of the gauges (set.seed(211)). max is reported, not scored.", "")
for (i in seq_len(nrow(combos))) {
  for (pool in c("loo", "leakfree")) {
    r <- mrows[mrows$variable == combos$variable[i] & mrows$period == combos$period[i] & mrows$pool == pool, ]
    s <- r[r$scored, ]
    why <- table(r$reason[!r$scored])
    ci <- boot_ci(s$diff)
    say(sprintf("%s, %s: %d held out, %d scored; not scored: %s.", lab(combos$variable[i], combos$period[i]),
                if (pool == "loo") "leave-one-gauge-out" else "leak-free", nrow(r), nrow(s),
                if (length(why)) paste(sprintf("%s %d", names(why), as.integer(why)), collapse = "; ") else "none"))
    if (nrow(s)) {
      say(sprintf("  RMSE without %s | with %s | difference %s (quartiles); better %d, worse %d, equal %d; median interval %s..%s",
                  paste(fmt(q3(s$rmse_without)), collapse = " "), paste(fmt(q3(s$rmse_with)), collapse = " "),
                  paste(fmt(q3(s$diff), 4), collapse = " "), sum(s$diff < 0), sum(s$diff > 0), sum(s$diff == 0),
                  fmt(ci[1], 4), fmt(ci[2], 4)))
    }
  }
}
say("")

# ---- 3. the verdict ---------------------------------------------------------------------------
say("## 3. Verdict", "",
    sprintf("Migration-window mean: median paired difference %s leave-one-gauge-out (%d gauges), %s leak-free (%d gauges); the rule needs at most -%.2f in both, with at least %d gauges each.",
            fmt(verdict$med_loo, 4), verdict$n_loo, fmt(verdict$med_lf, 4), verdict$n_lf, dd_margin, dd_min_gauges),
    sprintf("VERDICT: %s (%s).", if (verdict$ship) "the estimated-baseline route ships" else "the donor pool stays HYDAT-only",
            verdict$reason), "")

# ---- 4. reported, deciding nothing ------------------------------------------------------------
say("## 4. Reported, deciding nothing", "")
ev <- function(r, yrs, which) {
  a <- r[[which]]
  r$obs$dep[match(yrs, r$obs$year)] - a$anomaly[match(yrs, a$year)]
}
for (pool in c("loo", "leakfree")) {
  keys <- paste(mm$gauge, "q_mean", "migration", pool, sep = "|")
  rs <- main[keys]
  # every 2011-2025 year both carries return, at the gauges with a station among the donors
  split_rows <- do.call(rbind, lapply(rs, function(r) {
    if (is.null(r$with) || is.null(r$without)) return(NULL)
    dn <- lapply(r$with$donors, dd_donor_ids)
    if (!any(unlist(dn) %in% st_o$station_number)) return(NULL)
    yrs <- intersect(intersect(dd_test_years, r$obs$year), intersect(r$without$year, r$with$year))
    has <- vapply(yrs, function(y) any(dd_donor_ids(r$with$donors[r$with$year == y]) %in% st_o$station_number), TRUE)
    d <- function(y) {
      if (length(y) < dd_min_scored_years) return(NA_real_)
      o <- r$obs$dep[match(y, r$obs$year)]
      dd_rmse(o, r$with$anomaly[match(y, r$with$year)]) - dd_rmse(o, r$without$anomaly[match(y, r$without$year)])
    }
    data.frame(gauge = r$gauge, all = d(yrs), station = d(yrs[has]), none = d(yrs[!has]))
  }))
  if (is.null(split_rows)) split_rows <- data.frame(gauge = character(), all = numeric(), station = numeric(), none = numeric())
  med <- function(x) if (any(!is.na(x))) fmt(stats::median(x, na.rm = TRUE), 4) else "-"
  say(sprintf("Every 2011-2025 year both carries return (%s, migration mean), at the %d gauges with a station among the donors: median difference %s over all years (n %d), %s in the years a station is among the donors (n %d), %s in the years none is (n %d).",
              if (pool == "loo") "leave-one-gauge-out" else "leak-free", nrow(split_rows),
              med(split_rows$all), sum(!is.na(split_rows$all)), med(split_rows$station), sum(!is.na(split_rows$station)),
              med(split_rows$none), sum(!is.na(split_rows$none))))
  sc <- rs[vapply(rs, `[[`, TRUE, "scored")]
  if (length(sc)) {
    mse <- t(vapply(sc, function(r) c(without = mean(ev(r, r$years, "without")), with = mean(ev(r, r$years, "with"))), c(0, 0)))
    nse <- t(vapply(sc, function(r) {
      o <- r$obs$dep[match(r$years, r$obs$year)]
      vapply(c("without", "with"), function(w) {
        car <- r[[w]]$anomaly[match(r$years, r[[w]]$year)]
        wet:::wet_nse(o - mean(o), car - mean(car))
      }, 0)
    }, c(0, 0)))
    say(sprintf("  Mean signed error (observed minus carried), median over scored gauges: without %s, with %s. Centred log NSE on the scored years, median: without %s, with %s.",
                fmt(stats::median(mse[, 1]), 4), fmt(stats::median(mse[, 2]), 4),
                fmt(stats::median(nse[, 1])), fmt(stats::median(nse[, 2]))))
    top <- vapply(sc, function(r) {
      w <- unlist(lapply(r$with$donors[match(r$years, r$with$year)], function(s) {
        p <- strsplit(s, " ", fixed = TRUE)[[1]]
        stats::setNames(as.numeric(sub("^[^:]*:", "", p)), sub(":.*$", "", p))
      }))
      w <- w[names(w) %in% st_o$station_number]
      tw <- tapply(w, names(w), sum)
      names(tw)[order(-tw, names(tw), method = "radix")][1]
    }, "")
    behind <- rsort(unique(unlist(lapply(sc, function(r) {
      intersect(unlist(lapply(r$with$donors[match(r$years, r$with$year)], dd_donor_ids)), st_o$station_number)
    }))))
    dif <- vapply(sc, `[[`, 0, "diff")
    by_st <- tapply(dif, top, stats::median)
    say(sprintf("  Distinct stations behind the scored gauges: %d (%s).", length(behind), paste(behind, collapse = ", ")),
        sprintf("  Median difference by the station each gauge weighted most: %s.",
                paste(sprintf("%s %s (n %d)", names(by_st), fmt(by_st, 4), as.integer(table(top)[names(by_st)])),
                      collapse = "; ")))
    swaps <- sum(vapply(sc, function(r) {
      sum(vapply(r$years, function(y) {
        h1 <- setdiff(dd_donor_ids(r$with$donors[r$with$year == y]), st_o$station_number)
        h0 <- dd_donor_ids(r$without$donors[r$without$year == y])
        !all(h1 %in% h0)
      }, TRUE))
    }, 0))
    fewer <- sum(vapply(sc, function(r) {
      sum(vapply(r$years, function(y) {
        length(setdiff(dd_donor_ids(r$with$donors[r$with$year == y]), st_o$station_number)) <
          length(dd_donor_ids(r$without$donors[r$without$year == y]))
      }, TRUE))
    }, 0))
    n_sy <- sum(vapply(sc, function(r) length(r$years), 0L))
    say(sprintf("  Scored gauge-years whose HYDAT donors with the stations are not among those without: %d of %d; with fewer HYDAT donors than without (a station took a place): %d of %d.",
                swaps, n_sy, fewer, n_sy))
  }
}
say("")

# eligibility, over every held-out gauge, statistic and window (leave-one-gauge-out)
el <- do.call(rbind, lapply(main[vapply(main, function(r) r$pool == "loo" && nrow(r$eligible) > 0, TRUE)], function(r) {
  cbind(gauge = r$gauge, variable = r$variable, period = r$period, r$eligible)
}))
if (!is.null(el)) {
  tb <- table(el$reason)
  say("Station eligibility over every held-out gauge, statistic and window (leave-one-gauge-out), gauge-station pairs by reason:",
      paste0("  ", paste(sprintf("%s %d", names(tb), as.integer(tb)), collapse = "; ")), "")
  em <- el[el$variable == "q_mean" & el$period == "migration" & el$eligible, ]
  say("Eligible stations on the migration mean (leave-one-gauge-out), one line each: fit years; held-out gauges it is eligible at; OLS slope on the nearest extension gauge, median (least..most); its most frequent extension chain (gauges using it):")
  for (s_id in rsort(unique(em$station_number))) {
    e1 <- em[em$station_number == s_id, ]
    ch <- table(e1$chain)
    top_ch <- names(ch)[order(-as.integer(ch), names(ch), method = "radix")][1]
    say(sprintf("  %-10s %-38s %3d  %5s (%s..%s)  %s (%d)", s_id, e1$fit_years[1], nrow(e1),
                fmt(stats::median(e1$slope), 2), fmt(min(e1$slope), 2), fmt(max(e1$slope), 2), top_ch, max(ch)))
  }
  say("")
}
hs <- st_o[!is.na(st_o$hydat_site), ]
say("Stations at a HYDAT site (HYDAT's flag there: 0 natural, 1 regulated):")
for (j in seq_len(nrow(hs))) {
  say(sprintf("  %-10s at %-8s flag %s  migration window-years %d", hs$station_number[j], hs$hydat_site[j],
              ifelse(is.na(hs$hydat_flag[j]), "-", hs$hydat_flag[j]), hs$n_mig[j]))
}
say("")

# ---- 5. sensitivities -------------------------------------------------------------------------
say("## 5. Sensitivities (each a rerun of the whole test on the migration mean, both pools; deciding nothing)", "")
for (i in seq_along(sens_defs)) {
  v <- verdict_of(srows[[i]])
  say(sprintf("%s: median difference %s leave-one-gauge-out (%d gauges), %s leak-free (%d); %s (%s).", sens_defs[[i]]$label,
              fmt(v$med_loo, 4), v$n_loo, fmt(v$med_lf, 4), v$n_lf, if (v$ship) "would ship" else "would not ship", v$reason))
}
say("")

# ---- 6. the scored gauges ---------------------------------------------------------------------
say("## 6. Scored gauges, migration mean: gauge, pool, scored years, RMSE without, with, difference, stations among the donors in the scored years", "")
for (pool in c("loo", "leakfree")) {
  s <- mrows[mrows$variable == "q_mean" & mrows$period == "migration" & mrows$pool == pool & mrows$scored, ]
  for (j in seq_len(nrow(s))) {
    r <- main[[paste(s$gauge[j], "q_mean", "migration", pool, sep = "|")]]
    used <- rsort(unique(intersect(unlist(lapply(r$with$donors[match(r$years, r$with$year)], dd_donor_ids)),
                                   st_o$station_number)))
    say(sprintf("  %-8s %-8s %2d %s %s %s  %s", s$gauge[j], pool, s$n_years[j], fmt(s$rmse_without[j]), fmt(s$rmse_with[j]),
                fmt(s$diff[j], 4), paste(used, collapse = " ")))
  }
}

dir.create(dirname(report), recursive = TRUE, showWarnings = FALSE)
writeLines(out, report)
stamp("wrote ", report, ": ", if (verdict$ship) "ships" else "stays HYDAT-only")
