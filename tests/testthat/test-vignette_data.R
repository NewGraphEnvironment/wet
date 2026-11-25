# The vignettes run on data bundled by data-raw/station_vignette_*.R (#27),
# data-raw/segment_vignette_*.R (#28, #64, #71), data-raw/monthly_vignette_data.R
# (#65), data-raw/short_record_vignette_*.R (#130), data-raw/life_history_data.R (#126) and
# data-raw/temperature_vignette_*.R (#220), never on HYDAT, fwapg or the network.

vignette_data <- function(f) system.file("vignette-data", f, package = "wet")

test_that("each vignette's bundled data stays under 500 KB", {
  files <- list.files(system.file("vignette-data", package = "wet"))
  # every bundled file belongs to one vignette's budget
  budget <- list(station = c("station_daily.rds", "station_map.rds", "life_history_bulk.csv"),
                 segment = c("segment_values.rds", "segment_map.rds"),
                 monthly = c("monthly_values.rds", "monthly_map.rds"),
                 short_record = c("short_record_values.rds", "short_record_map.rds"),
                 chinook_sites = c("life_history_morr.csv", "chinook_sites_values.rds", "chinook_sites_map.rds"),
                 temperature = c("temperature_values.rds", "temperature_map.rds"))
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
  expect_named(m, c("stations", "catchments", "streams", "lakes", "places", "bc", "mouths", "towns"))
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
  expect_named(v, c("skill", "segments", "recipe", "daily", "provenance"))
  # the article's group recipe returned BULK's picks of both sources (#74)
  expect_named(v$recipe, c("pcic_routed", "wet_balance"))
  expect_true(all(v$recipe > 0))
  # fwapg's bigint ids would arrive as integer64, which a session without bit64
  # reads as raw bits: every table must hold plain types
  expect_false(any(vapply(v$skill, inherits, NA, "integer64")))
  # the routed values at the gauges are the published product's (#64): read
  # from the live manifest, checked against their source, none differing
  pub <- v$provenance$published
  expect_identical(pub$manifest, wet:::wet_catalog_url)
  expect_match(pub$wet_commit, "^[0-9a-f]{7,40}$")
  expect_true(all(c("key", "rows", "bytes", "md5") %in% names(pub$parts)))
  chk <- v$provenance$published_check
  expect_equal(nrow(chk), 1L)
  expect_gt(chk$compared, 0)
  expect_equal(chk$differing, 0)
  # every gauge segment with routed flow was compared
  expect_equal(chk$compared, length(unique(v$skill$linear_feature_id[!is.na(v$skill$routed_mm)])))
  expect_equal(nrow(v$skill), 315L)   # the shipped fit's calibration gauges (HYDAT 2026-07-17, #43)
  expect_type(v$skill$linear_feature_id, "integer")
  # routed PCIC flow (fwapg#6, #58) at most gauges, and none in the Liard (10x)
  expect_gt(mean(!is.na(v$skill$routed_mm)), 0.8)
  expect_true(all(is.na(v$skill$routed_mm[startsWith(v$skill$station_number, "10")])))
  expect_true(all(v$skill$routed_mm > 0, na.rm = TRUE))
  # what pick gives the province (#71): every segment once, and the picks
  # those a reader of the live build sees
  sg <- v$segments
  expect_named(sg, c("fwa", "no_lut", "neither", "pick_routed", "pick_balance", "far_low", "no_lut_connector"))
  expect_lte(sg[["no_lut_connector"]], sg[["no_lut"]])
  expect_equal(sg[["pick_routed"]] + sg[["pick_balance"]] + sg[["neither"]], sg[["fwa"]])
  expect_lte(sg[["no_lut"]], sg[["neither"]])
  expect_lte(sg[["far_low"]], sg[["pick_balance"]])
  rd <- pub$reader
  expect_equal(sg[["pick_routed"]], rd$picked[rd$source == "pcic_routed"])
  expect_equal(sg[["pick_balance"]], rd$picked[rd$source == "wet_balance"])
  expect_equal(v$provenance$far_low, 0.2)
  expect_true(all(c("wet_commit", "province_run", "aet", "hydat_release", "far_low", "segment_report",
                    "segment_report_commit", "published", "published_check", "routed_commit", "routed_fingerprint",
                    "routed_report") %in% names(v$provenance)))
  expect_match(v$provenance$segment_report_commit, "^[0-9a-f]{7,40}$")
  # routed's period as the published rows carry it, which the article states
  expect_identical(v$provenance$routed_period, "1981-2010")
})

