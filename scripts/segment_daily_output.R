# Per-segment daily flow from either source (#99): the monthly segment table
# (scripts/segment_output.R, #57) laid out on the 365 days of a common year,
# 29 February folded into 28 February.
#
#   WET_FWAPG_COMMIT=<sha> Rscript scripts/segment_daily_output.R
#
# Reads the monthly segment table and its tracked report, the shipped fit's
# balance output and daily shape (<fit>/shape_daily.rds, scripts/wb_shape_daily.R,
# #70), the province run's upstream/ (predictors and areas), and fwapg's
# routed day-of-year climatology and segment weights (scripts/pcic_routed_lib.R).
# Writes, per watershed group (gitignored):
#   <fit>/segment_daily/<GROUP>.parquet
#     linear_feature_id, doy (1-365), runoff_mm, q_m3s, coverage, source, period, pick
# one row per segment, day and source the monthly table has, and the tracked
# report wb_report("segment_daily_output", release).
#
# - The balance: each watershed's published months 1-12 (output/) laid on the
#   shape the fit ships, q[d] = Q[m] * n[m] * w[d] (wet_shape_daily()), so a
#   calendar month's days average to its month; reached by a segment through
#   fwa_streams_watersheds_lut, as the monthly rows are.
# - Routed PCIC: each day routed from the sub-basin days and the segment's
#   weights, clamped at 0 and rounded to 5 decimals, as fwapg makes its months
#   (wet:::wet_routed_days()). Its days need not average to its months: the
#   clamp applies day by day, and 28 February carries 29 February.
# - runoff_mm is mm/day over the area the monthly row used (NA where the
#   monthly routed row's is: off the watershed's own line); coverage, period
#   and pick are the monthly rows'.
# - Guards: the routed months rebuilt from the days must be fwapg's months the
#   monthly table holds (a rounding tie aside), and the balance's days must
#   average to its months, or nothing is written.
#
# Run where the full province run is (m4 holds it). Connection from WET_PG*.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
source("scripts/pcic_routed_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
t_start <- Sys.time()

git <- function(...) {
  x <- suppressWarnings(system2("git", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data/checks")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the output:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")

key_dir <- wb_key_dir()
release <- wb_release()
if (!identical(release, wb_shipped_release)) stop("the daily table is built from the shipped fit, ", wb_shipped_release)
fit_dir <- wb_fit_dir(key_dir, release)
out_dir <- file.path(fit_dir, "segment_daily")
# the old table goes first, so a refused run never leaves one to be read
unlink(out_dir, recursive = TRUE)
stopifnot(!dir.exists(out_dir))
source("scripts/wb_score_md5.R")  # score_code_md5

# ---- the inputs, each the one the monthly table was built from ---------------------------------
fits <- readRDS(file.path(fit_dir, "fits.rds"))
winner <- readLines(file.path(fit_dir, "aet_winner.txt"))
if (!identical(fits$code_md5, score_code_md5) || !identical(winner[1:2], c(fits$aet, score_code_md5))) {
  stop("the fit in ", fit_dir, " was made or chosen under other scoring code")
}
shape <- readRDS(file.path(fit_dir, "shape_daily.rds"))
if (!identical(shape$method, "donor") || !inherits(shape$fit, "wet_shape_fit") ||
      !identical(shape$code_md5, fits$code_md5) || !identical(shape$release, release) ||
      !identical(shape$aet, fits$aet)) {
  stop("shape_daily.rds is not a donor shape made on this fit: rerun scripts/wb_shape_daily.R")
}
f_seg_report <- wb_report("segment_output", release)
sr <- readLines(f_seg_report)
seg_commit <- sub("^wet commit ([0-9a-f]+);.*", "\\1", grep("^wet commit ", sr, value = TRUE))
if (length(seg_commit) != 1L || !any(grepl(paste0("scoring code ", score_code_md5, "$"), sr[3]))) {
  stop(f_seg_report, " names no single wet commit, or another fit's scoring code")
}
# the monthly table must be what the code as it stands builds; this script and
# the publish code are the only files it does not depend on
own <- c("scripts/segment_daily_output.R", "R/wet_catalog.R", "R/wet_db_load.R", "R/wet_values_compare.R",
         "scripts/discharge_publish.R", "scripts/discharge_publish_lib.R")
changed <- git("diff", "--name-only", seg_commit, "HEAD", "--", "R", "scripts", paste0(":(exclude)", own))
if (length(changed)) {
  stop("code changed since the monthly segment table was built at ", seg_commit, " (",
       paste(changed, collapse = ", "), "): rerun scripts/segment_output.R")
}
seg_files <- list.files(file.path(fit_dir, "segment"), "\\.parquet$", full.names = TRUE)
out_files <- list.files(file.path(fit_dir, "output"), "\\.parquet$", full.names = TRUE)
if (!length(seg_files) || max(file.mtime(seg_files)) > file.mtime(f_seg_report) ||
      min(file.mtime(seg_files)) < max(file.mtime(out_files))) {
  stop("the monthly segment table is missing, postdates its report or predates the balance output: ",
       "rerun scripts/segment_output.R")
}
codes <- sub("\\.rds$", "", list.files(file.path(key_dir, "upstream"), "\\.rds$"))
codes_seg <- sub("\\.parquet$", "", basename(seg_files))
if (!setequal(codes, sub("\\.parquet$", "", basename(out_files))) || !all(codes_seg %in% codes)) {
  stop("the balance output, the segment table and the province run's upstream/ hold different basins")
}
routed_line <- grep("^routed: ", sr, value = TRUE)
routed_fp_seg <- sub("^table: ", "", grep("^table: ", sr, value = TRUE))
stopifnot(length(routed_line) == 1L, length(routed_fp_seg) == 1L)
if (!identical(routed_line, routed_report_line(routed_commit()))) {
  stop(f_seg_report, " was built from another routed run or fwapg commit than WET_FWAPG_COMMIT names")
}
n_unplaced <- as.numeric(sub(".*routed segments left out that way: ([0-9]+)$", "\\1",
                             grep("routed segments left out that way: ", sr, value = TRUE)))
stopifnot(length(n_unplaced) == 1L, !is.na(n_unplaced))

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
if (!identical(routed_fingerprint(conn), routed_fp_seg)) {
  stop("fwapg's ", routed_table, " is not the table ", f_seg_report, " was built from (", routed_fp_seg, ")")
}
daily_fp <- routed_daily_fingerprint(conn)
inp <- routed_daily_inputs(conn)
weights <- inp$weights
fold <- inp$fold
mid <- routed_mid_network(conn, weights)
lut <- DBI::dbGetQuery(conn, "
  SELECT linear_feature_id::int AS linear_feature_id, watershed_feature_id::int AS watershed_feature_id
  FROM whse_basemapping.fwa_streams_watersheds_lut")
seg_grp <- DBI::dbGetQuery(conn, "
  SELECT linear_feature_id::int AS linear_feature_id, watershed_group_code FROM whse_basemapping.fwa_stream_networks_sp")
stopifnot(identical(routed_daily_fingerprint(conn), daily_fp))
DBI::dbDisconnect(conn)
stopifnot(!anyDuplicated(lut$linear_feature_id), !anyDuplicated(seg_grp$linear_feature_id))
stamp(nrow(weights), " weighted segments, ", length(fold$subid), " sub-basins; ", daily_fp)

# ---- per drainage, then per group within it --------------------------------------------------------
m <- wet_doy_month()
n_m <- wet_doy_days()
dir.create(file.path(out_dir, "_pieces"), recursive = TRUE)
cols_out <- c("linear_feature_id", "doy", "runoff_mm", "q_m3s", "coverage", "source", "period", "pick")
tally <- list()
routed_seen <- integer()
clamp <- matrix(0, 365, 4, dimnames = list(NULL, c("rows", "clamped", "mid_rows", "mid_clamped")))
vs_month <- c(compared = 0, differing = 0, tie_steps = 0)
consist <- c(segment_months = 0, beyond_rounding = 0, feb_beyond = 0, max_above = 0, max_below = 0)
bal_identity <- c(watershed_months = 0, max_rel = 0, max_rel_mm = 0)
for (code in codes_seg) {
  st <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "segment", paste0(code, ".parquet"))))
  st0 <- st[st$month == 0L, ]
  st$group <- seg_grp$watershed_group_code[match(st$linear_feature_id, seg_grp$linear_feature_id)]
  stopifnot(!anyNA(st$group))

  # the balance: every watershed with months, on the shipped shape
  bal <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", paste0(code, ".parquet")),
                                           col_select = c("watershed_feature_id", "month", "runoff_mm", "discharge_m3s")))
  up <- readRDS(file.path(key_dir, "upstream", paste0(code, ".rds")))
  nws <- nrow(up)
  stopifnot(identical(as.integer(bal$month), rep(0:12, each = nws)),
            identical(bal$watershed_feature_id[seq_len(nws)], up$watershed_feature_id))
  q_mon <- matrix(bal$discharge_m3s[bal$month > 0L], nws, 12)
  valued <- which(!is.na(bal$discharge_m3s[seq_len(nws)]))
  stopifnot(!anyNA(q_mon[valued, ]))
  pred_ok <- stats::complete.cases(up[shape$static])
  if (!all(pred_ok[valued])) stop(code, ": ", sum(!pred_ok[valued]), " watersheds with months lack shape predictors")
  w <- wet_shape_predict(shape$fit, up[valued, shape$static])
  q_day <- wet_shape_daily(q_mon[valued, , drop = FALSE], w)
  rm(w)
  # each calendar month's days average to its month
  back <- vapply(1:12, function(k) rowMeans(q_day[, m == k, drop = FALSE]), numeric(length(valued)))
  back <- matrix(back, ncol = 12)
  rel <- abs(back - q_mon[valued, , drop = FALSE]) / pmax(abs(q_mon[valued, , drop = FALSE]), 1e-12)
  rel[q_mon[valued, ] == 0 & back == 0] <- 0
  bal_identity[["watershed_months"]] <- bal_identity[["watershed_months"]] + length(rel)
  bal_identity[["max_rel"]] <- max(bal_identity[["max_rel"]], rel)
  if (any(rel > 1e-9)) stop(code, ": the balance's days do not average to its months (largest relative ", max(rel), ")")
  ws_row <- match(up$watershed_feature_id, up$watershed_feature_id[valued])  # watershed -> row of q_day
  to_mm <- 86400 / up$upstream_area_m2 * 1000
  # and a month's daily depths sum to its depth, over 28 of February's 28.25 days
  mm_mon <- matrix(bal$runoff_mm[bal$month > 0L], nws, 12)[valued, , drop = FALSE]
  mm_sum <- matrix(vapply(1:12, function(k) rowSums(q_day[, m == k, drop = FALSE]), numeric(length(valued))),
                   ncol = 12) * to_mm[valued]
  want <- mm_mon * rep(n_m / wet_month_days(), each = nrow(mm_mon))
  rel_mm <- abs(mm_sum - want) / pmax(abs(want), 1e-12)
  rel_mm[want == 0 & mm_sum == 0] <- 0
  bal_identity[["max_rel_mm"]] <- max(bal_identity[["max_rel_mm"]], rel_mm)
  if (any(rel_mm > 1e-9)) stop(code, ": the balance's daily depths do not sum to its monthly depths")

  for (g in sort(unique(st$group))) {
    sg <- st[st$group == g, ]
    rows <- list()
    # balance rows: the segment's watershed's days
    b0 <- sg[sg$source == "wet_balance" & sg$month == 0L, ]
    if (nrow(b0)) {
      wsf <- lut$watershed_feature_id[match(b0$linear_feature_id, lut$linear_feature_id)]
      iw <- match(wsf, up$watershed_feature_id)
      ir <- ws_row[iw]
      if (anyNA(ir)) stop(code, " ", g, ": a balance segment's watershed has no days")
      rows$b <- data.frame(
        linear_feature_id = rep(b0$linear_feature_id, each = 365), doy = rep(1:365, nrow(b0)),
        runoff_mm = as.vector(t(q_day[ir, , drop = FALSE] * to_mm[iw])),
        q_m3s = as.vector(t(q_day[ir, , drop = FALSE])), coverage = rep(b0$coverage, each = 365),
        source = "wet_balance", period = rep(b0$period, each = 365), pick = rep(b0$pick, each = 365))
    }
    # routed rows: the segment's routed days, checked against its months
    r0 <- sg[sg$source == "pcic_routed" & sg$month == 0L, ]
    if (nrow(r0)) {
      iwt <- match(r0$linear_feature_id, weights$linear_feature_id)
      if (anyNA(iwt)) stop(code, " ", g, ": a routed segment has no weights")
      wt <- weights[iwt, ]
      raw <- wet:::wet_routed_raw(fold, wt)
      qd <- wet:::wet_routed_round(pmax(raw, 0))
      dim(qd) <- dim(raw)
      clamp[, "rows"] <- clamp[, "rows"] + nrow(raw)
      clamp[, "clamped"] <- clamp[, "clamped"] + colSums(raw < 0)
      clamp[, "mid_rows"] <- clamp[, "mid_rows"] + sum(mid[iwt])
      clamp[, "mid_clamped"] <- clamp[, "mid_clamped"] + colSums(raw[mid[iwt], , drop = FALSE] < 0)
      # fwapg's months from the raw days: n_days-weighted, then clamped and rounded
      wm <- vapply(1:12, function(k) {
        j <- which(m == k)
        as.vector(raw[, j, drop = FALSE] %*% fold$n_days[j]) / sum(fold$n_days[j])
      }, numeric(nrow(raw)))
      wm <- matrix(wm, ncol = 12)
      mine <- wet:::wet_routed_round(pmax(wm, 0))
      rm_ <- sg[sg$source == "pcic_routed" & sg$month > 0L, ]
      pub <- matrix(rm_$q_m3s[match(paste(rep(r0$linear_feature_id, 12), rep(1:12, each = nrow(r0))),
                                    paste(rm_$linear_feature_id, rm_$month))], ncol = 12)
      stopifnot(!anyNA(pub))
      d <- abs(mine - pub)
      # one 1e-5 step is fwapg's rounding of a value on a tie only where the
      # raw month sits on one, to within the two summation orders' relative
      # difference; any other difference is a difference
      f <- abs(wm) * 1e5
      tie <- d > 0 & d <= 1.000001e-5 & abs(f - floor(f) - 0.5) < 1e-6 + 1e-10 * f
      vs_month <- vs_month + c(length(d), sum(d > 0 & !tie), sum(tie))
      # how far a reader's plain mean of the published days sits from the month
      plain <- matrix(vapply(1:12, function(k) rowMeans(qd[, m == k, drop = FALSE]), numeric(nrow(qd))), ncol = 12)
      dd <- plain - pub
      beyond <- abs(dd) > 1e-5
      consist <- c(consist[["segment_months"]] + length(dd), consist[["beyond_rounding"]] + sum(beyond),
                   consist[["feb_beyond"]] + sum(beyond[, 2]), max(consist[["max_above"]], dd),
                   min(consist[["max_below"]], dd))
      names(consist) <- c("segment_months", "beyond_rounding", "feb_beyond", "max_above", "max_below")
      own_mm <- r0$runoff_mm  # NA off the watershed's own line, as in the monthly row
      area_mm <- ifelse(is.na(own_mm), NA_real_,
                        to_mm[match(lut$watershed_feature_id[match(r0$linear_feature_id, lut$linear_feature_id)],
                                    up$watershed_feature_id)])
      rows$r <- data.frame(
        linear_feature_id = rep(r0$linear_feature_id, each = 365), doy = rep(1:365, nrow(r0)),
        runoff_mm = as.vector(t(qd * area_mm)), q_m3s = as.vector(t(qd)), coverage = NA_real_,
        source = "pcic_routed", period = rep(r0$period, each = 365), pick = rep(r0$pick, each = 365))
      routed_seen <- c(routed_seen, r0$linear_feature_id)
      rm(raw, qd, wm, mine, plain)
    }
    out <- do.call(rbind, rows)[cols_out]
    out <- out[order(out$linear_feature_id, out$source, out$doy), ]
    key <- paste(out$linear_feature_id, out$doy)
    stopifnot(!anyDuplicated(paste(key, out$source)), !anyNA(out$pick), !anyNA(out$q_m3s),
              all(tabulate(match(key[out$pick], unique(key)), nbins = length(unique(key))) == 1L))
    arrow::write_parquet(out, file.path(out_dir, "_pieces", sprintf("%s_%s.parquet", g, code)))
    tally[[paste(code, g)]] <- data.frame(code = code, group = g, routed = nrow(r0), balance = nrow(b0),
                                          rows = nrow(out))
    rm(out, rows, sg)
  }
  if (vs_month[["differing"]] > 0) {
    stop(code, ": ", vs_month[["differing"]], " routed months rebuilt from the days are not fwapg's months")
  }
  stamp(code, ": ", length(valued), " watersheds with days, ", sum(st0$source == "pcic_routed"), " routed and ",
        sum(st0$source == "wet_balance"), " balance segments")
  rm(st, st0, bal, up, q_mon, q_day, back, rel)
  gc(verbose = FALSE)
}
stopifnot(!anyDuplicated(routed_seen))
# every weighted segment is published but those no basin places, as in the monthly table
n_weights_unpublished <- nrow(weights) - length(routed_seen)
if (n_weights_unpublished != n_unplaced) {
  stop(n_weights_unpublished, " weighted segments have no routed days; the monthly report leaves out ", n_unplaced)
}
tally <- do.call(rbind, tally)

