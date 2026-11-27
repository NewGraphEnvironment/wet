# Which product covers which watershed group (#169, #5): the published 1981-2010
# product (routed PCIC and the balance, and which `pick` takes), PCIC's routed
# network and domains, PCIC's gridded runs, CMIP6 by domain, what scenarios build
# on (rule 3 of the channel-scale pilot, with scripts/scenario_basis.R's verdicts
# where they ran), and how each source scores at the calibration gauges in the
# group.
#
#   WET_FWAPG_COMMIT=<sha> WET_DATA_ROOT=<data dir> Rscript scripts/pcic_coverage.R
#
# Inputs, each held to the record it must equal:
#   - the live build's segment_monthly parts (wet_catalog(), duckdb over httpfs),
#     under scripts/vignette_data_lib.R's guards: a clean tree, the routed table the
#     tracked routed report scored, a passing publish report naming the live build,
#     the tracked segment report the build read, and the parts held to their
#     manifest md5s before and after the read. Each source's month-0 rows are held
#     to the publish report's rows over 13, and every group's picks to the segment
#     report's;
#   - fwapg's pcic schema (crosswalk and segment weights) and watershed groups;
#   - PCIC's gridded PNWNAmet run: one day of the cached Peace, Fraser and Columbia
#     subsets under <data root>/pcic/ (no request: PCIC's /data/ is asked first, #169);
#   - the channel-scale pilot's report (CMIP6 GCMs by domain) and
#     scripts/scenario_basis.R's (rules 4 and 5);
#   - the calibration gauges and their month-0 errors (inst/vignette-data/monthly_values.rds).
#
# Report: data/checks/pcic_coverage_<release>.txt (tracked), with the group table
# written to <data root>/pcic_coverage/coverage_<release>.tsv, whose md5 the report
# names; scripts/pcic_coverage_map.R draws it. Findings: research/pcic_scenarios.md.

source("scripts/vignette_data_lib.R")
wet_commit <- vd_commit()
devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")          # wb_release(), wb_report()
source("scripts/pcic_routed_lib.R")     # routed_*
source("scripts/scenario_basis_lib.R")  # domain_of(), pilot_with_outlet()
sf::sf_use_s2(FALSE)

release <- wb_release()
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
stopifnot(dir.exists(data_root))
out_dir <- file.path(data_root, "pcic_coverage")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
f_report <- file.path("data", "checks", sprintf("pcic_coverage_%s.txt", release))
f_table <- file.path(out_dir, sprintf("coverage_%s.tsv", release))
f_pilot <- file.path("data", "checks", sprintf("channel_scale_pilot_%s.txt", release))
f_basis <- file.path("data", "checks", sprintf("scenario_basis_%s.txt", release))
f_bundle <- file.path("inst", "vignette-data", "monthly_values.rds")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
domains <- c("Fraser", "Coast", "Columbia", "Peace")
# the classes' breaks, fixed in the plan before the table was read (#169)
cut_hi <- 0.95
cut_lo <- 0.05
far_low <- routed_far_low

