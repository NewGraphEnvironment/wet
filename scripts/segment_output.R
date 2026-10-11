# Per-segment flow from either source (#57): PCIC's routed flow and the open
# water balance on every FWA segment, labelled by source, with a default pick.
#
#   WET_FWAPG_COMMIT=<sha> Rscript scripts/segment_output.R
#
# Reads the shipped fit's province output (scripts/wb_output.R, per
# fundamental watershed), wet's accumulated upstream areas (the province run's
# upstream/), the routed table (scripts/pcic_routed_lib.R) and
# fwa_streams_watersheds_lut. Writes, per top-level basin (gitignored):
#   <fit>/segment/<CODE>.parquet
#     linear_feature_id, month (0 annual, 1-12), runoff_mm, q_m3s, coverage,
#     source (pcic_routed, wet_balance), period, pick
# one row per segment, month and source with a value, and the tracked report
# wb_report("segment_output", release).
#
# - The balance reaches a segment through the lut: every segment of a
#   fundamental watershed carries that watershed's value, as the vignette maps
#   it. A segment with no lut row has no value from either source.
# - Routed annual flow is the mean of the 12 monthly means (routed_annual()'s
#   definition, #58), and needs all twelve. Its runoff_mm is over wet's
#   accumulated area of the segment's watershed, on 365.25 days a year and
#   wet_month_days() a month, the days the balance converts with. Its coverage
#   is NA: coverage is the share of a watershed's area the balance's inputs
#   cover.
# - pick: wet_source_pick() on annual flow at routed_far_low, the same source
#   for all 13 months.
# - period: routed 1951-2012, the balance 1981-2010 (#57's decision, until
#   fwapg builds routed flow over 1981-2010).
#
# Run where the full province run is (m4 holds it; m1's bundle is cut). Uses
# about 10 GB for the Fraser. Connection from WET_PG*.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
source("scripts/pcic_routed_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)

# the report cites the commit it was built at, so that commit must hold the
# code. system2() only warns when git fails, so check its status
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data/checks")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the output:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")

key_dir <- wb_key_dir()
release <- wb_release()
fit_dir <- wb_fit_dir(key_dir, release)
source("scripts/wb_score_md5.R")  # score_code_md5, aet_code_md5

# the balance as it ships: the fit wb_output.R would accept, and output made
# from that fit rather than an earlier one
fits <- readRDS(file.path(fit_dir, "fits.rds"))
winner <- readLines(file.path(fit_dir, "aet_winner.txt"))
if (!identical(fits$code_md5, score_code_md5) || !identical(winner[1:2], c(fits$aet, aet_code_md5))) {
  stop("the fit in ", fit_dir, " was made or chosen under other scoring code: rerun the fit and scripts/wb_output.R")
}
out_files <- list.files(file.path(fit_dir, "output"), "\\.parquet$", full.names = TRUE)
if (!length(out_files)) stop("no balance output in ", fit_dir, ": run scripts/wb_output.R")
if (any(file.mtime(out_files) < file.mtime(file.path(fit_dir, "fits.rds")))) {
  stop("the balance output predates fits.rds: rerun scripts/wb_output.R")
}
codes <- sub("\\.parquet$", "", basename(out_files))
miss_up <- codes[!file.exists(file.path(key_dir, "upstream", paste0(codes, ".rds")))]
if (length(miss_up)) stop("no upstream means for basins ", paste(miss_up, collapse = ", "))

# the routed table must be the one the tracked report scored, at the commit it names
fwapg_commit <- routed_commit()
f_routed <- wb_report("pcic_routed_compare", release)
rr <- readLines(f_routed)
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
routed_fp <- routed_fingerprint(conn)
routed_line <- sprintf("routed: %s, built by NewGraphEnvironment/fwapg at %s", routed_table, fwapg_commit)
if (!(any(rr == routed_line) && any(rr == sprintf("table: %s", routed_fp)))) {
  stop(f_routed, " was not made from this routed table at fwapg ", fwapg_commit,
       ": rerun scripts/pcic_routed_compare.R")
}