# ---- one file per group, from its pieces ------------------------------------------------------------
pieces <- list.files(file.path(out_dir, "_pieces"), "\\.parquet$", full.names = TRUE)
p_group <- sub("_.*$", "", basename(pieces))
for (g in sort(unique(p_group))) {
  x <- do.call(rbind, lapply(pieces[p_group == g], function(f) as.data.frame(arrow::read_parquet(f))))
  x <- x[order(x$linear_feature_id, x$source, x$doy), ]
  stopifnot(!anyDuplicated(paste(x$linear_feature_id, x$source, x$doy)))
  tmp <- tempfile(fileext = ".parquet", tmpdir = out_dir)
  arrow::write_parquet(x, tmp)
  if (!file.rename(tmp, file.path(out_dir, paste0(g, ".parquet")))) stop("could not move ", tmp)
}
unlink(file.path(out_dir, "_pieces"), recursive = TRUE)
by_group <- stats::aggregate(cbind(routed, balance, rows) ~ group, tally, sum)
stopifnot(setequal(sub("\\.parquet$", "", list.files(out_dir, "\\.parquet$")), by_group$group),
          all(by_group$rows == 365 * (by_group$routed + by_group$balance)))
stamp(nrow(by_group), " group files")

# ---- report ---------------------------------------------------------------------------------------
pct <- function(a, b) sprintf("%.3f %%", 100 * a / b)
md <- wet_doy_md()
worst <- order(-clamp[, "mid_clamped"])[1:5]
con <- file(wb_report("segment_daily_output", release), "w")
writeLines(c(
  "# Per-segment daily flow from either source (#99)", "",
  sprintf("wet commit %s (segment table built at %s); fit %s, province run %s, scoring code %s", wet_commit,
          seg_commit, release, basename(key_dir), score_code_md5),
  routed_line, sprintf("table: %s", routed_fp_seg), sprintf("daily: %s", daily_fp),
  sprintf("balance shape: %s, k = %d, shape code %s", shape$method, shape$fit$k, shape$shape_code_md5),
  sprintf("elapsed: %.1f min", as.numeric(difftime(Sys.time(), t_start, units = "mins"))), "",
  "## Rows",
  sprintf("segments: %d routed, %d balance; rows: %.0f (%d groups)", sum(by_group$routed), sum(by_group$balance),
          sum(by_group$rows), nrow(by_group)),
  sprintf("weighted segments without routed days: %d (the monthly report's routed segments left out: %d)",
          n_weights_unpublished, n_unplaced), "",
  "## The balance's days average to its months",
  sprintf("watershed-months: %.0f; largest relative difference: %.3g (limit 1e-9)", bal_identity[["watershed_months"]],
          bal_identity[["max_rel"]]),
  sprintf("daily runoff_mm summed over each month against its monthly runoff_mm (x 28/28.25 in February): largest relative %.3g",
          bal_identity[["max_rel_mm"]]), "",
  "## Routed months rebuilt from the raw days (n_days-weighted, clamped, rounded) against fwapg's months",
  sprintf("segment-months: %.0f; differing by more than one 1e-5 step: %.0f; by one step at a rounding tie: %.0f",
          vs_month[["compared"]], vs_month[["differing"]], vs_month[["tie_steps"]]), "",
  "## A reader's plain mean of a month's published routed days against the published month",
  sprintf("segment-months: %.0f; more than 1e-5 m3/s apart: %.0f (%s), %.0f of them in February",
          consist[["segment_months"]], consist[["beyond_rounding"]],
          pct(consist[["beyond_rounding"]], consist[["segment_months"]]), consist[["feb_beyond"]]),
  sprintf("largest above: %.5f m3/s; largest below: %.5f m3/s", consist[["max_above"]], consist[["max_below"]]), "",
  "## Routed days clamped at zero (flow before the clamp below 0)",
  sprintf("rows: %.0f; clamped: %.0f (%s); mid-network rows: %.0f; clamped: %.0f (%s)",
          sum(clamp[, "rows"]), sum(clamp[, "clamped"]), pct(sum(clamp[, "clamped"]), sum(clamp[, "rows"])),
          sum(clamp[, "mid_rows"]), sum(clamp[, "mid_clamped"]),
          pct(sum(clamp[, "mid_clamped"]), sum(clamp[, "mid_rows"]))),
  sprintf("worst days, mid-network clamped: %s", paste(sprintf("%s %.0f", md[worst], clamp[worst, "mid_clamped"]),
                                                      collapse = "; ")), "",
  "## By group",
  sprintf("%-5s %9s %9s %12s", "group", "routed", "balance", "rows"),
  sprintf("%-5s %9d %9d %12.0f", by_group$group, by_group$routed, by_group$balance, by_group$rows)
), con)
close(con)
stamp("report written")