# ---- the published product, by group ------------------------------------------------------------
rc <- vd_routed_check(release)
pb <- vd_published(release)
seg <- vd_segment_report(pb, release)
parts <- pb$catalog[pb$catalog$dataset == "discharge/fwa/v1/segment_monthly" & pb$catalog$scenario == "historical", ]
vd_verify(parts)
stamp("reading month 0 of ", nrow(parts), " parts")
duck <- DBI::dbConnect(duckdb::duckdb())
invisible(DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;"))
pub <- DBI::dbGetQuery(duck, sprintf("
  SELECT watershed_group_code,
         count(DISTINCT linear_feature_id)::double AS segments,
         count(*) FILTER (WHERE source = 'pcic_routed')::double AS routed,
         count(*) FILTER (WHERE source = 'wet_balance')::double AS balance,
         count(*) FILTER (WHERE source = 'pcic_routed' AND pick)::double AS pick_routed,
         count(*) FILTER (WHERE source = 'wet_balance' AND pick)::double AS pick_balance
  FROM read_parquet([%s], hive_partitioning = true)
  WHERE month = 0
  GROUP BY watershed_group_code ORDER BY watershed_group_code", paste0("'", parts$href, "'", collapse = ", ")))
DBI::dbDisconnect(duck, shutdown = TRUE)
vd_verify(parts)
rows_of <- function(s) pb$reader$rows[pb$reader$source == s]
picks_of <- function(s) pb$reader$picked[pb$reader$source == s]
stopifnot(sum(pub$routed) * 13 == rows_of("pcic_routed"), sum(pub$balance) * 13 == rows_of("wet_balance"),
          sum(pub$pick_routed) == picks_of("pcic_routed"), sum(pub$pick_balance) == picks_of("wet_balance"),
          all(pub$pick_routed + pub$pick_balance == pub$segments))
# every group's picks are the segment report's
h <- grep("^## By watershed group", seg$lines)
tab <- seg$lines[(h + 3L):length(seg$lines)]
tab <- tab[grepl("^[A-Z]{4} ", tab)]
sr <- do.call(rbind, lapply(strsplit(trimws(tab), " +"), function(f) {
  data.frame(watershed_group_code = f[1], seg_routed = as.numeric(f[3]), seg_balance = as.numeric(f[4]))
}))
m <- match(pub$watershed_group_code, sr$watershed_group_code)
if (anyNA(m) || any(sr$seg_routed[m] != pub$pick_routed) || any(sr$seg_balance[m] != pub$pick_balance)) {
  stop("a group's picks in the parts are not the segment report's", call. = FALSE)
}

# ---- fwapg: groups, routed outlets and domains --------------------------------------------------
conn <- vd_connect()
grp <- sf::st_read(conn, quiet = TRUE, query = "
  SELECT watershed_group_code, watershed_group_name, ST_Area(geom) AS area_m2, geom
  FROM whse_basemapping.fwa_watershed_groups_poly ORDER BY watershed_group_code")
stopifnot(nrow(grp) == 246L, !anyDuplicated(grp$watershed_group_code))
outlets <- DBI::dbGetQuery(conn, "
  SELECT s.watershed_group_code, count(*)::double precision AS placed_outlets
  FROM pcic.fwa_crosswalk x JOIN whse_basemapping.fwa_stream_networks_sp s ON s.linear_feature_id = x.linear_feature_id
  WHERE x.flag IS NULL GROUP BY s.watershed_group_code ORDER BY s.watershed_group_code")
sw <- DBI::dbGetQuery(conn, "
  SELECT watershed_group_code, subid / 1000000 AS prefix, count(*)::double precision AS n
  FROM pcic.segment_weights GROUP BY 1, 2 ORDER BY 1, 2")
DBI::dbDisconnect(conn)
sw$domain <- domain_of(sw$prefix * 1e6)
dom_n <- tapply(sw$n, list(sw$watershed_group_code, factor(sw$domain, domains)), sum)
dom_n[is.na(dom_n)] <- 0

# ---- PCIC's gridded run: the share of each group's area on cells with values -------------------
f_grid <- sort(list.files(file.path(data_root, "pcic"),
                          "^TPS_gridded_obs_init_RUNOFF_t13149-13513_y[0-9]+-[0-9]+_x[0-9]+-[0-9]+\\.nc$",
                          full.names = TRUE))
f_grid <- f_grid[!grepl("_y210-224_x254-270", f_grid)]   # a 15-cell test box, inside the Fraser's
stopifnot(length(f_grid) == 3L)
cells <- do.call(rbind, lapply(f_grid, function(f) {
  r <- terra::rast(f)[[1]]
  if (!nzchar(terra::crs(r))) terra::crs(r) <- "EPSG:4326"   # PCIC's grid is longitude and latitude
  p <- terra::as.polygons(!is.na(r), dissolve = TRUE)
  sf::st_as_sf(p[p[[1]][, 1] == 1, ])[0]
}))
cells <- sf::st_union(sf::st_transform(sf::st_make_valid(cells), 3005))
# each group's area on cells with values, one group at a time
grp$gridded <- vapply(seq_len(nrow(grp)), function(i) {
  x <- sf::st_intersection(sf::st_geometry(grp)[i], cells)
  if (length(x)) sum(as.numeric(sf::st_area(x))) else 0
}, 1) / grp$area_m2

# ---- CMIP6 by domain (the pilot), rules 4 and 5 (scenario_basis) -------------------------------
pilot <- readLines(f_pilot)
h <- grep("^## Domains", pilot)
gcm_by_dom <- vapply(domains, function(d) {
  row <- grep(paste0("^", d, " "), pilot[(h + 1L):(h + 6L)], value = TRUE)
  as.integer(strsplit(trimws(row), " +")[[1]][4])
}, 1L)
basis <- readLines(f_basis)
r4_ran <- !any(grepl("^not run: ", basis[grep("^## Rule 4", basis):grep("^## Rule 5", basis)]))
r5_ran <- !any(grepl("^CMIP5 score: not run: ", basis))
r5_verdict <- sub("^verdict: ", "", grep("^verdict: ", basis, value = TRUE))
# rule 3's product for each domain, from the pilot's verdict column (the text before its first comma)
product <- vapply(domains, function(d) {
  row <- grep(paste0("^", d, " "), pilot[(h + 1L):(h + 6L)], value = TRUE)
  v <- sub(",.*$", "", sub("^.* (pass|fail) +", "", row))
  if (!v %in% c("CMIP5 gridded", "CMIP6 routed")) stop("the pilot's verdict for ", d, " is not a product: ", v, call. = FALSE)
  v
}, "")
if (r5_ran && !identical(r5_verdict, "the Fraser builds on CMIP5 gridded")) product[["Fraser"]] <- "undecided"

# ---- the calibration gauges ----------------------------------------------------------------------
gb <- readRDS(f_bundle)$gauges
g0 <- gb[gb$month == 0, ]
g0$scored <- !is.na(g0$routed_mm) & g0$routed_mm >= far_low * g0$obs_mm
g0$err_rt <- 100 * (g0$routed_mm / g0$obs_mm - 1)
g0$err_wb <- 100 * (g0$wb_mm / g0$obs_mm - 1)

# ---- the table -----------------------------------------------------------------------------------
tb <- sf::st_drop_geometry(grp)[c("watershed_group_code", "watershed_group_name", "area_m2", "gridded")]
pm <- match(tb$watershed_group_code, pub$watershed_group_code)
for (k in c("segments", "routed", "balance", "pick_routed", "pick_balance")) {
  tb[[k]] <- ifelse(is.na(pm), 0, pub[[k]][pm])
}
tb$routed_share <- ifelse(tb$segments > 0, tb$routed / tb$segments, 0)
tb$placed_outlets <- outlets$placed_outlets[match(tb$watershed_group_code, outlets$watershed_group_code)]
tb$placed_outlets[is.na(tb$placed_outlets)] <- 0
dn <- dom_n[match(tb$watershed_group_code, rownames(dom_n)), , drop = FALSE]
dn[is.na(dn)] <- 0
tb$weighted <- rowSums(dn)
share_of <- function(d) ifelse(tb$weighted > 0, dn[, d] / tb$weighted, 0)
for (d in domains) tb[[paste0("dom_", tolower(d))]] <- share_of(d)
tb$domains <- apply(dn, 1, function(x) paste(domains[x > 0], collapse = "+"))
tb$cmip6_gcms <- apply(dn, 1, function(x) if (any(x > 0)) min(gcm_by_dom[domains[x > 0]]) else NA_integer_)
prod_share <- t(apply(dn, 1, function(x) tapply(x, factor(product[domains], unique(product)), sum)))
prod_share <- prod_share / pmax(tb$weighted, 1)
tb$builds_on <- apply(prod_share, 1, function(x) paste(names(x)[x > 0], collapse = "+"))
tb$class_pub <- ifelse(tb$routed_share >= cut_hi, "both", ifelse(tb$routed_share >= cut_lo, "routed on part",
                                                                  "balance alone"))
top <- apply(prod_share, 1, function(x) if (any(x >= cut_hi)) names(x)[x >= cut_hi][1] else NA_character_)
two <- apply(prod_share, 1, function(x) sum(x >= cut_lo) >= 2)
tb$class_scen <- ifelse(tb$routed_share < cut_lo, "none",
                        ifelse(tb$routed_share >= cut_hi & !is.na(top) & !two, top, "part or mixed"))
gg <- split(g0, g0$watershed_group_code)
tb$gauges <- vapply(tb$watershed_group_code, function(k) if (is.null(gg[[k]])) 0L else nrow(gg[[k]]), 1L)
tb$scored <- vapply(tb$watershed_group_code, function(k) if (is.null(gg[[k]])) 0L else sum(gg[[k]]$scored), 1L)
tb$mae_routed <- vapply(tb$watershed_group_code, function(k) {
  x <- gg[[k]]
  if (is.null(x) || !any(x$scored)) NA_real_ else mean(abs(x$err_rt[x$scored]))
}, 1)
tb$mae_balance <- vapply(tb$watershed_group_code, function(k) {
  x <- gg[[k]]
  if (is.null(x)) NA_real_ else mean(abs(x$err_wb))
}, 1)
stopifnot(sum(tb$segments) == sum(pub$segments), sum(tb$gauges) == nrow(g0),
          all(tb$class_pub %in% c("both", "routed on part", "balance alone")),
          all(tb$class_scen %in% c(unique(product), "part or mixed", "none")))

# the table the map draws, and its md5
out <- tb
num <- vapply(out, is.numeric, TRUE)
out[num] <- lapply(out[num], function(x) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = 4)))
utils::write.table(out, f_table, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
table_md5 <- unname(tools::md5sum(f_table))

# ---- report --------------------------------------------------------------------------------------
pct <- function(x) sprintf("%5.1f", 100 * x)
f1 <- function(x) ifelse(is.na(x), "    -", sprintf("%5.1f", x))
count_by <- function(cls, lev) vapply(lev, function(k) sum(cls == k), 1L)
scen_lev <- c(unique(product), "part or mixed", "none")
by_dom <- vapply(domains, function(d) sum(dn[, d] > 0), 1L)
rep <- c(
  sprintf("# Which product covers which watershed group (#169, #5), HYDAT %s", release),
  "",
  "## Provenance",
  sprintf("wet commit %s; live build %s (segment table %s); %d segment_monthly parts, historical",
          wet_commit, pb$build_commit, pb$segment_commit, nrow(parts)),
  sprintf("live parts md5 %s; verified against the manifest before and after the read", wet:::wet_catalog_digest(parts)),
  routed_report_line(rc$commit),
  paste("table:", rc$fingerprint),
  sprintf("held to %s (rows over 13, picks) and %s (each group's picks)", pb$report, seg$report),
  sprintf("gridded cells: one day of %d cached PNWNAmet subsets (Peace, Fraser, Columbia; no request): %s",
          length(f_grid), md5_text(unname(tools::md5sum(f_grid)))),
  "  the CMIP5 runs' domain is PCIC's statement (the same three basins), not measured here",
  sprintf("CMIP6 GCMs by domain: the pilot's listings at its scored gauges' outlets (%s): %s", f_pilot,
          paste(sprintf("%s %d", domains, gcm_by_dom), collapse = ", ")),
  sprintf("rules 4 and 5 (%s): rule 4 %s; rule 5's CMIP5 score %s", f_basis, if (r4_ran) "ran" else "not run",
          if (r5_ran) paste("ran:", r5_verdict) else "not run"),
  sprintf("gauges: %s md5 %s", f_bundle, unname(tools::md5sum(f_bundle))),
  sprintf("group table: <data root>/pcic_coverage/%s md5 %s", basename(f_table), table_md5),
  "",
  "## Classes (breaks fixed before the table was read)",
  "a group's segments: those with a month-0 row from either source; routed share: those with a routed row over all",
  sprintf("published sources: both (routed share >= %.2f), routed on part (%.2f to %.2f), balance alone (< %.2f)",
          cut_hi, cut_lo, cut_hi, cut_lo),
  sprintf(paste("what scenarios build on (rule 3's product by PCIC domain, over the group's segments in",
                "pcic.segment_weights): one product where the routed share is >= %.2f and >= %.2f of those segments",
                "lie in its domains; part or mixed where the routed share is %.2f to %.2f or two products each hold",
                ">= %.2f; none where the routed share is < %.2f"), cut_hi, cut_hi, cut_lo, cut_hi, cut_lo, cut_lo),
  sprintf("rule 3's product: %s", paste(sprintf("%s %s", names(product), product), collapse = "; ")),
  if (!r5_ran) "  CMIP5 gridded in the Fraser waits on rule 5 (scripts/scenario_basis.R), not run" else NULL,
  if (!r4_ran) "  CMIP6 routed waits on rule 4 (what each run lacks), not run" else NULL,
  "",
  "## Summary",
  sprintf("groups: %d; with a segment value: %d; segments with a value: %.0f", nrow(tb), sum(tb$segments > 0),
          sum(tb$segments)),
  sprintf("published sources: %s", paste(sprintf("%s %d", c("both", "routed on part", "balance alone"),
                                                  count_by(tb$class_pub, c("both", "routed on part", "balance alone"))),
                                          collapse = "; ")),
  sprintf("what scenarios build on: %s", paste(sprintf("%s %d", scen_lev, count_by(tb$class_scen, scen_lev)),
                                               collapse = "; ")),
  sprintf("groups with segments in each PCIC domain: %s; in none: %d",
          paste(sprintf("%s %d", domains, by_dom), collapse = ", "), sum(tb$weighted == 0)),
  sprintf("groups with any area on PCIC's gridded cells: %d (>= %.2f of their area: %d)", sum(tb$gridded > 0),
          cut_hi, sum(tb$gridded >= cut_hi)),
  sprintf("calibration gauges: %d in %d groups; routed scored at %d (carries >= %.1f of observed flow)",
          nrow(g0), sum(tb$gauges > 0), sum(g0$scored), far_low),
  "",
  "products #5 names that are not in this table, and why:",
  "  GEOGLOWS v2: no report scores it yet",
  "  TerraClimate runoff: no report scores it yet",
  "  the 1961-1990 runoff isolines: no report scores them yet",
  "  the BC Water Tool's modelled estimates: not released (the Province's; contact goes through the owner)",
  "products in this table and the tracked reports that score them:",
  "  routed PCIC: pcic_routed_compare, gauge_monthly_compare",
  "  the balance: the shipped fit's held-out scores (wb_validate), gauge_monthly_compare",
  "  PCIC's gridded PNWNAmet run through fwapg: research/water_balance_method.md section 0 (no report of its own)",
  "  WALLY's zone regressions (beside the balance, not by group): wally_compare",
  "",
  "## By watershed group",
  paste("group  segments  routed%  outlets  Fraser% Coast% Columbia% Peace%  gridded%  CMIP6  builds on",
        "                       published         scenarios       gauges scored  MAE rt  MAE wb"),
  sprintf("%-5s %9.0f  %s %8.0f  %s %s %s %s  %s %6s  %-26s %-17s %-17s %6d %6d  %s  %s",
          tb$watershed_group_code, tb$segments, pct(tb$routed_share), tb$placed_outlets,
          pct(tb$dom_fraser), pct(tb$dom_coast), pct(tb$dom_columbia), pct(tb$dom_peace), pct(tb$gridded),
          ifelse(is.na(tb$cmip6_gcms), "-", tb$cmip6_gcms), ifelse(nzchar(tb$builds_on), tb$builds_on, "-"),
          tb$class_pub, tb$class_scen, tb$gauges, tb$scored, f1(tb$mae_routed), f1(tb$mae_balance)),
  "routed%: segments with a routed row over segments with a value; Fraser% ... Peace%: the group's segments in",
  "pcic.segment_weights by their sub-basin's domain; gridded%: area on PCIC's gridded cells; CMIP6: GCMs listed in",
  "every domain the group lies in; MAE: mean absolute percent error of month-0 runoff at the group's gauges (routed",
  "at the scored gauges, the balance held out at all)"
)
writeLines(rep, f_report)
stamp("wrote ", f_report)
