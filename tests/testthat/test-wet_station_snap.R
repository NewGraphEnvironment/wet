cand <- function(...) {
  x <- data.frame(...)
  x$wscode <- "100"
  x$localcode <- "100"
  x
}

test_that("the candidate whose area matches wins over a nearer one", {
  st <- data.frame(station_number = "A", lon = 0, lat = 0, drainage_area_gross_km2 = 144)
  cd <- cand(station_number = "A", linear_feature_id = c(1, 2), distance_m = c(36, 300),
             watershed_feature_id = c(10L, 20L), upstream_area_km2 = c(3.1, 145))
  out <- wet:::wet_snap_pick(st, cd, 0.1)
  expect_equal(out$watershed_feature_id, 20L)
  expect_true(out$accepted)
  expect_equal(out$area_ratio, 145 / 144)
})

test_that("stations without a usable candidate or area keep a row with a reason", {
  st <- data.frame(station_number = c("A", "B", "C"), lon = 0, lat = 0,
                   drainage_area_gross_km2 = c(100, NA, 100))
  cd <- cand(station_number = c("B", "B", "C"), linear_feature_id = c(1, 2, 3),
             distance_m = c(50, 10, 5), watershed_feature_id = c(1L, 2L, 3L),
             upstream_area_km2 = c(40, 60, 150))
  out <- wet:::wet_snap_pick(st, cd, 0.1)
  expect_equal(out$station_number, c("A", "B", "C"))
  expect_false(any(out$accepted))
  expect_equal(out$reason[1], "no candidate within tolerance")
  # no gross area: nearest candidate, not accepted
  expect_equal(out$watershed_feature_id[2], 2L)
  expect_equal(out$reason[2], "no gross drainage area")
  expect_match(out$reason[3], "area ratio 1.50 outside")
})