test_that("the segment map holds the picked source on the rivers, from the same build", {
  skip_if_not_installed("sf")
  m <- readRDS(vignette_data("segment_map.rds"))
  expect_named(m, c("rivers", "regions", "zones", "provenance"))
  for (nm in c("rivers", "regions")) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
    expect_gt(nrow(m[[nm]]), 0)
  }
  # three classes, each drawn, and each line one class in one order band
  expect_setequal(unique(m$rivers$class), c("pcic_routed", "wet_balance", "none"))
  expect_true(all(m$rivers$order_band %in% 5:8))
  expect_true(all(sf::st_geometry_type(m$rivers) == "MULTILINESTRING"))
  expect_setequal(names(m$provenance$drawn), c("pcic_routed", "wet_balance", "none"))
  # the picks drawn come from the build the values were read from
  v <- readRDS(vignette_data("segment_values.rds"))
  expect_identical(m$provenance$published$wet_commit, v$provenance$published$wet_commit)
  expect_identical(m$provenance$published$built, v$provenance$published$built)
  expect_identical(m$provenance$published$manifest, v$provenance$published$manifest)
  # ...and published with one receipt (#161)
  expect_identical(m$provenance$published$receipt$recipe_id, v$provenance$published$receipt$recipe_id)
  expect_match(v$provenance$published$receipt$recipe_id, "^[0-9a-f]{64}$")
  # the region the article names, with its picks counted
  expect_identical(m$regions$name, "Liard")
  expect_true(all(m$regions$pcic_routed + m$regions$wet_balance + m$regions$none > 0))
  # each calibration gauge's zone has a name
  expect_true(all(v$skill$zone %in% m$zones$zone))
  expect_false(anyNA(m$zones$name))
})

test_that("the monthly values hold both sources' months and days, checked against their sources", {
  v <- readRDS(vignette_data("monthly_values.rds"))
  expect_named(v, c("segments", "segments_daily", "gauges", "provenance"))
  for (nm in setdiff(names(v), "provenance")) {
    expect_false(any(vapply(v[[nm]], inherits, NA, "integer64")), info = nm)
  }
  # three Bulkley gauges' segments, 13 months of each source
  sg <- v$segments
  expect_setequal(sg$station_number, c("08EE013", "08EE003", "08EE004"))
  expect_equal(nrow(sg), 3 * 2 * 13)
  expect_false(anyDuplicated(sg[c("linear_feature_id", "source", "month")]) > 0)
  expect_false(anyNA(sg$q_m3s))
  expect_setequal(sg$period[sg$source == "pcic_routed"], "1981-2010")
  expect_setequal(sg$period[sg$source == "wet_balance"], "1981-2010")
  # one source picked per segment and month
  expect_true(all(tapply(sg$pick, paste(sg$linear_feature_id, sg$month), sum) == 1))
  # the same segments' 365 days of each source (#107), from the published
  # segment_daily; the balance's days average to its published months
  sd <- v$segments_daily
  expect_named(sd, c("station_number", "linear_feature_id", "source", "doy", "q_m3s"))
  expect_equal(nrow(sd), 3 * 2 * 365)
  expect_setequal(sd$linear_feature_id, sg$linear_feature_id)
  expect_setequal(sd$source, c("pcic_routed", "wet_balance"))
  expect_setequal(sd$doy, 1:365)
  expect_false(anyDuplicated(sd[c("linear_feature_id", "source", "doy")]) > 0)
  expect_false(anyNA(sd$q_m3s))
  bd <- sd[sd$source == "wet_balance", ]
  bm <- sg[sg$source == "wet_balance" & sg$month > 0, ]
  bd$month <- wet:::wet_doy_month()[bd$doy]
  from_days <- stats::aggregate(q_m3s ~ linear_feature_id + month, bd, mean)
  key <- function(d) paste(d$linear_feature_id, d$month)
  expect_equal(from_days$q_m3s, bm$q_m3s[match(key(from_days), key(bm))], tolerance = 1e-9)
  # every published value checked against its source, none differing, none
  # empty; the days by routing them again and by making them again from the
  # published months and the fit's shape
  chk <- v$provenance$published_check
  expect_true(all(chk$compared > 0))
  expect_true(all(chk$differing == 0))
  expect_equal(sum(grepl("^routed days", chk$check)), 1L)
  expect_equal(sum(grepl("^balance (days|months from the days)", chk$check)), 2L)
  expect_match(v$provenance$shape_code_md5, "^[0-9a-f]{32}$")
  expect_true("shape_daily.rds" %in% names(v$provenance$md5))
  expect_identical(v$provenance$published$manifest, wet:::wet_catalog_url)
  # the calibration gauges: 13 months each, observed and held-out balance at
  # all of them, routed where its segment has flow, its months all or none
  g <- v$gauges
  n <- length(unique(g$station_number))
  expect_equal(n, 315L)
  expect_equal(nrow(g), 13 * n)
  expect_false(anyNA(g$obs_mm))
  expect_false(anyNA(g$wb_mm))
  routed_n <- tapply(!is.na(g$routed_mm), g$station_number, sum)
  expect_true(all(routed_n %in% c(0, 13)))
  # observed months sum to the annual (shares of one record), and so do the
  # balance's (annual times shares that sum to 1)
  sum_months <- function(x) tapply(ifelse(g$month > 0, x, 0), g$station_number, sum)
  ann <- function(x) tapply(ifelse(g$month == 0, x, 0), g$station_number, sum)
  expect_equal(sum_months(g$obs_mm), ann(g$obs_mm), tolerance = 1e-9)
  expect_equal(sum_months(g$wb_mm), ann(g$wb_mm), tolerance = 1e-9)
})

