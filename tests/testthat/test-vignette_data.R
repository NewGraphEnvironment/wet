# The vignettes run on data bundled by data-raw/station_vignette_*.R (#27)
# and data-raw/segment_vignette_*.R (#28), never on HYDAT, fwapg or the network.

vignette_data <- function(f) system.file("vignette-data", f, package = "wet")

test_that("each vignette's bundled data stays under 500 KB", {
  files <- list.files(system.file("vignette-data", package = "wet"))
  # every bundled file belongs to one vignette's budget
  budget <- list(station = c("station_daily.rds", "station_map.rds", "life_history_bulk.csv"),
                 segment = c("segment_values.rds", "segment_map.rds"))
  expect_setequal(files, unlist(budget))
  for (v in names(budget)) {
    expect_lt(sum(file.size(vignette_data(budget[[v]]))), 500 * 1024)
  }
})

test_that("the daily series has both stations, all three sources and its provenance", {
  d <- readRDS(vignette_data("station_daily.rds"))
  expect_named(d, c("station_number", "date", "q_m3s", "symbol", "source", "status"))
  expect_s3_class(d$date, "Date")
  expect_setequal(unique(d$station_number), c("08EE013", "08EE003"))
  for (st in c("08EE013", "08EE003")) {
    expect_setequal(unique(d$source[d$station_number == st]), c("hydat", "provisional", "realtime"))
  }
  expect_false(anyDuplicated(d[c("station_number", "date")]) > 0)
  p <- attr(d, "provenance")
  expect_true(all(c("hydat", "stations", "retrieved", "knowledge_sha", "ranges") %in% names(p)))
  expect_setequal(p$stations$station_number, c("08EE013", "08EE003"))
})

test_that("the species windows are complete, unique month-days", {
  w <- utils::read.csv(vignette_data("life_history_bulk.csv"), stringsAsFactors = FALSE)
  expect_true(all(c("species_code", "life_stage", "start", "end", "source") %in% names(w)))
  expect_gt(nrow(w), 0)
  expect_true(all(grepl("^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$", c(w$start, w$end))))
  expect_false(anyDuplicated(w[c("species_code", "life_stage")]) > 0)
})

test_that("the map layers are sf in BC Albers, with both stations and their catchments", {
  skip_if_not_installed("sf")
  m <- readRDS(vignette_data("station_map.rds"))
  expect_named(m, c("stations", "catchments", "streams", "lakes", "places", "bc"))
  for (nm in names(m)) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
    expect_gt(nrow(m[[nm]]), 0)
  }
  expect_setequal(m$stations$station_number, c("08EE013", "08EE003"))
  expect_setequal(m$catchments$station_number, c("08EE013", "08EE003"))
  # each catchment is the station's own: FWA area within 10% of HYDAT's gross area
  expect_true(all(abs(m$catchments$area_ratio - 1) < 0.1))
  expect_equal(sum(m$streams$main), 2L)
})

test_that("the segment values carry plain ids, the calibration gauges and their provenance", {
  v <- readRDS(vignette_data("segment_values.rds"))
  expect_named(v, c("parity", "sampling", "segments", "skill", "gauges_salr", "provenance"))
  # fwapg's bigint ids would arrive as integer64, which a session without bit64
  # reads as raw bits: every table must hold plain types
  for (nm in setdiff(names(v), "provenance")) {
    expect_false(any(vapply(v[[nm]], inherits, NA, "integer64")), info = nm)
  }
  expect_type(v$segments$linear_feature_id, "integer")
  # the parity summary: every SALR segment fwapg has a value for, all matched
  expect_equal(v$parity$n_segments, v$provenance$fwapg_discharge_rows[["SALR"]])
  expect_equal(v$parity$n_match5, v$parity$n_segments)
  expect_equal(nrow(v$skill), 315L)   # the shipped fit's calibration gauges (HYDAT 2026-07-17, #43)
  expect_type(v$skill$linear_feature_id, "integer")
  # routed PCIC flow (fwapg#6, #58) at most gauges in its coverage, and at few outside it
  expect_type(v$skill$in_routed, "logical")
  expect_gt(sum(v$skill$in_routed & !is.na(v$skill$routed_mm)), 0.9 * sum(v$skill$in_routed))
  expect_lt(sum(!v$skill$in_routed & !is.na(v$skill$routed_mm)), 5)
  expect_true(all(v$skill$routed_mm > 0, na.rm = TRUE))
  expect_false(anyNA(v$gauges_salr[c("lon", "lat", "routed_mm")]))
  expect_setequal(unique(v$segments$watershed_group_code), c("SALR", "BULK"))
  # routed flow covers both groups: all but a few segments that have a watershed
  for (g in c("SALR", "BULK")) {
    i <- v$segments$watershed_group_code == g & !is.na(v$segments$mad_wb_m3s)
    expect_gt(mean(!is.na(v$segments$mad_routed_m3s[i])), 0.99, label = g)
  }
  expect_equal(sum(v$gauges_salr$holds_salr), 1L)
  expect_true(all(c("wet_commit", "province_run", "aet", "hydat_release", "near_km",
                    "salr_stale_segments", "upstream_area_100", "fwapg_discharge_rows", "routed_commit",
                    "routed_fingerprint", "routed_groups", "routed_cov_rows", "routed_order8") %in% names(v$provenance)))
})

test_that("the segment map layers are sf in BC Albers and join the values", {
  skip_if_not_installed("sf")
  m <- readRDS(vignette_data("segment_map.rds"))
  expect_named(m, c("segments", "groups", "lakes", "places", "context", "context_streams", "context_lakes",
                    "coverage", "zones"))
  for (nm in names(m)) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
    expect_gt(nrow(m[[nm]]), 0)
  }
  expect_setequal(m$groups$watershed_group_code, c("SALR", "BULK"))
  v <- readRDS(vignette_data("segment_values.rds"))
  expect_setequal(m$segments$linear_feature_id, v$segments$linear_feature_id)
  # the coverage outline and the scored gauges come from two queries: every
  # gauge in routed coverage lies inside the outline
  s2 <- suppressMessages(sf::sf_use_s2())
  withr::defer(suppressMessages(sf::sf_use_s2(s2)))
  suppressMessages(sf::sf_use_s2(FALSE))
  expect_equal(m$coverage$cov_share, v$provenance$routed_cov_share)
  expect_identical(m$coverage$routed_fingerprint, v$provenance$routed_fingerprint)
  pts <- sf::st_transform(sf::st_as_sf(v$skill, coords = c("lon", "lat"), crs = 4326), 3005)
  inside <- lengths(sf::st_intersects(pts, m$coverage)) > 0
  expect_identical(inside, v$skill$in_routed)
  # PCIC's routed domains leave out the Liard (10x gauges)
  expect_false(any(startsWith(v$skill$station_number[v$skill$in_routed], "10")))
  # each calibration gauge's zone is drawn, and SALR's context holds its gauges
  expect_true(all(v$skill$zone %in% m$zones$zone))
  near <- sf::st_transform(sf::st_as_sf(v$gauges_salr, coords = c("lon", "lat"), crs = 4326), 3005)
  expect_true(all(lengths(sf::st_within(near, m$context)) > 0))
  # and each sits on a river the map draws: SALR's segments or the context rivers
  rivers <- c(sf::st_geometry(m$context_streams),
              sf::st_geometry(m$segments[m$segments$watershed_group_code == "SALR", ]))
  expect_true(all(apply(sf::st_distance(near, rivers), 1, min) < 200))
  expect_setequal(m$places$watershed_group_code, c("SALR", "BULK"))
})