test_that("real stations snap to the right stream: mainstem, headwater, confluence", {
  conn <- local_fwapg()
  h <- local_hydat_pinned()
  con <- wet:::wet_hydat_connect(h)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  st <- DBI::dbGetQuery(con, "
    SELECT STATION_NUMBER station_number, LONGITUDE lon, LATITUDE lat,
           DRAINAGE_AREA_GROSS drainage_area_gross_km2
    FROM STATIONS WHERE STATION_NUMBER IN ('08EE004', '08OA003', '08ME023', '08JB003', '08LE077',
                                          '09AE003', '08GA079')")
  out <- wet_station_snap(conn, st)
  expect_true(all(out$accepted))
  expect_true(all(abs(out$area_ratio - 1) < 0.1))
  # 08ME023: the nearest segment drains ~3 km2; the gauge drains 144 km2
  expect_gt(out$upstream_area_km2[out$station_number == "08ME023"], 100)
  # 08JB003 sits 845 m below Fraser Lake: an outlet. 08LE077 has a lake
  # downstream of the gauge (an inlet), which is not one.
  expect_true(out$lake[out$station_number == "08JB003"])
  expect_false(out$lake[out$station_number == "08LE077"])
  # 09AE003: a lake draining 0.25 % of the basin, on a tributary. 08GA079: an
  # inlet that an FWA localcode fault places upstream; its lake drains more
  # than the gauge does.
  expect_false(out$lake[out$station_number == "09AE003"])
  expect_false(out$lake[out$station_number == "08GA079"])
  # base types only: a bigint id must not arrive as integer64, whose typeof()
  # is also "double", so the class is what tells them apart
  expect_identical(class(out$linear_feature_id), "numeric")
  expect_type(out$watershed_feature_id, "integer")
})

test_that("a tie in score and distance goes to the lower segment id, in any order", {
  st <- data.frame(station_number = "A", lon = 0, lat = 0, drainage_area_gross_km2 = 100)
  # two segments meeting at the node nearest the station, in one watershed
  cd <- cand(station_number = "A", linear_feature_id = c(7, 3), distance_m = c(25, 25),
             watershed_feature_id = c(10L, 10L), upstream_area_km2 = c(101, 101))
  expect_equal(wet:::wet_snap_pick(st, cd, 0.1)$linear_feature_id, 3)
  expect_equal(wet:::wet_snap_pick(st, cd[2:1, ], 0.1)$linear_feature_id, 3)
})

test_that("the database has fwapg#41's fwa_indexpoint() wherever WET_FWAPG_CURRENT says it should", {
  if (!fwapg_current_wanted()) skip("WET_FWAPG_CURRENT does not say the database is current")
  # no skip helper and no trial: an unreachable database errors here, and a
  # stale one fails, so neither can turn the suite green
  conn <- fwapg_connect()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  expect_true(fwapg_indexpoint_current(conn),
              info = "migration 202610240132__indexpoint_tiebreak (NewGraphEnvironment/fwapg#41) is not applied")
})

# A station's candidates as wet_station_snap() fetches them, on the same
# connection; and the snapped position on its picked segment, the blue line and
# measure scripts/vignette_map_lib.R cuts the catchment at
candidates <- function(conn, st) {
  DBI::dbGetQuery(conn, sprintf("
    SELECT c.linear_feature_id::double precision AS linear_feature_id, c.blue_line_key,
           c.downstream_route_measure AS measure
    FROM whse_basemapping.fwa_indexpoint(
      ST_Transform(ST_SetSRID(ST_MakePoint(%.10f, %.10f), 4326), 3005), 1000, 5) c", st$lon, st$lat))
}
snapped_position <- function(conn, st, linear_feature_id) {
  cd <- candidates(conn, st)
  cd[cd$linear_feature_id == linear_feature_id, c("blue_line_key", "measure")]
}
locate_n <- function(conn, pos) {
  DBI::dbGetQuery(conn, sprintf("SELECT count(*)::integer AS n FROM whse_basemapping.fwa_locatealong(%d, %.17g)",
                                pos$blue_line_key, pos$measure))$n
}
watershed_km2 <- function(conn, pos) {
  DBI::dbGetQuery(conn, sprintf("SELECT sum(area_ha)::double precision / 100 AS km2
                                 FROM whse_basemapping.fwa_watershedatmeasure(%d, %.17g)",
                                pos$blue_line_key, pos$measure))$km2
}

test_that("08KD006 snaps to the segment starting at its tied vertex, and its watershed comes back", {
  conn <- local_fwapg_indexpoint()
  # Willow River above Hay Creek (HYDAT 2026-07-17). The gauge is exactly as far
  # from the two Willow segments meeting at a vertex; the old fwa_indexpoint()
  # returned the lower one, 703862843, at a measure a hair below the upper one's
  # start, where fwa_locatealong() and fwa_watershedatmeasure() find nothing.
  st <- data.frame(station_number = "08KD006", lon = -122.373062133789, lat = 54.0455589294434,
                   drainage_area_gross_km2 = 2863)
  out <- wet_station_snap(conn, st)
  expect_equal(out$linear_feature_id, 703862887)
  expect_true(out$accepted)
  pos <- snapped_position(conn, st, out$linear_feature_id)
  expect_equal(nrow(pos), 1L)
  expect_equal(locate_n(conn, pos), 1L)
  km2 <- watershed_km2(conn, pos)
  expect_false(is.na(km2))
  expect_lt(abs(km2 - 2861.2), 2)
})

# Three more cases from scripts/station_snap_sweep.R's run on HYDAT 2026-07-17
# (data/checks/station_snap_sweep_20260717.txt, research/station_snap.md)

test_that("a measure at a stream's head is one fwa_locatealong() finds", {
  conn <- local_fwapg_indexpoint()
  # Cypress Creek near the mouth: two of its candidates lie on the top segment
  # of their streams, where the old measure ran past the segment's top by under
  # a millimetre (110 such candidates in the sweep, every one at a head)
  st <- data.frame(station_number = "07FA007", lon = -122.624717712402, lat = 56.8233299255371)
  cd <- candidates(conn, st)
  head <- cd[cd$blue_line_key %in% c(359001991L, 359001990L), ]
  expect_setequal(head$linear_feature_id, c(223047489, 223047585))
  for (i in seq_len(nrow(head))) expect_equal(locate_n(conn, head[i, ]), 1L)
})

test_that("a tie on a candidate stream goes to the segment starting at the shared vertex", {
  conn <- local_fwapg_indexpoint()
  # Finlay River at Ware: exactly as far from 207086752 and 207086967 on blue
  # line 359014591; the old function returned 207086967, where
  # fwa_locatealong() finds nothing
  st <- data.frame(station_number = "07EA001", lon = -125.626388549805, lat = 57.4208297729492)
  cd <- candidates(conn, st)
  tie <- cd[cd$blue_line_key == 359014591L, ]
  expect_equal(tie$linear_feature_id, 207086752)
  expect_equal(locate_n(conn, tie), 1L)
})

test_that("08LB050's catchment, which errored, comes back at the same snap", {
  conn <- local_fwapg_indexpoint()
  # Mann Creek near Blackpool: the snap does not move, but
  # fwa_watershedatmeasure() raised "line_interpolate_point: 2nd arg isn't
  # within [0,1]" at the old measure
  st <- data.frame(station_number = "08LB050", lon = -120.138328552246, lat = 51.5761108398438,
                   drainage_area_gross_km2 = 287)
  out <- wet_station_snap(conn, st)
  expect_equal(out$linear_feature_id, 701842242)
  km2 <- watershed_km2(conn, snapped_position(conn, st, out$linear_feature_id))
  expect_lt(abs(km2 - 287.5), 1)
})