# every FWA segment, with its watershed where the lut has one
seg <- DBI::dbGetQuery(conn, "
  SELECT s.linear_feature_id, s.watershed_group_code, l.watershed_feature_id
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)")
stopifnot(!anyDuplicated(seg$linear_feature_id), max(seg$linear_feature_id) < .Machine$integer.max)
seg$linear_feature_id <- as.integer(seg$linear_feature_id)
seg$watershed_feature_id <- as.integer(seg$watershed_feature_id)
seg$basin <- NA_character_
stamp(nrow(seg), " segments, ", sum(!is.na(seg$watershed_feature_id)), " with a watershed")

unlink(file.path(fit_dir, "segment"), recursive = TRUE)
dir.create(file.path(fit_dir, "segment"))
days <- c(365.25, wet_month_days())
cols_out <- c("linear_feature_id", "month", "runoff_mm", "q_m3s", "coverage", "source", "period", "pick")
period_routed <- "1951-2012"
period_balance <- "1981-2010"
tally <- list()
seg_q <- list()  # annual flow of each source and the pick, per segment, for the report
DBI::dbExecute(conn, "CREATE TEMP TABLE seg_ids (linear_feature_id bigint PRIMARY KEY)")
for (code in codes) {
  bal <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", paste0(code, ".parquet"))))
  stopifnot(setequal(unique(bal$month), 0:12))
  up <- readRDS(file.path(key_dir, "upstream", paste0(code, ".rds")))
  ws <- unique(bal$watershed_feature_id)
  stopifnot(setequal(ws, up$watershed_feature_id), !anyDuplicated(up$watershed_feature_id))
  i_seg <- which(seg$watershed_feature_id %in% ws)
  if (any(!is.na(seg$basin[i_seg]))) stop("segments of basin ", code, " already belong to another basin")
  seg$basin[i_seg] <- code
  s <- seg[i_seg, c("linear_feature_id", "watershed_feature_id")]

  # the balance: the watershed's value on each of its segments. wb_output.R
  # writes the watersheds in one order, month by month
  nws <- length(ws)
  stopifnot(identical(bal$month, rep(0:12, each = nws)),
            identical(bal$watershed_feature_id, rep(bal$watershed_feature_id[seq_len(nws)], 13)))
  iw <- match(s$watershed_feature_id, bal$watershed_feature_id[seq_len(nws)])
  s$q_balance <- bal$discharge_m3s[iw]
  s$area_m2 <- up$upstream_area_m2[match(s$watershed_feature_id, up$watershed_feature_id)]

  # routed: all twelve months on the segment
  DBI::dbExecute(conn, "TRUNCATE seg_ids")
  DBI::dbWriteTable(conn, "seg_ids", data.frame(linear_feature_id = s$linear_feature_id), append = TRUE)
  rt <- DBI::dbGetQuery(conn, sprintf("
    SELECT r.linear_feature_id::int AS linear_feature_id, r.month, r.q_m3s
    FROM %s r JOIN seg_ids USING (linear_feature_id)", routed_table))
  stopifnot(all(rt$month %in% 1:12))
  n12 <- tabulate(match(rt$linear_feature_id[!is.na(rt$q_m3s)], s$linear_feature_id), nbins = nrow(s))
  rt <- rt[rt$linear_feature_id %in% s$linear_feature_id[n12 == 12], ]
  rt0 <- stats::aggregate(q_m3s ~ linear_feature_id, rt, mean)
  s$q_routed <- rt0$q_m3s[match(s$linear_feature_id, rt0$linear_feature_id)]
  s$source <- wet_source_pick(s$q_routed, s$q_balance, routed_far_low)

  # balance rows: 13 per segment whose watershed has a value
  kb <- which(!is.na(s$q_balance))
  sb <- s[kb, ]
  bm <- bal[rep(iw[kb], 13) + rep(0:12 * nws, each = length(kb)), ]
  rows_b <- data.frame(
    linear_feature_id = rep(sb$linear_feature_id, 13), month = rep(0:12, each = nrow(sb)),
    runoff_mm = bm$runoff_mm, q_m3s = bm$discharge_m3s, coverage = bm$coverage,
    source = "wet_balance", period = period_balance,
    pick = rep(sb$source == "wet_balance", 13)
  )

  # routed rows: the annual mean plus its twelve months
  sr <- s[!is.na(s$q_routed), ]
  rq <- rbind(data.frame(linear_feature_id = sr$linear_feature_id, month = 0L, q_m3s = sr$q_routed),
              rt[rt$linear_feature_id %in% sr$linear_feature_id, c("linear_feature_id", "month", "q_m3s")])
  j <- match(rq$linear_feature_id, sr$linear_feature_id)
  rows_r <- data.frame(
    linear_feature_id = rq$linear_feature_id, month = as.integer(rq$month),
    runoff_mm = rq$q_m3s * days[rq$month + 1] * 86400 / sr$area_m2[j] * 1000,
    q_m3s = rq$q_m3s, coverage = NA_real_,
    source = "pcic_routed", period = period_routed,
    pick = sr$source[j] == "pcic_routed"
  )
  out <- rbind(rows_b, rows_r)[cols_out]
  out <- out[order(out$linear_feature_id, out$source, out$month), ]
  # exactly one picked source per segment and month, and only one row per source
  key <- paste(out$linear_feature_id, out$month)
  stopifnot(!anyDuplicated(paste(key, out$source)), !anyNA(out$pick),
            all(tabulate(match(key[out$pick], unique(key)), nbins = length(unique(key))) == 1),
            sum(out$pick) == 13 * sum(!is.na(s$source)))
  tmp <- tempfile(fileext = ".parquet", tmpdir = file.path(fit_dir, "segment"))
  arrow::write_parquet(out, tmp)
  if (!file.rename(tmp, file.path(fit_dir, "segment", paste0(code, ".parquet")))) stop("could not move ", tmp)

  tally[[code]] <- data.frame(
    code = code, segments = nrow(s), both = sum(!is.na(s$q_routed) & !is.na(s$q_balance)),
    routed_only = sum(!is.na(s$q_routed) & is.na(s$q_balance)),
    balance_only = sum(is.na(s$q_routed) & !is.na(s$q_balance)),
    neither = sum(is.na(s$source)), pick_routed = sum(s$source %in% "pcic_routed"),
    pick_balance = sum(s$source %in% "wet_balance"),
    flipped = sum(!is.na(s$q_routed) & s$source %in% "wet_balance"),
    routed_no_area = sum(!is.na(s$q_routed) & is.na(s$area_m2))
  )
  seg_q[[code]] <- s[c("linear_feature_id", "q_routed", "q_balance", "source")]
  stamp(code, ": ", nrow(s), " segments, ", nrow(out), " rows")
  rm(bal, up, rt, rt0, rows_b, rows_r, out, bm, rq)
  gc(verbose = FALSE)
}
stopifnot(identical(routed_fingerprint(conn), routed_fp))
# a routed segment whose watershed is in no basin's output would be dropped
n_routed_unplaced <- DBI::dbGetQuery(conn, sprintf("
  SELECT count(DISTINCT linear_feature_id)::int AS n FROM %s", routed_table))$n -
  sum(vapply(tally, function(x) x$both + x$routed_only, integer(1)))
DBI::dbDisconnect(conn)
tally <- do.call(rbind, tally)
seg_q <- do.call(rbind, seg_q)

# ---- report -----------------------------------------------------------------------------------
seg$source <- seg_q$source[match(seg$linear_feature_id, seg_q$linear_feature_id)]
seg$both <- seg$linear_feature_id %in% seg_q$linear_feature_id[!is.na(seg_q$q_routed) & !is.na(seg_q$q_balance)]
flip_ids <- seg_q$linear_feature_id[!is.na(seg_q$q_routed) & seg_q$source %in% "wet_balance"]
seg$flipped <- seg$linear_feature_id %in% flip_ids
grp <- do.call(rbind, lapply(split(seg, seg$watershed_group_code), function(x) {
  data.frame(group = x$watershed_group_code[1], segments = nrow(x), routed = sum(x$source %in% "pcic_routed"),
             balance = sum(x$source %in% "wet_balance"), none = sum(is.na(x$source)), both = sum(x$both),
             flipped = sum(x$flipped))
}))
grp$flip_pct <- ifelse(grp$both > 0, 100 * grp$flipped / grp$both, NA)
grp <- grp[order(grp$group), ]
nechako <- c("LEUT", "UEUT", "UNRS", "LNRS")
hi <- grp[!is.na(grp$flip_pct) & grp$flip_pct > 50, ]
fmt_grp <- function(x) {
  sprintf("%-5s %9d %9d %9d %8d %9d %9d %7.1f", x$group, x$segments, x$routed, x$balance, x$none, x$both,
          x$flipped, x$flip_pct)
}
hdr_grp <- sprintf("%-5s %9s %9s %9s %8s %9s %9s %7s", "group", "segments", "routed", "balance", "none", "both",
                   "flipped", "flip %")
n_no_ws <- sum(is.na(seg$watershed_feature_id))
n_ws_no_basin <- sum(!is.na(seg$watershed_feature_id) & is.na(seg$basin))
pct <- function(a, b) sprintf("%.1f %%", 100 * a / b)

con <- file(wb_report("segment_output", release), "w")
writeLines(c(
  "# Per-segment flow from either source (#57)", "",
  sprintf("wet commit %s; fit %s, province run %s, scoring code %s", wet_commit, release, basename(key_dir),
          score_code_md5),
  routed_line, sprintf("table: %s", routed_fp),
  sprintf("pick: routed PCIC unless its annual flow is under %.2f x the balance's, then the balance (wet_source_pick)",
          routed_far_low),
  sprintf("periods: routed %s, balance %s", period_routed, period_balance), "",
  "## Segments",
  sprintf("FWA segments: %d; with a watershed in the lut: %d; without (no value from either source): %d",
          nrow(seg), nrow(seg) - n_no_ws, n_no_ws),
  sprintf("with a watershed but in no basin's output: %d; routed segments left out that way: %d",
          n_ws_no_basin, n_routed_unplaced),
  sprintf("both sources: %d; routed only: %d; balance only: %d; neither: %d",
          sum(tally$both), sum(tally$routed_only), sum(tally$balance_only), sum(tally$neither) + n_no_ws),
  sprintf("picked routed: %d (%s of segments with a value); picked balance: %d, %d of them under the cut",
          sum(tally$pick_routed), pct(sum(tally$pick_routed), sum(tally$pick_routed) + sum(tally$pick_balance)),
          sum(tally$pick_balance), sum(tally$flipped)),
  sprintf("routed segments with no accumulated area (runoff_mm NA): %d", sum(tally$routed_no_area)),
  "", "## By basin",
  sprintf("%-4s %9s %9s %9s %9s %8s %9s %9s %9s", "code", "segments", "both", "rt_only", "bal_only", "neither",
          "pick_rt", "pick_bal", "flipped"),
  sprintf("%-4s %9d %9d %9d %9d %8d %9d %9d %9d", tally$code, tally$segments, tally$both, tally$routed_only,
          tally$balance_only, tally$neither, tally$pick_routed, tally$pick_balance, tally$flipped),
  "", "## Nechako Reservoir groups (routed about zero on #58's reservoir-lake gauges)",
  hdr_grp, fmt_grp(grp[grp$group %in% nechako, ]),
  sprintf("their share of all flipped segments: %s", pct(sum(grp$flipped[grp$group %in% nechako]), sum(grp$flipped))),
  "", sprintf("## Groups where more than half the segments with both sources flip (%d)", nrow(hi)),
  hdr_grp, fmt_grp(hi),
  "", "## By watershed group",
  "flipped: routed flow under the cut, so the balance is picked; flip %: of segments with both sources",
  hdr_grp, fmt_grp(grp)
), con)
close(con)
stamp("report written")
