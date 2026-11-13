# One watershed group's balance and pick from the shipped fit (#157), checked
# against the published product.
#
#   Rscript scripts/segment_group.R <WSG>
#   WET_WB_RESAMPLE=1 Rscript scripts/segment_group.R BULK   # also resample the group and compare
#
# A group's rows need only the polygons FWA_Upstream reaches from them: the
# polygons under its roots (wet_ws_closure()) trimmed to that reach
# (wet_ws_reach(); scripts/segment_group_closure.R counts both). So this
# samples (or reads the province run's samples of) the reach's groups,
# accumulates over the reach alone,
# applies the shipped fit as scripts/wb_output.R does, and gives the group's
# segments their balance rows and pick as scripts/segment_output.R does. Routed
# PCIC is not rebuilt: pick reads its published annual flow. Writes
# (gitignored):
#   <fit>/group/<WSG>/watershed.parquet  watershed_feature_id, watershed_group_code,
#     month, runoff_mm, q_m3s, coverage, bc_fraction, period (rows with a value)
#   <fit>/group/<WSG>/segment.parquet    linear_feature_id, watershed_group_code,
#     month, runoff_mm, q_m3s, coverage, period, pick (the balance's rows)
#   <fit>/group/<WSG>/sample/<G>.rds     samples this run made
# and the tracked report wb_report("segment_group_<WSG>", release), which
# compares every row with the published parts. A row on one side only is
# refused (after the report is written); values beyond 1e-9 relative are
# listed and attributed. Before #158 the donor shares at a calibration gauge
# turned on an exact-zero distance, which the order doubles are added in can
# move; since, a donor within 1e-9 of the median distance is the gauge's own.
#
# WET_WB_RESAMPLE=1 samples the group again and compares it with the province
# run's sample (reported, not refused: terra or GDAL may have moved since),
# then goes on with the province samples. WET_GROUP_DROP=<G>[,<G>] removes
# those groups' polygons from the reach, the deliberate break that shows the
# comparison can fail; its parquet goes under <fit>/group/<WSG>/drop-<G>/ and
# its report to data/logs/157/, not data/checks/.
#
# Run where the province run's layers.tif and samples are (m4). Connection
# from WET_PG*.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
source("scripts/pcic_routed_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
wsg <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(wsg) || !grepl("^[A-Z]{4}$", wsg)) stop("usage: Rscript scripts/segment_group.R <WSG>, e.g. BULK")
resample <- Sys.getenv("WET_WB_RESAMPLE") %in% c("1", "true", "TRUE")
drop_groups <- strsplit(Sys.getenv("WET_GROUP_DROP"), ",")[[1]]
if (wsg %in% drop_groups) stop("WET_GROUP_DROP cannot remove the group itself")
dirty <- git("status", "--porcelain", "--", "R", "scripts")
if (length(dirty)) stop("commit these first, so the recorded commit made the report:\n", paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
times <- numeric()
timed <- function(step, expr) {
  t0 <- Sys.time()
  v <- expr
  times[[step]] <<- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  v
}

# ---- the shipped fit, under segment_output.R's guards ------------------------------------------
key_dir <- wb_key_dir()
release <- wb_release()
if (!identical(release, wb_shipped_release)) stop("the group build applies the shipped fit, ", wb_shipped_release)
fit_dir <- wb_fit_dir(key_dir, release)
source("scripts/wb_score_md5.R")  # score_code_md5
fits <- readRDS(file.path(fit_dir, "fits.rds"))
winner <- readLines(file.path(fit_dir, "aet_winner.txt"))
if (!identical(fits$code_md5, score_code_md5) || !identical(winner[1:2], c(fits$aet, score_code_md5))) {
  stop("the fit in ", fit_dir, " was made or chosen under other scoring code: rerun the fit")
}
aet <- fits$aet
lay_file <- file.path(key_dir, "layers.tif")
bc_file <- file.path(key_dir, "in_bc.tif")
# a deliberate break writes beside the group's real build, never over it
out_dir <- file.path(fit_dir, "group", wsg)
if (length(drop_groups)) out_dir <- file.path(out_dir, paste0("drop-", paste(drop_groups, collapse = "-")))
unlink(file.path(out_dir, c("watershed.parquet", "segment.parquet")))
dir.create(file.path(out_dir, "sample"), recursive = TRUE, showWarnings = FALSE)
pg <- function() {
  DBI::dbConnect(RPostgres::Postgres(),
                 host = Sys.getenv("WET_PGHOST", "localhost"),
                 port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                 dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                 user = Sys.getenv("WET_PGUSER", "postgres"),
                 password = Sys.getenv("WET_PGPASSWORD", "postgres"))
}
conn <- pg()

# ---- the polygons the group's rows reach ------------------------------------------------------------
ws <- timed("closure", wet_ws_closure(conn, wsg))
roots <- attr(ws, "roots")
codes <- attr(ws, "codes")
irr <- attr(ws, "irregular")
n_closure <- nrow(ws)
groups_closure <- attr(ws, "groups")
ws <- timed("reach", ws[wet_ws_reach(ws, ws$watershed_group_code == wsg, irr), ])
# the pairs of the irregular polygons kept (each has its own self pair)
irr <- irr[irr$id_up %in% ws$watershed_feature_id, ]
groups_all <- sort(unique(ws$watershed_group_code), method = "radix")
if (length(drop_groups)) {
  if (!all(drop_groups %in% groups_all)) stop("WET_GROUP_DROP names groups outside the reach")
  ws <- ws[!ws$watershed_group_code %in% drop_groups, ]
  irr <- irr[irr$id_up %in% ws$watershed_feature_id, ]
}
groups <- sort(unique(ws$watershed_group_code), method = "radix")
stamp(wsg, ": ", length(roots), " roots, ", nrow(ws), " polygons in ", length(groups), " groups")

# ---- the published rows of the group, verified before and after the read ---------------------------
cat_pub <- wet_catalog()
prov_bal <- attr(cat_pub, "source_provenance")$wet_balance
if (!identical(c(prov_bal$fit_release, prov_bal$province_run), c(release, basename(key_dir)))) {
  stop("the live build's balance is fit ", prov_bal$fit_release, " of run ", prov_bal$province_run,
       ", not ", release, " of ", basename(key_dir))
}
parts <- cat_pub[cat_pub$scenario == "historical" & cat_pub$code %in% codes &
                   (cat_pub$dataset == "discharge/fwa/v1/segment_monthly" |
                      (cat_pub$dataset == "discharge/fwa/v1/watershed_monthly" & cat_pub$source == "wet_balance")), ]
parts <- parts[order(parts$dataset, parts$source, parts$code, method = "radix"), ]
verify <- function() {
  v <- wet:::wet_catalog_verify(parts)
  if (!all(v$ok)) stop("published parts do not match the manifest (a publish under way?): ",
                       paste(v$key[!v$ok], v$reason[!v$ok], collapse = "; "))
  sum(v$ok)
}
pub <- timed("published read", {
  n_ok_before <- verify()
  duck <- DBI::dbConnect(duckdb::duckdb())
  invisible(DBI::dbExecute(duck, "INSTALL httpfs"))
  invisible(DBI::dbExecute(duck, "LOAD httpfs"))
  x <- DBI::dbGetQuery(duck, sprintf("
    SELECT source, linear_feature_id, watershed_feature_id, month, runoff_mm, q_m3s, coverage,
           bc_fraction, period, pick
    FROM read_parquet([%s], hive_partitioning = true, union_by_name = true)
    WHERE watershed_group_code = '%s'", paste0("'", parts$href, "'", collapse = ", "), wsg))
  DBI::dbDisconnect(duck, shutdown = TRUE)
  n_ok_after <- verify()
  x
})
pub_ws <- pub[!is.na(pub$watershed_feature_id), ]
pub_b <- pub[is.na(pub$watershed_feature_id) & pub$source == "wet_balance", ]
pub_r <- pub[is.na(pub$watershed_feature_id) & pub$source == "pcic_routed", ]
stopifnot(all(pub_ws$source == "wet_balance"), nrow(pub_ws) + nrow(pub_b) + nrow(pub_r) == nrow(pub),
          !anyNA(pub_b$linear_feature_id), !anyNA(pub_r$linear_feature_id))
stamp("published: ", nrow(pub_ws), " watershed rows, ", nrow(pub_b), " balance and ", nrow(pub_r),
      " routed segment rows")

# ---- samples ------------------------------------------------------------------------------------------
# wb_province.R's extent query and sample_group(), copied verbatim (the
# province key hashes that script, so it is not edited to share them); the
# copy writes under this group's directory
ext <- timed("extents", DBI::dbGetQuery(conn, "
  SELECT watershed_group_code wsg,
         ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT watershed_group_code, ST_Extent(ST_Transform(geom, 4326)) e
        FROM whse_basemapping.fwa_watershed_groups_poly GROUP BY 1) x
  ORDER BY 1"))
sample_group <- function(g, lay_file, bc_file, out_dir, pg) {
  terra::setGDALconfig("GDAL_CACHEMAX", "256")
  conn <- pg()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  t0 <- Sys.time()
  ws <- wet_ws_geom(conn, g$wsg)
  e <- terra::ext(g$xmin - 0.05, g$xmax + 0.05, g$ymin - 0.05, g$ymax + 0.05)
  lay <- terra::crop(terra::rast(lay_file), e, snap = "out")
  zones <- sort(unique(stats::na.omit(terra::values(lay[["zone"]], mat = FALSE))))
  base <- lay[[setdiff(names(lay), "zone")]]
  zl <- lapply(zones, function(z) {
    i <- terra::ifel(lay[["zone"]] == z, 1, 0)
    x <- c(i, i * lay[["p_yr"]])
    names(x) <- c(sprintf("z%02d", z), sprintf("zp%02d", z))
    x
  })
  st <- if (length(zl)) c(base, terra::rast(zl)) else base
  v <- wet_ws_sample(st, ws, "area")
  inbc <- wet_ws_sample(terra::crop(terra::rast(bc_file), e, snap = "out"), ws, "area")
  v$in_bc <- inbc$value
  v$watershed_group_code <- g$wsg
  f <- file.path(out_dir, "sample", paste0(g$wsg, ".rds"))
  tmp <- tempfile(fileext = ".rds", tmpdir = dirname(f))
  saveRDS(v, tmp)
  file.rename(tmp, f)
  sprintf("%s %d polygons %.0f s", g$wsg, nrow(ws), as.numeric(Sys.time() - t0, units = "secs"))
}
f_prov <- file.path(key_dir, "sample", paste0(groups, ".rds"))
f_smp <- ifelse(file.exists(f_prov), f_prov, file.path(out_dir, "sample", paste0(groups, ".rds")))
smp_from <- ifelse(file.exists(f_prov), "province run", "sampled here")
todo <- groups[!file.exists(f_prov)]
if (resample) todo <- union(todo, wsg)
if (length(todo) && !all(file.exists(c(lay_file, bc_file)))) stop("no layers.tif or in_bc.tif in ", key_dir)
smp_msgs <- timed("sampling", vapply(todo, function(g) {
  sample_group(ext[ext$wsg == g, ], lay_file, bc_file, out_dir, pg)
}, ""))

# the group sampled again against the province run's sample
parity <- character()
if (resample) {
  a <- readRDS(file.path(key_dir, "sample", paste0(wsg, ".rds")))
  b <- readRDS(file.path(out_dir, "sample", paste0(wsg, ".rds")))
  parity <- if (identical(a, b)) {
    sprintf("%s resampled: identical() to the province run's sample (%d polygons, %d columns)", wsg, nrow(a), ncol(a))
  } else if (!setequal(names(a), names(b)) || !identical(a$watershed_feature_id, b$watershed_feature_id)) {
    sprintf("%s resampled: other columns or polygons than the province run's sample", wsg)
  } else {
    num <- names(a)[vapply(a, is.numeric, TRUE)]
    d <- vapply(num, function(k) max(abs(a[[k]] - b[[k]]), na.rm = TRUE), 0)
    nad <- vapply(num, function(k) sum(is.na(a[[k]]) != is.na(b[[k]])), 0)
    c(sprintf("%s resampled: not identical(); largest difference per column that differs:", wsg),
      sprintf("  %-12s %.3g (NA differs on %d rows)", num[d > 0 | nad > 0], d[d > 0 | nad > 0], nad[d > 0 | nad > 0]))
  }
}

# ---- accumulation over the reach, as wb_province.R does over a basin -------------------------------
up_all <- timed("accumulation", {
  vals <- lapply(f_smp, readRDS)
  cols <- unique(unlist(lapply(vals, names)))
  vals <- do.call(rbind, lapply(vals, function(v) {
    for (k in setdiff(cols, names(v))) v[[k]] <- 0  # a zone absent from a group has share 0
    v[, cols]
  }))
  vals <- vals[vals$watershed_feature_id %in% ws$watershed_feature_id, ]
  ws$in_bc <- vals$in_bc[match(ws$watershed_feature_id, vals$watershed_feature_id)]
  ws$in_bc[is.na(ws$in_bc)] <- 0
  keep <- setdiff(cols, c("in_bc", "watershed_group_code"))
  up <- wet_upstream_means(ws, vals[, keep], irregular_pairs = irr, extra = "in_bc")
  names(up)[names(up) == "in_bc"] <- "bc_fraction"
  up
})
# The basin run carries a zone column for every zone sampled anywhere in the
# basin; the reach carries only its own groups' zones. A zone outside the
# reach is 0 on every upstream polygon of the group's rows, which
# wet_wb_adjust() reads the same as an absent column, so no zone column is
# written and the values do not move.
up <- up_all[ws$watershed_group_code == wsg, ]

# the group's upstream means against the province run's, basin by basin,
# where its upstream/ is on this machine: the same values to summation order,
# and every zone column the reach lacks 0 or NA on the group's rows
f_up <- file.path(key_dir, "upstream", paste0(codes, ".rds"))
up_parity <- if (!all(file.exists(f_up))) {
  "the province run's upstream/ is not on this machine: not compared"
} else {
  timed("province upstream", unlist(lapply(f_up, function(f) {
    pu <- readRDS(f)
    pu <- pu[pu$watershed_feature_id %in% up$watershed_feature_id, ]
    a <- up[match(pu$watershed_feature_id, up$watershed_feature_id), ]
    num <- setdiff(intersect(names(a), names(pu)), c("watershed_feature_id", "wscode", "localcode"))
    num <- num[vapply(pu[num], is.numeric, TRUE)]
    same <- Reduce(`&`, lapply(num, function(k) (a[[k]] == pu[[k]]) %in% TRUE | (is.na(a[[k]]) & is.na(pu[[k]]))))
    rel <- vapply(num, function(k) {
      d <- abs(a[[k]] - pu[[k]]) / pmax(abs(a[[k]]), abs(pu[[k]]))
      if (any(!is.na(d))) max(d, na.rm = TRUE) else 0
    }, 0)
    nad <- sum(vapply(num, function(k) sum(is.na(a[[k]]) != is.na(pu[[k]])), 0))
    zx <- setdiff(grep("^zp?[0-9]+$", names(pu), value = TRUE), names(a))
    zx_nonzero <- sum(vapply(zx, function(k) sum(pu[[k]] != 0, na.rm = TRUE), 0))
    top <- utils::head(sort(rel[rel > 0], decreasing = TRUE), 3)
    c(sprintf("basin %s: %d of %s's watersheds, %d columns; identical in every column: %d; NA on one side: %d",
              sub("\\.rds$", "", basename(f)), nrow(pu), wsg, length(num), sum(same), nad),
      sprintf("  largest relative difference: %s",
              if (length(top)) paste(sprintf("%s %.3g", names(top), top), collapse = ", ") else "none"),
      sprintf("  zone columns of the basin outside the reach: %d, nonzero on the group's rows: %d",
              length(zx), zx_nonzero))
  })))
}

# ---- the fit, as wb_output.R applies it ----------------------------------------------------------------
days <- c(365.25, wet_month_days())
bal <- timed("fit", {
  up$raw <- wet:::wet_wb_raw(up, aet)
  zc <- grep("^zp?[0-9]+$", names(up), value = TRUE)
  known <- c(paste0("z", fits$wb$coef$zone), paste0("zp", fits$wb$coef$zone))
  drop <- setdiff(zc, known)
  ann <- if (fits$keep_adjust) wet_wb_adjust(fits$wb, up[setdiff(names(up), drop)]) else pmax(up$raw, 0)
  sh <- wet_share_predict(fits$share, up)
  mm <- cbind(ann, sh * ann)
  data.frame(
    watershed_feature_id = rep(up$watershed_feature_id, 13),
    watershed_group_code = wsg,
    month = rep(0:12, each = nrow(up)),
    runoff_mm = as.vector(mm),
    q_m3s = as.vector(wet_mm_to_m3s(mm, up$upstream_area_m2, days = rep(days, each = nrow(up)))),
    coverage = rep(up$coverage, 13),
    bc_fraction = rep(up$bc_fraction, 13),
    period = "1981-2010"
  )
})
# the publish drops a watershed with no balance value (discharge_publish.R)
n_ws_na <- sum(is.na(bal$q_m3s))
bal_out <- bal[!is.na(bal$q_m3s), ]

# ---- the group's segments, as segment_output.R gives them their rows and pick -------------------------
seg <- timed("segments", DBI::dbGetQuery(conn, sprintf("
  SELECT s.linear_feature_id::int AS linear_feature_id, l.watershed_feature_id::int AS watershed_feature_id,
         w.watershed_group_code AS ws_group, coalesce(%s, false) AS own_line
  FROM whse_basemapping.fwa_stream_networks_sp s
  LEFT JOIN whse_basemapping.fwa_streams_watersheds_lut l USING (linear_feature_id)
  LEFT JOIN whse_basemapping.fwa_watersheds_poly w ON w.watershed_feature_id = l.watershed_feature_id
  WHERE s.watershed_group_code = $1
  ORDER BY s.linear_feature_id", routed_own_line_sql), params = list(wsg)))
DBI::dbDisconnect(conn)
# a segment's lut watershed lies in the segment's own group, so the group's
# watersheds give its segments every balance value they can have
if (any(!is.na(seg$ws_group) & seg$ws_group != wsg)) stop("a ", wsg, " segment's watershed lies in another group")
stopifnot(!anyDuplicated(seg$linear_feature_id), is.logical(seg$own_line), !anyNA(seg$own_line))
b0 <- bal[bal$month == 0, ]
seg$q_balance <- b0$q_m3s[match(seg$watershed_feature_id, b0$watershed_feature_id)]
r0 <- pub_r[pub_r$month == 0, ]
stopifnot(!anyDuplicated(r0$linear_feature_id), all(r0$linear_feature_id %in% seg$linear_feature_id))
seg$q_routed <- r0$q_m3s[match(seg$linear_feature_id, r0$linear_feature_id)]
seg$source <- wet_source_pick(seg$q_routed, seg$q_balance, routed_far_low, own_line = seg$own_line)
kb <- which(!is.na(seg$q_balance))
sb <- seg[kb, ]
ib <- match(sb$watershed_feature_id, bal$watershed_feature_id[bal$month == 0])
nws <- nrow(up)
stopifnot(identical(bal$month, rep(0:12, each = nws)))
bm <- bal[rep(ib, 13) + rep(0:12 * nws, each = length(ib)), ]
seg_out <- data.frame(
  linear_feature_id = rep(sb$linear_feature_id, 13), watershed_group_code = wsg,
  month = rep(0:12, each = nrow(sb)), runoff_mm = bm$runoff_mm, q_m3s = bm$q_m3s, coverage = bm$coverage,
  period = "1981-2010", pick = rep(sb$source == "wet_balance", 13)
)
seg_out <- seg_out[order(seg_out$linear_feature_id, seg_out$month), ]
for (x in list(list(bal_out, "watershed"), list(seg_out, "segment"))) {
  tmp <- tempfile(fileext = ".parquet", tmpdir = out_dir)
  arrow::write_parquet(x[[1]], tmp)
  if (!file.rename(tmp, file.path(out_dir, paste0(x[[2]], ".parquet")))) stop("could not move ", tmp)
}
stamp(nrow(bal_out), " watershed rows, ", nrow(seg_out), " segment rows written")

# ---- parity with the published product ------------------------------------------------------------------
keys <- function(d, id, time = "month") paste(d[[id]], d[[time]])
one_side <- c(
  watershed = length(setdiff(keys(bal_out, "watershed_feature_id"), keys(pub_ws, "watershed_feature_id"))) +
    length(setdiff(keys(pub_ws, "watershed_feature_id"), keys(bal_out, "watershed_feature_id"))),
  segment = length(setdiff(keys(seg_out, "linear_feature_id"), keys(pub_b, "linear_feature_id"))) +
    length(setdiff(keys(pub_b, "linear_feature_id"), keys(seg_out, "linear_feature_id")))
)
# routed rows: the published pick against the one this build makes for them
rt_pick <- data.frame(linear_feature_id = pub_r$linear_feature_id, month = pub_r$month,
                      pick = as.numeric(seg$source[match(pub_r$linear_feature_id, seg$linear_feature_id)] ==
                                          "pcic_routed"))
num_pick <- function(d) {
  d$pick <- as.numeric(d$pick)
  d
}
cmp <- rbind(
  data.frame(rows = "watershed", value = c("q_m3s", "runoff_mm", "coverage", "bc_fraction"), tol = 1e-9,
             id = "watershed_feature_id"),
  data.frame(rows = "balance segment", value = c("q_m3s", "runoff_mm", "coverage", "pick"),
             tol = c(1e-9, 1e-9, 1e-9, 0), id = "linear_feature_id"),
  data.frame(rows = "routed segment", value = "pick", tol = 0, id = "linear_feature_id")
)
side <- function(rows) {
  switch(rows,
         watershed = list(bal_out, pub_ws),
         `balance segment` = list(num_pick(seg_out), num_pick(pub_b)),
         `routed segment` = list(rt_pick, num_pick(pub_r)))
}
# rows beyond tolerance, largest first
beyond <- function(a, b, id, value, tol) {
  m <- merge(a[c(id, "month", value)], b[c(id, "month", value)], by = c(id, "month"), suffixes = c("_group", "_pub"))
  va <- m[[paste0(value, "_group")]]
  vb <- m[[paste0(value, "_pub")]]
  d <- abs(va - vb)
  bad <- xor(is.na(va), is.na(vb)) | (!is.na(d) & d > tol * pmax(abs(va), abs(vb)))
  m$rel <- d / pmax(abs(va), abs(vb))
  m <- m[bad, ]
  m[order(-m$rel), ]
}
res <- do.call(rbind, lapply(seq_len(nrow(cmp)), function(i) {
  s <- side(cmp$rows[i])
  v <- wet_values_compare(s[[1]], s[[2]], id_col = cmp$id[i], value = cmp$value[i], tol = cmp$tol[i])
  cbind(cmp[i, c("rows", "value", "tol")], t(v))
}))
bad <- lapply(seq_len(nrow(cmp)), function(i) {
  s <- side(cmp$rows[i])
  beyond(s[[1]], s[[2]], cmp$id[i], cmp$value[i], cmp$tol[i])
})
# Attribution. The donor shares give a watershed within 1e-9 of the median
# distance of a calibration gauge's donor row that gauge's shares alone
# (wet_donor_mean(); exactly 0 before #158); further off, the other donors
# weigh in. The province run's own upstream means are the donor rows, so a
# last-bit move in them turns a gauge's exact 0 into about 1e-15, which moved
# its months before #158 and no longer does. The count below is of
# watersheds within an absolute 1e-9 (scaled) of a donor row.
dfit <- switch(fits$share_method, donor = fits$share, blend = fits$share$donor, NULL)
at_gauge <- integer()
if (!is.null(dfit)) {
  xs <- sweep(as.matrix(up[dfit$static]), 2, dfit$sd, "/")
  dmin <- apply(xs, 1, function(r) min(sqrt(colSums((t(dfit$x) - r)^2))))
  at_gauge <- up$watershed_feature_id[!is.na(dmin) & dmin < 1e-9]
  n_gauge0 <- sum(!is.na(dmin) & dmin == 0)
}
ws_bad <- unique(c(unlist(lapply(which(cmp$rows == "watershed"), function(i) bad[[i]]$watershed_feature_id)),
                   seg$watershed_feature_id[match(unlist(lapply(which(cmp$rows != "watershed"), function(i) {
                     bad[[i]]$linear_feature_id
                   })), seg$linear_feature_id)]))
attribution <- c(
  sprintf("watersheds with a row beyond tolerance (either table): %d; at a calibration gauge: %d", length(ws_bad),
          sum(ws_bad %in% at_gauge)),
  if (!is.null(dfit)) {
    sprintf("%s watersheds within 1e-9 (scaled) of a calibration gauge's donor row: %d, exactly 0: %d", wsg,
            length(at_gauge), n_gauge0)
  }
)
lists <- lapply(seq_len(nrow(cmp)), function(i) {
  b <- bad[[i]]
  if (!nrow(b)) return(character())
  h <- utils::head(b, 20)
  c(sprintf("%s %s: %d rows beyond %g relative (largest 20)", cmp$rows[i], cmp$value[i], nrow(b), cmp$tol[i]),
    sprintf("  %-12s %5s %22s %22s %10s", "id", "month", "group", "published", "relative"),
    sprintf("  %-12d %5d %22.15g %22.15g %10.3g", h[[cmp$id[i]]], as.integer(h$month),
            h[[paste0(cmp$value[i], "_group")]], h[[paste0(cmp$value[i], "_pub")]], h$rel))
})

# ---- report -------------------------------------------------------------------------------------------------
f_rep <- if (length(drop_groups)) {
  dir.create("data/logs/157", recursive = TRUE, showWarnings = FALSE)
  file.path("data/logs/157",
            sprintf("segment_group_%s_drop-%s_%s.txt", wsg, paste(drop_groups, collapse = "-"), release))
} else {
  wb_report(paste0("segment_group_", wsg), release)
}
short <- function(v, k = 8) {
  if (length(v) > k) v <- c(v[1:k], sprintf("+%d", length(v) - k))
  paste(v, collapse = ", ")
}
con <- file(f_rep, "w")
writeLines(c(
  sprintf("# One watershed group's balance from the shipped fit: %s (#157)", wsg), "",
  if (length(drop_groups)) {
    c(sprintf("DELIBERATE BREAK: polygons of %s removed from the reach", short(drop_groups)), "")
  },
  sprintf("wet commit %s; fit %s of province run %s; scoring code %s", wet_commit, release, basename(key_dir),
          score_code_md5),
  sprintf("annual AET %s; adjustment %s; monthly shares %s", aet,
          if (fits$keep_adjust) "applied" else "not applied", fits$share_method),
  "", "## Polygons",
  sprintf("roots: %d (%s); top-level drainage codes: %s", length(roots), short(roots, 3),
          paste(codes, collapse = ", ")),
  sprintf("under the roots (wet_ws_closure()): %d polygons in %d groups (%s)", n_closure, length(groups_closure),
          short(groups_closure)),
  sprintf("reached from %s's rows (wet_ws_reach()), used: %d polygons, %d of them %s's, in %d groups (%s);",
          wsg, nrow(ws), sum(ws$watershed_group_code == wsg), wsg, length(groups), short(groups)),
  sprintf("  irregular pairs: %d", nrow(irr)),
  "", "## Samples",
  sprintf("  %-5s %s", groups, smp_from),
  if (length(smp_msgs)) c("sampled by this run:", paste0("  ", smp_msgs)),
  if (length(parity)) c("", parity),
  "", "## Upstream means against the province run's",
  up_parity,
  "", "## Published product",
  sprintf("live build %s (manifest built %s); balance fit %s of run %s", attr(cat_pub, "provenance")$wet_commit,
          attr(cat_pub, "built"), prov_bal$fit_release, prov_bal$province_run),
  sprintf("parts read: %d, all matching the manifest before (%d) and after (%d) the read:", nrow(parts),
          n_ok_before, n_ok_after),
  sprintf("  %s %s", parts$md5, sub("^discharge/fwa/v1/", "", parts$key)),
  sprintf("rows of %s: %d watershed, %d balance segment, %d routed segment", wsg, nrow(pub_ws), nrow(pub_b),
          nrow(pub_r)),
  "", "## This build",
  sprintf("watersheds: %d; with no balance value (dropped, as the publish drops them): %d rows", nrow(up), n_ws_na),
  sprintf("segments: %d; with a balance value: %d; picked balance: %d, routed: %d, neither: %d", nrow(seg),
          length(kb), sum(seg$source %in% "wet_balance"), sum(seg$source %in% "pcic_routed"), sum(is.na(seg$source))),
  sprintf("rows written: %d watershed, %d balance segment", nrow(bal_out), nrow(seg_out)),
  "", "## Time per step (s)",
  sprintf("  %-16s %7.1f", names(times), unlist(times)),
  "", "## Parity: this build against the published rows",
  sprintf("rows on one side only: %d watershed, %d balance segment", one_side[["watershed"]], one_side[["segment"]]),
  sprintf("%-16s %-12s %6s %9s %9s %12s", "rows", "value", "tol", "compared", "differing", "max_abs_diff"),
  sprintf("%-16s %-12s %6g %9d %9d %12.3g", res$rows, res$value, res$tol, as.integer(res$compared),
          as.integer(res$differing), res$max_abs_diff),
  "", attribution,
  if (length(unlist(lists))) c("", unlist(lists))
), con)
close(con)
stamp("report ", f_rep)
if (any(one_side > 0)) {
  stop("rows on one side only: ", paste(names(one_side), one_side, collapse = ", "), "; see ", f_rep)
}