test_that("the monthly map holds the three Bulkley gauges and their nested catchments", {
  skip_if_not_installed("sf")
  m <- readRDS(vignette_data("monthly_map.rds"))
  expect_named(m, c("stations", "catchments", "streams", "lakes", "places", "bc"))
  for (nm in names(m)) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
    expect_gt(nrow(m[[nm]]), 0)
  }
  st <- c("08EE013", "08EE003", "08EE004")
  expect_setequal(m$stations$station_number, st)
  expect_setequal(m$catchments$station_number, st)
  # each catchment is the station's own: FWA area within 10% of HYDAT's gross area
  expect_true(all(abs(m$catchments$area_ratio - 1) < 0.1))
  # and they nest, Buck Creek inside Houston inside Quick, as the article says
  a <- stats::setNames(m$catchments$area_km2, m$catchments$station_number)
  expect_lt(a[["08EE013"]], a[["08EE003"]])
  expect_lt(a[["08EE003"]], a[["08EE004"]])
  expect_equal(sum(m$streams$main), 2L)
  expect_setequal(m$places$name, c("Houston", "Telkwa"))
  # the same gauges as the values, from the same HYDAT release
  v <- readRDS(vignette_data("monthly_values.rds"))
  expect_setequal(m$stations$station_number, unique(v$segments$station_number))
  expect_identical(attr(m, "provenance")$hydat, substr(v$provenance$hydat_release, 1, 10))
})

test_that("the short-record values carry Maxan's series, its scores and their provenance", {
  v <- readRDS(vignette_data("short_record_values.rds"))
  expect_named(v, c("extended", "carried", "change", "scores", "snow", "departures", "snow_change", "fits",
                    "gauges", "site", "provenance"))
  # Maxan's row of scripts/departure_sites.csv (#146)
  expect_identical(v$site$site_id, "maxan")
  expect_identical(v$site$target_station, "08EE018")
  expect_identical(v$site$snow_gauges, c("08EE003", "08EE013"))
  # Maxan's five measured summers, each window filled to 1931-2024
  for (w in c("migration", "spawning")) {
    e <- v$extended[v$extended$window == w, ]
    expect_equal(range(e$year), c(1931L, 2024L))
    expect_false(anyDuplicated(e$year) > 0)
    expect_equal(e$year[e$source == "observed"], 1975:1979)
    expect_true(all(is.na(e$donor[e$source == "observed"])), info = w)
    expect_false(anyNA(e$donor[e$source == "extended"]), info = w)
    expect_true(all(e$lower <= e$value & e$value <= e$upper), info = w)
  }
  expect_setequal(paste(v$scores$statistic, v$scores$window), paste(v$change$statistic, v$change$window))
  expect_setequal(unique(v$snow$gauge), c("08EE003", "08EE013", "08EE018"))
  expect_true("08EE018" %in% v$gauges$station_number)
  expect_true(all(c("wet_commit", "hydat", "cd_sha", "code_md5", "report_md5") %in% names(v$provenance)))
})

