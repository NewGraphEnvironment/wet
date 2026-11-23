test_that("the list is one row per station with the documented columns, provincial then Tool", {
  s <- wet_station_list()
  expect_named(s, c("station_number", "name", "lon", "lat", "source", "network", "first", "last", "regulation",
                    "hydat_site", "hydat_km", "licence", "credit"))
  expect_equal(as.vector(table(s$source)[c("bcenv", "bcwatertool")]), c(211, 46))
  expect_false(anyDuplicated(s$station_number) > 0)
  key <- paste(s$source, s$station_number)
  expect_identical(key, sort(key, method = "radix"))
  expect_s3_class(s$first, "Date")
  expect_true(all(s$first <= s$last, na.rm = TRUE))
  expect_true(all(s$regulation %in% c("unknown", "regulated by name")))
  # BC's longitudes and latitudes
  expect_true(all(s$lon > -140 & s$lon < -114 & s$lat > 48 & s$lat < 60.1))
})

test_that("the provincial list alone is the province's 211 stations under its licence", {
  s <- wet_station_list("bcenv")
  expect_equal(nrow(s), 211)
  expect_true(all(s$source == "bcenv") && all(s$licence == "OGL-BC 2.0"))
  expect_identical(s$station_number, sort(s$station_number, method = "radix"))
  expect_match(s$credit[1], "Open Government Licence \u2013 British Columbia", fixed = TRUE)
})

test_that("the Tool's gauges carry their network and their own credit, and state no licence", {
  s <- wet_station_list("bcwatertool")
  expect_equal(nrow(s), 46)
  expect_true(all(s$source == "bcwatertool") && all(is.na(s$licence)))
  expect_false(any(grepl("Any reliance|BC ENV", c(s$credit, s$network))))
  expect_true(all(grepl("^Data from ", s$credit)))
  # the listings at provincial sites continue those stations, and are not stations of their own
  expect_false(any(c("2601", "4601", "4602", "4603") %in% s$station_number))
  expect_true(all(c("HRB3142", "UC 5") %in% s$station_number))
})

test_that("a provincial station a Tool gauge continues says so when both sources are listed", {
  both <- wet_station_list()
  prov <- wet_station_list("bcenv")
  r <- both[both$station_number == "08HB0008", ]
  p <- prov[prov$station_number == "08HB0008", ]
  expect_lt(r$first, p$first)
  expect_equal(format(r$first, "%Y"), "2012")
  expect_equal(r$licence, paste0("OGL-BC 2.0; days before ", p$first, ": none stated"))
  expect_match(r$credit, paste0("; days before ", p$first, ": Data from BC Conservation Foundation"), fixed = TRUE)
  # every other provincial row is as the provincial list gives it
  moved <- both$station_number[both$source == "bcenv"][
    both$first[both$source == "bcenv"] != prov$first | both$credit[both$source == "bcenv"] != prov$credit]
  expect_setequal(stats::na.omit(moved), c("08HB0008", "08HB0011", "08HB0012", "08HC0001", "08HC0002", "08HC0003",
                                           "08HC0004"))
})

test_that("stations at a HYDAT site name it, within 1 km", {
  s <- wet_station_list("bcenv")
  at <- s[!is.na(s$hydat_site), ]
  # the survey's 57 same-site stations and 1 duplicate (#123)
  expect_equal(nrow(at), 58)
  expect_true(all(grepl("^[0-9]{2}[A-Z]{2}[0-9]{3}$", at$hydat_site)))
  expect_true(all(at$hydat_km <= 1))
  expect_true(all(is.na(s$hydat_km[is.na(s$hydat_site)])))
  expect_equal(s$hydat_site[s$station_number == "08NM0015"], "08NM116")
  t <- wet_station_list("bcwatertool")
  expect_true(all(t$hydat_km[!is.na(t$hydat_site)] <= 1))
})

test_that("bad arguments are refused", {
  expect_error(wet_station_list("usgs"), "some of")
  expect_error(wet_station_list(character()), "some of")
  expect_error(wet_station_list(snapshot = "19000101"), "no tracked manifest")
})
