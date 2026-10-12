# A tiny made-up published-discharge tree, laid out as
# s3://fresh-bc/discharge/fwa/v1/: two segments and one fundamental watershed
# in drainage code 100. Segment 701001 picks routed, 701002 the balance.
# data-raw/discharge_fixture.R builds the shipped manifest from it.

discharge_fixture_parts <- function() {
  shares <- c(2, 2, 3, 6, 16, 22, 17, 10, 7, 6, 5, 4) / 100
  seg <- function(id, q, mm, coverage, period, pick) {
    data.frame(linear_feature_id = as.integer(id), watershed_group_code = "SALR", month = 0:12,
               runoff_mm = c(mm, mm * shares), q_m3s = c(q, q * shares * 12),
               coverage = coverage, period = period, pick = pick)
  }
  list(
    "segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-100.parquet" =
      rbind(seg(701001, 2.4, 610, NA_real_, "1951-2012", TRUE),
            seg(701002, 0.05, 40, NA_real_, "1951-2012", FALSE)),
    "segment_monthly/scenario=historical/forcing=climr/source=wet_balance/part-100.parquet" =
      rbind(seg(701001, 2.1, 540, 1, "1981-2010", FALSE),
            seg(701002, 0.6, 480, 1, "1981-2010", TRUE)),
    "watershed_monthly/scenario=historical/forcing=climr/source=wet_balance/part-100.parquet" =
      data.frame(watershed_feature_id = 9001L, watershed_group_code = "SALR", month = 0:12,
                 runoff_mm = c(540, 540 * shares), q_m3s = c(2.1, 2.1 * shares * 12),
                 coverage = 1, bc_fraction = 1, period = "1981-2010")
  )
}

discharge_fixture_sources <- function() {
  list(
    list(source = "pcic_routed", description = "Made-up routed values.", citation = "Fixture; not data.",
         provenance = list(routed_table = "fixture")),
    list(source = "wet_balance", description = "Made-up balance values.", citation = "Fixture; not data.",
         provenance = list(fit_release = "fixture"))
  )
}

# write the tree and its manifest under `root`
discharge_fixture_write <- function(root) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  parts <- discharge_fixture_parts()
  for (key in names(parts)) {
    f <- file.path(root, key)
    dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
    duckdb::duckdb_register(con, "part", parts[[key]])
    DBI::dbExecute(con, sprintf("COPY part TO '%s' (FORMAT parquet)", f))
    duckdb::duckdb_unregister(con, "part")
  }
  wet_manifest_write(root, "discharge/fwa/v1", drainage = c("100" = "Fraser River"),
                     sources = discharge_fixture_sources(),
                     provenance = list(wet_version = "fixture", wet_commit = "fixture"),
                     crate_version = "0.0.0", built = as.POSIXct("2026-10-12 00:00:00", tz = "UTC"))
}

# the fixture tree in a temporary directory, or a skip without duckdb
local_discharge_tree <- function(env = parent.frame()) {
  testthat::skip_if_not_installed("duckdb")
  root <- file.path(withr::local_tempdir(.local_envir = env), "discharge", "fwa", "v1")
  dir.create(root, recursive = TRUE)
  discharge_fixture_write(root)
  root
}
