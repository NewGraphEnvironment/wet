# Regulation per non-HYDAT station (#196, scripts/station_regulation_rule.R). scripts/ is not in
# the installed package, so these run from the source tree only.
local_rule <- function() {
  scripts <- testthat::test_path("..", "..", "scripts")
  testthat::skip_if_not(dir.exists(scripts), "scripts/ is not in the installed package")
  e <- new.env()
  sys.source(file.path(scripts, "station_sources_lib.R"), envir = e)
  sys.source(file.path(scripts, "station_regulation_rule.R"), envir = e)
  e
}
cand_of <- function(gnis, dist, area, lfid = seq_along(gnis), ws = seq_along(gnis)) {
  data.frame(linear_feature_id = lfid, gnis_name = gnis, distance_m = dist, upstream_area_km2 = area,
             watershed_feature_id = ws)
}
# one snapped station with flow, all tests clear, unless overridden
status_of <- function(r, ..., name_regulated = FALSE, snapped = TRUE) {
  a <- utils::modifyList(list(dams_up = 0L, L_share = 0, S_share = 0, outside_bc = FALSE, power_up = FALSE,
                              novol_up = FALSE),
                         list(...))
  r$rg_status(name_regulated, snapped, a$dams_up, a$L_share, a$S_share, a$outside_bc, a$power_up, a$novol_up)
}

test_that("L and S regulate at exactly the share, not below", {
  r <- local_rule()
  expect_equal(r$rg_share, 0.10)
  expect_equal(status_of(r, L_share = 0.10)$regulation, "regulated")
  expect_equal(status_of(r, L_share = 0.0999)$regulation, "natural")
  expect_equal(status_of(r, S_share = 0.10)$regulation, "regulated")
  expect_equal(status_of(r, S_share = 0.0999)$regulation, "natural")
  expect_match(status_of(r, L_share = 0.123)$why, "licensed use 12.3 %", fixed = TRUE)
  expect_equal(status_of(r, L_share = 0.05, S_share = 0.02)$why,
               "no regulating dam; licensed use 5.0 %, storage 2.0 %")
})

test_that("a regulating dam upstream regulates", {
  r <- local_rule()
  x <- status_of(r, dams_up = 1L)
  expect_equal(x$regulation, "regulated")
  expect_equal(x$why, "1 regulating dam upstream")
  expect_equal(status_of(r, dams_up = 3L)$why, "3 regulating dams upstream")
})

test_that("each unknown branch gives unknown, and a dam, L or S still regulates there", {
  r <- local_rule()
  expect_equal(status_of(r, snapped = FALSE, dams_up = NA, L_share = NA, S_share = NA, outside_bc = NA,
                         power_up = NA, novol_up = NA)$regulation, "unknown")
  expect_equal(status_of(r, outside_bc = TRUE)$regulation, "unknown")
  expect_equal(status_of(r, power_up = TRUE)$regulation, "unknown")
  # Amendment 2: a licence with no volume upstream
  x <- status_of(r, novol_up = TRUE, L_share = 0.05)
  expect_equal(x$regulation, "unknown")
  expect_equal(x$why, "licence with no volume upstream")
  expect_equal(status_of(r, novol_up = TRUE, S_share = 0.1)$regulation, "regulated")
  expect_equal(status_of(r, novol_up = TRUE, dams_up = 1L)$regulation, "regulated")
  x <- status_of(r, L_share = NA, S_share = NA)
  expect_equal(x$regulation, "unknown")
  expect_equal(x$why, "no published flow")
  expect_equal(status_of(r, outside_bc = TRUE, dams_up = 1L)$regulation, "regulated")
  expect_equal(status_of(r, power_up = TRUE, L_share = 0.2)$regulation, "regulated")
  expect_equal(status_of(r, L_share = NA, S_share = NA, dams_up = 2L)$regulation, "regulated")
  x <- status_of(r, outside_bc = TRUE, power_up = TRUE)
  expect_equal(x$why, "upstream area outside BC; power licence upstream")
})

test_that("a station regulated by name is never natural or unknown", {
  r <- local_rule()
  expect_equal(status_of(r, name_regulated = TRUE)$regulation, "regulated")
  x <- status_of(r, name_regulated = TRUE, snapped = FALSE, dams_up = NA, L_share = NA, S_share = NA,
                 outside_bc = NA, power_up = NA, novol_up = NA)
  expect_equal(x$regulation, "regulated")
  expect_equal(x$why, "name; no accepted snap")
  expect_equal(status_of(r, name_regulated = TRUE, outside_bc = TRUE)$regulation, "regulated")
  expect_equal(status_of(r, name_regulated = TRUE, L_share = NA, S_share = NA)$regulation, "regulated")
})

