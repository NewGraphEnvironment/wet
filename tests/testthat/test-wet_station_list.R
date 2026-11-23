test_that("the provincial list is one row per station with the documented columns", {
  s <- wet_station_list()
  expect_named(s, c("station_number", "name", "lon", "lat", "source", "network", "first", "last", "regulation",
                    "hydat_site", "hydat_km", "licence", "credit"))
  expect_equal(nrow(s), 211)
  expect_false(anyDuplicated(s$station_number) > 0)
  expect_false(is.unsorted(s$station_number))
  expect_s3_class(s$first, "Date")
  expect_true(all(s$first <= s$last, na.rm = TRUE))
  expect_true(all(s$source == "bcenv") && all(s$licence == "OGL-BC 2.0"))
  expect_match(s$credit[1], "Open Government Licence – British Columbia", fixed = TRUE)
  expect_true(all(s$regulation %in% c("unknown", "regulated by name")))
  # BC's longitudes and latitudes
  expect_true(all(s$lon > -140 & s$lon < -114 & s$lat > 48 & s$lat < 60.1))
})

test_that("stations at a HYDAT site name it, within 1 km", {
  s <- wet_station_list()
  at <- s[!is.na(s$hydat_site), ]
  # the survey's 57 same-site stations and 1 duplicate (#123)
  expect_equal(nrow(at), 58)
  expect_true(all(grepl("^[0-9]{2}[A-Z]{2}[0-9]{3}$", at$hydat_site)))
  expect_true(all(at$hydat_km <= 1))
  expect_true(all(is.na(s$hydat_km[is.na(s$hydat_site)])))
  expect_equal(s$hydat_site[s$station_number == "08NM0015"], "08NM116")
})

test_that("bad arguments are refused", {
  expect_error(wet_station_list("bcwatertool"), "only network")
  expect_error(wet_station_list(snapshot = "19000101"), "no tracked manifest")
})
