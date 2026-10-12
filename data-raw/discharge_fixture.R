# A tiny published-discharge tree for the wet_catalog() example and the tests:
# inst/extdata/discharge/fwa/v1/, laid out as s3://fresh-bc/discharge/fwa/v1/.
#
#   Rscript data-raw/discharge_fixture.R
#
# Two segments and one fundamental watershed in one drainage code (100), with
# made-up values: it exercises the layout and the manifest, not hydrology.
# Segment 1 picks routed, segment 2 the balance.

pkgload::load_all(quiet = TRUE)
root <- file.path("inst", "extdata", "discharge", "fwa", "v1")
unlink(root, recursive = TRUE)

seg_rows <- function(id, q_ann, runoff_ann, coverage, period, pick) {
  data.frame(
    linear_feature_id = as.integer(id), watershed_group_code = "SALR", month = 0:12,
    runoff_mm = c(runoff_ann, runoff_ann * c(2, 2, 3, 6, 16, 22, 17, 10, 7, 6, 5, 4) / 100),
    q_m3s = c(q_ann, q_ann * c(2, 2, 3, 6, 16, 22, 17, 10, 7, 6, 5, 4) / 100 * 12),
    coverage = coverage, period = period, pick = pick
  )
}
parts <- list(
  "segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-100.parquet" =
    rbind(seg_rows(701001, 2.4, 610, NA_real_, "1951-2012", TRUE),
          seg_rows(701002, 0.05, 40, NA_real_, "1951-2012", FALSE)),
  "segment_monthly/scenario=historical/forcing=climr/source=wet_balance/part-100.parquet" =
    rbind(seg_rows(701001, 2.1, 540, 1, "1981-2010", FALSE),
          seg_rows(701002, 0.6, 480, 1, "1981-2010", TRUE)),
  "watershed_monthly/scenario=historical/forcing=climr/source=wet_balance/part-100.parquet" =
    data.frame(watershed_feature_id = 9001L, watershed_group_code = "SALR", month = 0:12,
               runoff_mm = c(540, 540 * c(2, 2, 3, 6, 16, 22, 17, 10, 7, 6, 5, 4) / 100),
               q_m3s = c(2.1, 2.1 * c(2, 2, 3, 6, 16, 22, 17, 10, 7, 6, 5, 4) / 100 * 12),
               coverage = 1, bc_fraction = 1, period = "1981-2010")
)

con <- DBI::dbConnect(duckdb::duckdb())
for (key in names(parts)) {
  f <- file.path(root, key)
  dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
  duckdb::duckdb_register(con, "part", parts[[key]])
  DBI::dbExecute(con, sprintf("COPY part TO '%s' (FORMAT parquet)", f))
  duckdb::duckdb_unregister(con, "part")
}
DBI::dbDisconnect(con, shutdown = TRUE)

wet_manifest_write(
  root, "discharge/fwa/v1",
  drainage = c("100" = "Fraser River"),
  sources = data.frame(
    source = c("pcic_routed", "wet_balance"),
    description = c("Made-up routed values for the package fixture.",
                    "Made-up balance values for the package fixture."),
    citation = c("Fixture; not data.", "Fixture; not data.")
  ),
  provenance = list(wet_version = "fixture", wet_commit = "fixture"),
  built = as.POSIXct("2026-10-12 00:00:00", tz = "UTC")
)