test_that("the short-record map layers are sf in BC Albers, with the three catchments", {
  skip_if_not_installed("sf")
  m <- readRDS(vignette_data("short_record_map.rds"))
  v <- readRDS(vignette_data("short_record_values.rds"))
  expect_named(m, c("stations", "catchments", "streams", "lakes", "places", "bc"))
  for (nm in names(m)) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
    expect_gt(nrow(m[[nm]]), 0)
  }
  # the map draws every gauge the values name
  expect_setequal(m$stations$station_number, v$gauges$station_number)
  expect_setequal(m$catchments$station_number, c("08EE003", "08EE013", "08EE018"))
  expect_true(all(abs(m$catchments$area_ratio - 1) < 0.1))
  expect_setequal(m$streams$gnis_name[m$streams$main], c("Bulkley River", "Buck Creek", "Maxan Creek", "Foxy Creek"))
})


test_that("the Chinook sites' values hold four sites, both routes and their provenance", {
  v <- readRDS(vignette_data("chinook_sites_values.rds"))
  expect_named(v, c("sites", "change", "scores", "snow", "snow_change", "normal", "gauges", "windows", "use", "use_obs",
                    "score_settings", "daily", "years", "periods", "carry", "provenance"))
  # #147: one weighting per site and window set, both weightings scored on the same gauges in each setting,
  # and the shipped one is what the scores carry
  w <- unique(v$carry[c("site_id", "group", "ship")])
  expect_false(anyDuplicated(w[c("site_id", "group")]) > 0)
  expect_true(all(w$ship %in% c("distance", "covariance_pick")))
  expect_setequal(paste(w$site_id, w$group), paste(v$scores$site_id, v$scores$group))
  expect_equal(v$scores$weighting, w$ship[match(paste(v$scores$site_id, v$scores$group), paste(w$site_id, w$group))])
  expect_true(all(v$carry$covered <= v$carry$pool))
  # the comparison periods (#152), and every change and snow mean over exactly them
  expect_equal(v$periods, list(ref = 1951:1980, recent = 2016:2025))
  expect_true(all(v$change$n_pre <= 30 & v$change$n_post <= 10))
  expect_true(all(v$snow_change$n_ref == 30 & v$snow_change$n_recent == 10))
  # a measured coverage for every change with an interval
  expect_true(all(is.na(v$change$lo) | !is.na(v$change$cover)))
  # a typical year of 365 days at every site, one picked source a day
  expect_setequal(unique(v$daily$site_id), v$sites$site_id)
  expect_true(all(table(v$daily$site_id[v$daily$pick]) == 365))
  # year-by-year departures: borrowed at every site, measured and filled only where a gauge exists
  for (id in v$sites$site_id) {
    r <- unique(v$years$route[v$years$site_id == id])
    expect_true("borrowed" %in% r, info = id)
    expect_equal(all(c("measured", "filled") %in% r), v$sites$kind[v$sites$site_id == id] == "extend", info = id)
  }
  expect_equal(v$sites$site_id, c("maxan", "swift", "naver", "gosnell"))
  expect_equal(v$sites$kind, c("extend", "extend", "extend", "ungauged"))
  # every site has the carried route in each window; only a gauged one has the extended route
  for (id in v$sites$site_id) {
    r <- v$change[v$change$site_id == id & v$change$group == "BULK", ]
    expect_setequal(paste(r$statistic, r$window)[r$route == "carried"],
                    paste(rep(c("mean", "min7", "cov_day"), each = 2), c("migration", "spawning")))
    expect_equal(any(r$route == "extended"), v$sites$kind[v$sites$site_id == id] == "extend", info = id)
  }
  expect_true(all(v$change$lo <= v$change$change & v$change$change <= v$change$hi, na.rm = TRUE))
  # Gosnell runs under the Morice's windows too, and only it has a normal
  expect_setequal(v$scores$group[v$scores$site_id == "gosnell"], c("BULK", "MORR"))
  expect_equal(unique(v$normal$site_id), "gosnell")
  expect_true(all(c("wet_commit", "hydat", "scripts", "reports") %in% names(v$provenance)))
})

