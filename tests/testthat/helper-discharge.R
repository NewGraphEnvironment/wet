# A tiny made-up published-discharge tree, laid out as
# s3://fresh-bc/discharge/fwa/v1/: two segments and one fundamental watershed
# in drainage code 100, watershed group SALR. Segment 701001 picks routed, 701002
# the balance. The daily parts are keyed by the group, as the published ones are.
# data-raw/discharge_fixture.R builds the shipped manifest from it.

discharge_fixture_parts <- function() {
  shares <- c(2, 2, 3, 6, 16, 22, 17, 10, 7, 6, 5, 4) / 100
  seg <- function(id, q, mm, coverage, period, pick) {
    data.frame(linear_feature_id = as.integer(id), watershed_group_code = "SALR", month = 0:12,
               runoff_mm = c(mm, mm * shares), q_m3s = c(q, q * shares * 12),
               coverage = coverage, period = period, pick = pick)
  }
  # the days: each month's flow, rising through the month, so a day differs from its month
  m <- wet_doy_month()
  ramp <- unlist(lapply(wet_doy_days(), function(n) seq(0.5, 1.5, length.out = n)))
  day <- function(id, q, mm, coverage, pick) {
    qd <- (q * shares * 12)[m] * ramp
    data.frame(linear_feature_id = as.integer(id), watershed_group_code = "SALR", doy = 1:365,
               runoff_mm = qd / q * mm / 365.25,
               q_m3s = qd, coverage = coverage, period = "1981-2010", pick = pick)
  }
  list(
    "segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-100.parquet" =
      rbind(seg(701001, 2.4, 610, NA_real_, "1951-2012", TRUE),
            seg(701002, 0.05, 40, NA_real_, "1951-2012", FALSE)),
    "segment_monthly/scenario=historical/forcing=climr/source=wet_balance/part-100.parquet" =
      rbind(seg(701001, 2.1, 540, 1, "1981-2010", FALSE),
            seg(701002, 0.6, 480, 1, "1981-2010", TRUE)),
    "segment_daily/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-SALR.parquet" =
      rbind(day(701001, 2.4, 610, NA_real_, TRUE), day(701002, 0.05, 40, NA_real_, FALSE)),
    "segment_daily/scenario=historical/forcing=climr/source=wet_balance/part-SALR.parquet" =
      rbind(day(701001, 2.1, 540, 1, FALSE), day(701002, 0.6, 480, 1, TRUE)),
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
  wet_manifest_write(root, "discharge/fwa/v1", drainage = c("100" = "Fraser River", SALR = "Salmon River"),
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

# The fixture tree with a made-up fit beside it and a receipt (#160, #161), as
# a build since #164 publishes, or a skip without crate.
discharge_fixture_inputs <- function() {
  list(province_run = "fixture", fit = "fixture", hydat_release = "fixture", pcic_routed = "fixture",
       pcic_routed_daily = "fixture", fwapg = "fixture")
}

local_discharge_tree_fit <- function(env = parent.frame()) {
  testthat::skip_if_not_installed("crate")
  root <- local_discharge_tree(env)
  dir.create(file.path(root, "fit", "sample"), recursive = TRUE)
  saveRDS(list(aet = "cfu"), file.path(root, "fit", "fits.rds"))
  con <- DBI::dbConnect(duckdb::duckdb())
  duckdb::duckdb_register(con, "s", data.frame(watershed_feature_id = 9001L, p_mm = 800, in_bc = 1))
  DBI::dbExecute(con, sprintf("COPY s TO '%s' (FORMAT parquet)", file.path(root, "fit", "sample", "part-SALR.parquet")))
  DBI::dbDisconnect(con, shutdown = TRUE)
  built <- as.POSIXct("2026-10-12 00:00:00", tz = "UTC")
  fit_files <- c(fits = "fit/fits.rds", sample = "fit/sample/part-SALR.parquet")
  parts <- names(discharge_fixture_parts())
  rc <- wet_receipt_write(root, "discharge/fwa/v1", strrep("a", 40), "fixture", discharge_fixture_inputs(),
                          list(crate_version = "0.0.0"), c(parts, unname(fit_files)), built = built)
  wet_manifest_write(root, "discharge/fwa/v1", drainage = c("100" = "Fraser River", SALR = "Salmon River"),
                     sources = discharge_fixture_sources(),
                     provenance = list(wet_version = "fixture", wet_commit = "fixture"),
                     crate_version = "0.0.0", built = built,
                     fit = list(release = "fixture", province_run = "fixture", score_code_md5 = strrep("0", 32),
                                description = "A made-up fit.", citation = "Fixture; not data.",
                                files = fit_files),
                     receipt = rc)
  root
}
