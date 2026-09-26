# Topology check for wet_upstream_sums() at basin scale (#2): accumulated
# polygon area vs fwapg's fwa_watersheds_upstream_area, which fwapg built with
# the pairwise FWA_Upstream join over ST_Area(geom).
#
# The stored table is a cached snapshot and can predate the polygons now in
# fwa_watersheds_poly (it disagrees with itself: polygons sharing a code pair
# have different stored areas). So every mismatch is re-checked against the
# live FWA_Upstream join, which is the actual reference.
#
#   Rscript scripts/upstream_area_check.R [WSCODE]      # default 100 (Fraser)
#
# Connection from WET_PG* env vars, defaulting to the local fresh-db container.

devtools::load_all(quiet = TRUE)
wscode <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(wscode)) wscode <- "100"

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"),
  port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
  user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres")
)

tm <- function(expr) { t0 <- Sys.time(); v <- expr; list(v = v, s = as.numeric(Sys.time() - t0, units = "secs")) }

f <- tm(wet_ws_fetch(conn, wscode)); ws <- f$v
message(nrow(ws), " polygons fetched in ", round(f$s, 1), " s")
p <- tm(wet_upstream_irregular(conn, wscode)); irr <- p$v
message(nrow(irr), " irregular pairs (", length(unique(irr$id_up)), " polygons) in ",
        round(p$s, 1), " s")
ref <- DBI::dbGetQuery(conn, "
  SELECT u.watershed_feature_id, u.upstream_area_ha * 10000 AS ref_m2
  FROM whse_basemapping.fwa_watersheds_upstream_area u
  JOIN whse_basemapping.fwa_watersheds_poly w USING (watershed_feature_id)
  WHERE w.wscode_ltree <@ $1::ltree", params = list(wscode))
s <- tm(wet_upstream_sums(ws, "area_m2", irregular_pairs = irr))
message("range sums in ", round(s$s, 1), " s")
# deliberately without the correction, to show what it fixes
s0 <- suppressWarnings(wet_upstream_sums(ws, "area_m2"))

cmp <- merge(data.frame(watershed_feature_id = ws$watershed_feature_id,
                        got = s$v$area_m2, got_noirr = s0$area_m2),
             ref, by = "watershed_feature_id", all = TRUE)
rel <- abs(cmp$got - cmp$ref_m2) / cmp$ref_m2
rel0 <- abs(cmp$got_noirr - cmp$ref_m2) / cmp$ref_m2
cat("\n## Upstream area check, basin", wscode, "\n\n")
cat("polygons:", nrow(ws), "| reference rows:", nrow(ref),
    "| missing either side:", sum(is.na(cmp$got) | is.na(cmp$ref_m2)), "\n")
cat("max relative difference:", signif(max(rel, na.rm = TRUE), 3),
    "| mismatches > 1e-9:", sum(rel > 1e-9, na.rm = TRUE), "\n")
cat("without the irregular correction: mismatches > 1e-9:", sum(rel0 > 1e-9, na.rm = TRUE),
    "| max", signif(max(rel0, na.rm = TRUE), 3), "\n")
cat("timing (s): fetch", round(f$s, 1), "| irregular", round(p$s, 1),
    "| sums", round(s$s, 1), "\n")
# ---- re-check mismatches against the live FWA_Upstream join -----------------
bad <- cmp[!is.na(rel) & rel > 1e-9, ]
n_live <- as.integer(Sys.getenv("WET_LIVE_MAX", "400"))
set.seed(1)
chk <- if (nrow(bad) > n_live) bad[sample(nrow(bad), n_live), ] else bad
# the basin mouth (largest upstream area) always, as the heaviest case
chk <- unique(rbind(chk, cmp[which.max(cmp$got), ]))
live <- if (nrow(chk)) DBI::dbGetQuery(conn, "
  SELECT a.watershed_feature_id, sum(ST_Area(b.geom)) AS live_m2
  FROM whse_basemapping.fwa_watersheds_poly a
  JOIN whse_basemapping.fwa_watersheds_poly b
    ON whse_basemapping.FWA_Upstream(a.wscode_ltree, a.localcode_ltree,
                                     b.wscode_ltree, b.localcode_ltree)
  WHERE a.watershed_feature_id = ANY($1::integer[])
  GROUP BY a.watershed_feature_id",
  params = list(paste0("{", paste(chk$watershed_feature_id, collapse = ","), "}")))
DBI::dbDisconnect(conn)
chk <- merge(chk, live, by = "watershed_feature_id")
rel_live <- abs(chk$got - chk$live_m2) / chk$live_m2
rel_ref <- abs(chk$ref_m2 - chk$live_m2) / chk$live_m2
cat("\nlive FWA_Upstream re-check of", nrow(chk), "mismatched polygons",
    "(of", nrow(bad), "; includes the basin mouth):\n")
cat("  wet == live (<= 1e-9):", sum(rel_live <= 1e-9), "| stored == live:", sum(rel_ref <= 1e-9), "\n")
cat("  max |wet - live| / live:", signif(max(rel_live), 3), "\n")
m <- chk[which.max(chk$got), ]
cat("  basin mouth", m$watershed_feature_id, ": wet", signif(m$got, 10), "| live",
    signif(m$live_m2, 10), "| stored", signif(m$ref_m2, 10), "\n")
if (any(rel_live > 1e-9)) { cat("\nwet vs live disagreements:\n"); print(chk[rel_live > 1e-9, ]) }