test_that("the status refuses incomplete inputs for a snapped station", {
  r <- local_rule()
  expect_error(status_of(r, dams_up = NA), "dams, border, power and no-volume")
  expect_error(status_of(r, outside_bc = NA), "dams, border, power and no-volume")
  expect_error(status_of(r, novol_up = NA), "dams, border, power and no-volume")
  expect_error(status_of(r, L_share = NA), "both NA")
  expect_error(status_of(r, L_share = -0.1), "non-negative")
  expect_error(r$rg_status(NA, TRUE, 0L, 0, 0, FALSE, FALSE, FALSE), "TRUE or FALSE")
  expect_error(r$rg_status(c(FALSE, FALSE), TRUE, 0L, 0, 0, FALSE, FALSE, FALSE), "one value per station")
  # every status is in the vocabulary
  x <- r$rg_status(c(FALSE, TRUE, FALSE), c(TRUE, FALSE, FALSE), c(0L, NA, NA), c(0, NA, NA), c(0, NA, NA),
                   c(FALSE, NA, NA), c(FALSE, NA, NA), c(FALSE, NA, NA))
  expect_true(all(x$regulation %in% r$rg_vocab))
  expect_equal(x$regulation, c("natural", "regulated", "unknown"))
})

test_that("a dam regulates only when active and in a regulated class; other codes stop", {
  r <- local_rule()
  op <- c("Active", "Active", "Active", "Removed", "Breached (Failed)")
  rc <- c("Regulated", "Regulated - Part 3 Exempt", "Non-Regulated - Including Minor Dam", "Regulated", "Regulated")
  expect_equal(r$rg_dam_regulating(op, rc, rep("Main", 5)), c(TRUE, TRUE, FALSE, FALSE, FALSE))
  # any function counts
  expect_equal(r$rg_dam_regulating(rep("Active", 5), rep("Regulated", 5), r$rg_dam_function_codes), rep(TRUE, 5))
  # an en dash is not the register's hyphen
  expect_error(r$rg_dam_regulating("Active", "Regulated – Part 3 Exempt", "Main"), "outside the rule's known set")
  expect_error(r$rg_dam_regulating("Operating", "Regulated", "Main"), "DAM_OPERATION_CODE")
  expect_error(r$rg_dam_regulating("Active", NA, "Main"), "DAM_REGULATED_CODE holds NA")
  expect_error(r$rg_dam_regulating("Active", "Regulated", "Weir"), "DAM_FUNCTION")
  expect_error(r$rg_codes_check(c("Current", "Pending"), r$rg_licence_status_codes, "LICENCE_STATUS"),
               '"Pending"')
})

test_that("licence classes follow #53's purpose codes, power counted as instream", {
  r <- local_rule()
  expect_equal(r$rg_licence_class(c("08A", "07A", "01A", NA, "11B")),
               c("storage", "instream", "consumptive", "none", "instream"))
  expect_true(all(r$rg_power_codes %in% r$rg_instream_codes))
})

test_that("an own-reach point is dropped only more than 100 m below the station (Amendment 3)", {
  r <- local_rule()
  expect_equal(r$rg_own_margin_m, 100)
  # a tie, just inside and just beyond the margin, on the station's line
  expect_equal(r$rg_own_below(TRUE, FALSE, TRUE, c(0, 100, 100.001, 500)), c(FALSE, FALSE, TRUE, TRUE))
  # upstream by #53's test stays upstream; a point not indexed is never dropped
  expect_false(r$rg_own_below(TRUE, TRUE, TRUE, 500))
  expect_false(r$rg_own_below(FALSE, NA, NA, NA))
  # on another blue line, #53's test decides
  expect_true(r$rg_own_below(TRUE, FALSE, FALSE, 10))
  expect_true(r$rg_own_below(TRUE, FALSE, NA, NA))
})

test_that("a shared quantity is split over kept, located PODs that are not rediversions (Amendment 1)", {
  r <- local_rule()
  # one licence's two PODs: the first diverts, the second rediverts
  expect_equal(r$rg_split_pods(located = c(TRUE, TRUE), kept = c(TRUE, TRUE), shared = c(TRUE, TRUE),
                               redivert = c(FALSE, TRUE)), c(TRUE, FALSE))
  expect_equal(r$rg_split_pods(c(FALSE, TRUE, TRUE), c(TRUE, FALSE, TRUE), c(TRUE, TRUE, FALSE),
                               c(FALSE, FALSE, FALSE)), c(FALSE, FALSE, FALSE))
})