test_that("the Chinook sites' map layers are sf in BC Albers, two regional maps holding every site", {
  skip_if_not_installed("sf")
  m <- readRDS(vignette_data("chinook_sites_map.rds"))
  v <- readRDS(vignette_data("chinook_sites_values.rds"))
  expect_named(m, c("bc", "targets", "gauges", "extents", "streams", "lakes", "places"))
  for (nm in names(m)) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
  }
  expect_equal(sort(m$targets$site_id), sort(v$sites$site_id))
  expect_setequal(m$extents$map, unique(m$targets$map))
  # every target and every gauge it borrows from inside its map's extent
  for (k in seq_len(nrow(m$targets))) {
    ext <- m$extents[m$extents$map == m$targets$map[k], ]
    expect_equal(lengths(sf::st_within(m$targets[k, ], ext)), 1L, info = m$targets$site_id[k])
  }
  for (mp in unique(m$extents$map)) {
    g <- m$gauges[m$gauges$map == mp, ]
    expect_true(all(lengths(sf::st_within(g, m$extents[m$extents$map == mp, ])) == 1), info = mp)
    expect_true(any(m$streams$map == mp & m$streams$main), info = mp)
    expect_true(any(m$places$map == mp), info = mp)
  }
  # each target names the river it flows into, its river system and its mouth
  expect_false(anyNA(m$targets$into1))
  expect_false(anyNA(m$targets$system))
  expect_false(anyNA(m$targets$mouth_x))
  # the gauges drawn are exactly the values' donors, by site (a rebuilt values bundle needs the map rebuilt)
  don <- v$gauges[v$gauges$role %in% c("extension donor", "carried donor"), ]
  expect_setequal(paste(m$gauges$site_id, m$gauges$station_number, m$gauges$role),
                  paste(don$site_id, don$station_number, don$role))
})

test_that("the temperature values hold plain types, the basin's stations and the fill's error", {
  v <- readRDS(vignette_data("temperature_values.rds"))
  expect_named(v, c("basin", "stations", "pool", "candidates", "pick", "year", "season", "gsdd", "edge", "fit",
                    "validation", "provenance"))
  for (x in list(v$stations, v$candidates, v$year, v$season)) {
    expect_false(any(vapply(x, inherits, NA, "integer64")))
  }
  expect_s3_class(v$year$date, "Date")
  expect_false(anyDuplicated(v$stations$station_number) > 0)
  # every station sits under the basin's main stem, on a whole-numbered segment
  main <- v$basin$wscode
  expect_match(main, "^[0-9]{3}(\\.[0-9]{6})*$")
  expect_true(all(v$stations$wscode == main | startsWith(v$stations$wscode, paste0(main, "."))))
  expect_equal(v$stations$linear_feature_id, round(v$stations$linear_feature_id))
  expect_true(v$pick$station_number %in% v$stations$station_number)
  expect_true(all(c("commit", "retrieved", "hydat", "cd", "gsdd") %in% names(v$provenance)))
  expect_gt(v$validation$season_open$gsdd_mae, 0)
  expect_gt(v$validation$truth_station_years, v$validation$truth_stations)
})

test_that("the temperature pick follows the rule on the bundle's own candidate table", {
  v <- readRDS(vignette_data("temperature_values.rds"))
  cand <- v$candidates
  # the rule in the header of data-raw/temperature_vignette_data.R: one interior gap of 7 to 45
  # days (60 only when none qualifies at 45), a fitted station, a degree-day value only once
  # filled, and the gap inside a growing season
  rule <- function(max_days) {
    !is.na(cand$gap_days) & cand$gap_days >= 7 & cand$gap_days <= max_days & cand$fitted &
      is.na(cand$gsdd_unfilled) & !is.na(cand$gsdd_filled) & cand$in_season %in% TRUE
  }
  expect_true(v$pick$gap_max %in% c(45, 60))
  if (v$pick$gap_max == 60) expect_false(any(rule(45)))
  expect_identical(cand$qualifies, rule(v$pick$gap_max))
  # the gap is recomputed from each year's runs of missing days: one run longer than 2 days,
  # touching neither end of 1 March to 30 November
  one_gap <- vapply(seq_len(nrow(cand)), function(i) {
    days <- as.integer(strsplit(cand$run_days[i], ",")[[1]])
    edge <- as.integer(strsplit(cand$run_edge[i], ",")[[1]]) == 1
    long <- which(days > 2)
    if (length(long) == 1 && !edge[long]) days[long] else NA_integer_
  }, 0L)
  expect_identical(one_gap, cand$gap_days)
  expect_identical(as.integer(cand$gap_end - cand$gap_start) + 1L, cand$gap_days)
  # closest to 30 days, then the later year, then the lower station number
  o <- order(abs(cand$gap_days - 30), -cand$year, cand$station_number, method = "radix")
  o <- o[cand$qualifies[o]]
  expect_gt(length(o), 0)
  expect_identical(which(cand$picked), o[1])
  expect_identical(cand$station_number[o[1]], v$pick$station_number)
  expect_identical(cand$year[o[1]], v$pick$year)
  expect_identical(cand$gap_days[o[1]], v$pick$gap_days)
})

