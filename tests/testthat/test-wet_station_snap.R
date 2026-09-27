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
  h <- local_hydat_real()
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