test_that("the name leg takes the nearest candidate on the named stream", {
  r <- local_rule()
  # the nearer candidate is another stream; the named one wins
  cand <- cand_of(c("Sulphurets Creek", "Unuk River"), c(50, 400), c(100, 1500))
  x <- r$rg_snap_pick(cand, "Unuk River upstream of Sulphurets Creek", NA)
  expect_true(x$accepted)
  expect_equal(x$leg, "name")
  expect_equal(x$linear_feature_id, 2)
  # abbreviations fold: "Ck" is "Creek"
  x <- r$rg_snap_pick(cand_of(c("Maxan Creek", NA), c(300, 10), c(240, 1)), "Maxan Ck hydrometric", NA)
  expect_equal(x$linear_feature_id, 1)
  # a distance tie goes to the smaller linear_feature_id, whatever the row order
  cand <- cand_of(c("Mill Creek", "Mill Creek"), c(100, 100), c(10, 20), lfid = c(9, 7))
  expect_equal(r$rg_snap_pick(cand, "Mill Creek at road", NA)$linear_feature_id, 7)
  expect_equal(r$rg_snap_pick(cand[2:1, ], "Mill Creek at road", NA)$linear_feature_id, 7)
})

test_that("a known area must agree with the named stream within 10 %", {
  r <- local_rule()
  cand <- cand_of(c("Petitot River", "Petitot River"), c(100, 600), c(18000, 20400))
  # the nearer reach fails the area test, the farther one passes
  x <- r$rg_snap_pick(cand, "Petitot River (Quicksilver Resources Ltd.)", 20410.5)
  expect_true(x$accepted)
  expect_equal(x$leg, "name and area")
  expect_equal(x$linear_feature_id, 2)
  # within 10 % passes on either side, beyond it the named stream is not snapped (no fall back to
  # area); the comparison is wet_station_snap()'s abs(ratio - 1) <= 0.1, so 1.1 itself is just over
  for (a in c(90, 109.999)) {
    x <- r$rg_snap_pick(cand_of(c("Petitot River", "Other Creek"), c(100, 50), c(a, 100)), "Petitot River", 100)
    expect_true(x$accepted)
  }
  x <- r$rg_snap_pick(cand_of(c("Petitot River", "Other Creek"), c(100, 50), c(89.9, 100)), "Petitot River", 100)
  expect_false(x$accepted)
  x <- r$rg_snap_pick(cand_of(c("Petitot River", "Other Creek"), c(100, 50), c(111, 100)), "Petitot River", 100)
  expect_false(x$accepted)
  expect_equal(x$leg, "name")
  expect_match(x$reason, "named stream's area ratio 1.11")
})

test_that("the area leg runs only where no candidate is on the named stream", {
  r <- local_rule()
  cand <- cand_of(c(NA, "Bowser River"), c(20, 300), c(16, 700))
  x <- r$rg_snap_pick(cand, "Brucejack Lake Outflow", 17.28)
  expect_true(x$accepted)
  expect_equal(x$leg, "area")
  expect_equal(x$linear_feature_id, 1)
  # no area and no named stream: not snapped
  x <- r$rg_snap_pick(cand, "126 Road", NA)
  expect_false(x$accepted)
  expect_match(x$reason, "no drainage area")
  # area outside 10 %: not snapped, the best candidate reported
  x <- r$rg_snap_pick(cand, "126 Road", 30)
  expect_false(x$accepted)
  expect_equal(x$leg, "area")
  expect_match(x$reason, "area ratio 0.53")
})

test_that("candidates without a watershed or an area are dropped; none left is not snapped", {
  r <- local_rule()
  cand <- cand_of(c("Unuk River", "Unuk River"), c(10, 200), c(NA, 1500), ws = c(1, 2))
  expect_equal(r$rg_snap_pick(cand, "Unuk River", NA)$linear_feature_id, 2)
  cand$watershed_feature_id[2] <- NA
  x <- r$rg_snap_pick(cand, "Unuk River", NA)
  expect_false(x$accepted)
  expect_equal(x$reason, "no candidate within tolerance")
  expect_false(r$rg_snap_pick(cand_of(character(), numeric(), numeric()), "Unuk River", NA)$accepted)
  expect_error(r$rg_snap_pick(cand, "Unuk River", 0), "positive number or NA")
  expect_error(r$rg_snap_pick(cand, NA, NA), "one station")
})