test_that("the picked year is filled where the station has no day, and its degree days add up", {
  v <- readRDS(vignette_data("temperature_values.rds"))
  y <- v$year
  yr <- v$pick$year
  expect_identical(unique(as.integer(format(y$date, "%Y"))), yr)
  in_win <- y$date >= as.Date(paste0(yr, "-03-01")) & y$date <= as.Date(paste0(yr, "-11-30"))
  in_gap <- y$date >= v$pick$gap_start & y$date <= v$pick$gap_end
  expect_equal(sum(in_gap), v$pick$gap_days)
  expect_false(anyNA(y$t_mean_c[in_win]))
  expect_true(all(y$filled[in_gap]))
  # the days filled in the window are the days the candidate table counts as not observed
  row <- v$candidates[v$candidates$picked, ]
  expect_equal(sum(y$filled[in_win]), sum(in_win) - row$observed)
  # an observed day is its own interval; a filled day lies inside one
  obs <- in_win & !y$filled
  expect_equal(y$t_lo_c[obs], y$t_mean_c[obs])
  expect_equal(y$t_hi_c[obs], y$t_mean_c[obs])
  expect_true(all(y$t_lo_c[in_gap] <= y$t_mean_c[in_gap] & y$t_mean_c[in_gap] <= y$t_hi_c[in_gap]))
  # the season's degree days are the daily means summed over it, filled; none without the fill
  acc <- vapply(seq_len(nrow(v$season)), function(i) {
    sum(y$t_mean_c[y$date >= v$season$start[i] & y$date <= v$season$end[i]])
  }, 0)
  expect_equal(acc, v$season$gsdd, tolerance = 1e-10)
  expect_equal(sum(v$season$gsdd), v$gsdd$filled, tolerance = 1e-10)
  expect_true(is.na(v$gsdd$unfilled))
  expect_true(any(v$season$start <= v$pick$gap_start & v$season$end >= v$pick$gap_end))
})

test_that("the fill with the day before the gap hidden is a comparison beside the pick", {
  v <- readRDS(vignette_data("temperature_values.rds"))
  y <- v$year
  in_gap <- y$date >= v$pick$gap_start & y$date <= v$pick$gap_end
  expect_equal(v$edge$date, v$pick$gap_start - 1)
  expect_false(y$filled[y$date == v$edge$date])
  expect_equal(sum(y$t_mean_c[in_gap]), v$edge$gap_filled)
  expect_equal(sum(y$t_edge_c[in_gap]), v$edge$gap_edge)
  expect_equal(sum(y$s_open_c[in_gap]), v$edge$gap_open)
  expect_false(is.na(v$edge$gsdd))
})

test_that("the temperature map draws the values bundle's stations on the whole of the basin's tree", {
  skip_if_not_installed("sf")
  v <- readRDS(vignette_data("temperature_values.rds"))
  m <- readRDS(vignette_data("temperature_map.rds"))
  expect_named(m, c("basin", "tree", "streams", "lakes", "places", "stations", "extent", "bc"))
  for (nm in names(m)) {
    expect_s3_class(m[[nm]], "sf")
    expect_equal(sf::st_crs(m[[nm]])$epsg, 3005L, info = nm)
    expect_gt(nrow(m[[nm]]), 0)
  }
  # one set of stations and segments in both bundles, and one pick
  expect_identical(m$stations$station_number, v$stations$station_number)
  expect_identical(m$stations$linear_feature_id, v$stations$linear_feature_id)
  expect_identical(m$stations$station_number[m$stations$picked], v$pick$station_number)
  expect_identical(m$stations$fitted, v$stations$fitted)
  # the network's numbers are the per-order table's, and every order in it is drawn
  net <- attr(m, "network")
  expect_identical(net$wscode, v$basin$wscode)
  expect_equal(net$reaches, sum(net$orders$segments))
  expect_equal(net$km, sum(net$orders$km))
  expect_identical(m$tree$stream_order, net$orders$stream_order[net$orders$drawn])
  expect_equal(net$with_station, length(unique(v$stations$linear_feature_id)))
  expect_lt(net$with_station, net$reaches)
  # the towns the basin's row names, each once
  expect_setequal(m$places$name, strsplit(v$basin$towns, ";")[[1]])
  expect_false(anyDuplicated(m$places$name) > 0)
  # which tree was drawn
  tree <- attr(m, "provenance")$tree
  expect_match(tree$basin_ids_md5, "^[0-9a-f]{32}$")
  expect_gt(tree$rows, net$reaches)
})
