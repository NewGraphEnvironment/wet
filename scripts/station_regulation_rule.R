# Regulation per non-HYDAT station (#196, #191): the rule, as constants and pure functions.
# Sourced by scripts/station_regulation.R after scripts/station_sources_lib.R (stream_of(),
# regulation_of()), and tested by tests/testthat/test-station_regulation_rule.R. Needs no
# database and no download.
#
# Registered in a commit of its own, with research/station_sources.md's "Regulation" section,
# before scripts/station_regulation.R existed or any station was snapped or placed. The script
# records this file's registering commit and md5 in its report and stops when this file or
# scripts/station_sources_lib.R differs from that commit.
#
# ---- The rule -------------------------------------------------------------------------------
# Decided at #196's plan gate (2026-11-23, the issue's "Decisions"; decision 5 2026-11-24).
#
# Population. Every station wet_station_list() lists outside HYDAT: the provincial registry
# (bcenv_<snapshot>_hydat.csv, 211 stations) and the Water Tool's own listings
# (bcwatertool_<snapshot>_hydat.csv rows with no `continues`, 46); a Tool listing that continues
# a provincial record is that provincial station, as wet_station_list() folds it. One status
# per station, for the year as a whole (decision 2: the licence layer states no season).
#
# Registers. BC's dam register (WHSE_WATER_MANAGEMENT.WRIS_DAMS_PUBLIC_SVW, OGL-BC) and water
# rights licences (WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV, "Access Only"), each
# taken once from the BC WFS per run and held to the server's count. Reservoirs enter through
# the dam register and through storage licences. FWA man-made waterbodies upstream are
# reported beside the status and decide nothing. Only values wet computes from the licence
# layer ship (status, why, L and S, counts), never a licence record (decision 5).
#
# Snap (rg_snap_pick()). fwa_indexpoint() on the station's point, rg_snap_tolerance_m and
# rg_snap_candidates, as wet_station_snap(); a candidate needs a watershed and an upstream area.
#   - name leg: the candidates whose stream_of(gnis_name) equals stream_of(station name) (both
#     non-empty). Where the station's drainage area is known, only those whose upstream area is
#     within rg_snap_max_dev of it. The nearest wins, then the smaller linear_feature_id. A
#     station whose named stream is among the candidates but fails the area test is not snapped.
#   - area leg: where no candidate is on the named stream and the drainage area is known,
#     wet_station_snap()'s own pick (smallest |log(area ratio)|, then distance, then id),
#     accepted within rg_snap_max_dev.
#   - otherwise not snapped.
#   The drainage area is the Tool file's "Drainage Area" header (km^2: Beatton River at Tommy
#   Lakes Road reads 1852.0 against HYDAT 07FC008's 1851.7 at 0.04 km, and the two Petitot
#   listings, 9863.2 and 20410.5, lie upstream of 10DA001's 22260), else HYDAT's gross area at
#   the station's hydat_site; "None" or a missing header is no area.
#
# Status (rg_status()), in this order:
#   - regulated: the name says so (regulation_of());
#   - unknown: not snapped;
#   - regulated: a regulating dam upstream on the network (rg_dam_regulating(): operation
#     "Active" and DAM_REGULATED_CODE "Regulated" or "Regulated - Part 3 Exempt", any
#     DAM_FUNCTION). That code is a dam-safety class, by size and consequence of failure, not
#     a statement about flow;
#   - regulated: licensed consumptive use L >= rg_share, or licensed storage S >= rg_share, of
#     the mean annual flow (#53's thresholds);
#   - unknown: upstream area outside BC (an FWA stream upstream crosses one of rg_borders in
#     fwa_approx_borders), where the registers do not reach;
#   - unknown: a power licence (rg_power_codes, which #53 classes instream and does not count)
#     with a surface POD upstream;
#   - unknown: no published flow at the snapped segment, so L and S cannot be formed;
#   - natural otherwise.
#   A dam, L or S still makes a station outside BC or with a power licence regulated.
#
# Licences counted (L, S). LICENCE_STATUS "Current" in the snapshot, any POD_STATUS, then #53's
# row rules (scripts/wb_gauge_diversion.R, "licence rows", Amendment 1 and Deviation 1) on those
# rows: one row per licence-purpose, POD, quantity flag and units, at the largest quantity its
# repeats carry; a quantity shared by a licence-purpose split over its located PODs, so a group
# straddling the station counts its upstream PODs' share; located, surface (POD_SUBTYPE "POD"),
# not a rediversion, quantity > 0; storage by rg_storage_codes, consumptive by every purpose in
# neither rg_storage_codes nor rg_instream_codes. Under Current only, #53's removal of replaced
# rows removes nothing. A volume is taken in full (no in-force weighting): the snapshot is one
# date. Upstream: whse_basemapping.fwa_upstream() on the point's and the station's codes, and
# for a point in the station's own reach the stream-position test, as #53.
#
# Mean annual flow, the denominator of L and S: wet's published segment_monthly `pick` at the
# snapped segment, month 0 (q_m3s * rg_year_s per year). Most of these records are short or
# seasonal, so their own mean is not an annual one.
#
# Outside check, deciding nothing: at the provincial stations at a HYDAT site, the status
# beside HYDAT's regulation flag for that site.
#
# What was seen before this was registered: the code tables of #53's cached snapshot
# (data/gauge_div/raw/, taken 2026-10-07; the sets below are its values), the Tool's drainage
# areas against HYDAT (above), the two registries' counts, both layers' catalogue records and
# the licence layer's DescribeFeatureType. No station was snapped or placed and no new WFS
# snapshot was taken.
#
# Amendments. A change after any station is placed is dated and appended below this header,
# with its reason; the script's report then gives the statuses under both versions. A code
# outside a known set stops the script: it is a question for the owner, then an amendment.
#
# Report: data/checks/station_regulation_<bcenv snapshot>.txt. Status file:
# inst/extdata/station_sources/regulation_<bcenv snapshot>.csv.
#
# ---- Amendment 1, 2026-11-24 (the owner's decision, before any station was placed) ----------
# The first run, on the WFS snapshot of 2026-11-24, stopped on #53's check that every located
# POD of a shared licence-purpose is counted: one licence shares its quantity over its diversion
# point and a rediversion point (REDIVERSION_IND "Y"), which is never counted, so the diversion
# point carried half of it. No station had been snapped or placed, so no status exists under the
# registered version. Amended: a shared quantity is split over the group's located PODs that are
# not rediversions (rg_split_pods()), since a rediversion moves water already diverted at
# another POD; the check holds over those PODs and still stops on any other gap.
#
# ---- Amendment 2, 2026-11-24 (the owner's decision, after review, before any status shipped) --
# A licence that states no volume (units "Total Flow", for the whole flow of its source, or a
# zero or missing quantity) cannot enter L or S, so a station below one could read natural with
# its licensed use unknown. Amended: a Current, located, surface (POD_SUBTYPE "POD") consumptive
# or storage licence row with no volume, kept and not a rediversion, upstream makes a station
# that nothing regulates unknown, as a power licence does (rg_status()'s `novol_up`). The same
# review found the script counting groundwater PODs in L and S, against the header's
# "surface": corrected in the script, not the rule.
#
# ---- Amendment 3, 2026-11-24 (the owner's decision, after review, before any status shipped) --
# #53's stream-position test drops a point on the station's own reach that indexes even 1 mm
# below the station, so a licence or dam at the gauge (one indexed exactly at its measure) or a
# few metres below it was dropped and the station could read natural. A station's and a point's
# coordinates cannot be told apart that closely. Amended: a point on the station's own blue
# line in its own reach is dropped only when it indexes more than rg_own_margin_m below the
# station; within that, a tie included, it counts as upstream (rg_own_below()).
#
# ---- Amendment 4, 2026-11-27 (the owner's decision 3 at #242's plan gate, before any Hakai ----
# station of its own was listed or placed) -----------------------------------------------------
# The population grows by Hakai's stations of their own: the rows of the Hakai registry
# (hakai_<version>_hydat.csv) with no `continues`, which wet_station_list() lists under their
# own number. A Hakai row that continues a provincial record stays that provincial station, as
# a Tool listing that continues one does. Nothing else changes: snap, registers, status order,
# thresholds and the counted licences are as above. A Hakai station's drainage area could come
# only from a Tool header or a HYDAT site, and it has neither, so only the name leg can snap
# it. The population's counts are the report's, not this header's.
# ---------------------------------------------------------------------------------------------

rg_share <- 0.10              # L or S at or above this share of the mean annual flow: regulated
rg_snap_tolerance_m <- 1000   # fwa_indexpoint() search distance, as wet_station_snap()
rg_snap_candidates <- 5L      # fwa_indexpoint() candidates, as wet_station_snap()
rg_snap_max_dev <- 0.10       # upstream area within this of the drainage area, as wet_station_snap()
rg_year_s <- 365.25 * 86400   # seconds per year, as #53's m3/year conversion
rg_own_margin_m <- 100       # Amendment 3: an own-reach point within this below the station is upstream
rg_vocab <- c("natural", "regulated", "unknown")
rg_borders <- c("AB_120", "USA_49", "YTNWT_60")

# Every value each register wrote in #53's snapshot; any other stops the script.
rg_dam_regulated <- c("Regulated", "Regulated - Part 3 Exempt")
rg_dam_regulated_codes <- c(rg_dam_regulated, "Non-Regulated - Including Minor Dam")
rg_dam_operation_codes <- c("Active", "Application", "Breached (Failed)", "Deactivated", "Decommissioned",
                            "Not Constructed", "Removed")
rg_dam_function_codes <- c("Conversion", "Main", "Outlet", "Saddle", "Spillway")
rg_licence_status_codes <- c("Abandoned", "Cancelled", "Current", "Expired")

# #53's purpose classes (scripts/wb_gauge_diversion.R, "licence rows")
rg_storage_codes <- c("08A", "12A", "11A")
rg_instream_codes <- c("07A", "07B", "07C", "11B", "11C", "02E", "02I38", "02I26", "08B")
rg_power_codes <- c("07A", "07B", "07C")

# Stops on any value of `x` outside `known`, NA included.
rg_codes_check <- function(x, known, what) {
  bad <- unique(x[is.na(x) | !x %in% known])
  if (length(bad)) {
    stop(what, " holds ", paste(ifelse(is.na(bad), "NA", paste0('"', bad, '"')), collapse = ", "),
         ", outside the rule's known set: a question for the owner, then an amendment", call. = FALSE)
  }
  invisible(TRUE)
}

# Amendment 3: whether an own-reach point is below the station and dropped. `indexed` and
# `upstream` are #53's stream-position test (fwa_indexpoint() found the point's stream;
# fwa_upstream() on measures); `same_line` whether the point indexes to the station's blue line,
# `below_m` how far below the station's measure it indexes there (negative above).
rg_own_below <- function(indexed, upstream, same_line, below_m) {
  indexed %in% TRUE & !(upstream %in% TRUE) & !(same_line %in% TRUE & !is.na(below_m) & below_m <= rg_own_margin_m)
}

# A dam that regulates for the rule: active, and in the register's regulated classes.
rg_dam_regulating <- function(operation, regulated, fun) {
  rg_codes_check(operation, rg_dam_operation_codes, "DAM_OPERATION_CODE")
  rg_codes_check(regulated, rg_dam_regulated_codes, "DAM_REGULATED_CODE")
  rg_codes_check(fun, rg_dam_function_codes, "DAM_FUNCTION")
  operation == "Active" & regulated %in% rg_dam_regulated
}

# The PODs a shared quantity is split over (Amendment 1): located, kept (not a licensee repeat),
# sharing, and not a rediversion. #53 split over located kept sharing PODs, rediversions included.
rg_split_pods <- function(located, kept, shared, redivert) {
  located & kept & shared & !redivert
}

# A licence row's class, as #53 classes it; NA purpose is "none".
rg_licence_class <- function(purpose) {
  ifelse(is.na(purpose), "none",
         ifelse(purpose %in% rg_storage_codes, "storage",
                ifelse(purpose %in% rg_instream_codes, "instream", "consumptive")))
}

# One station's snap from its fwa_indexpoint() candidates `cand` (linear_feature_id, gnis_name,
# distance_m, upstream_area_km2, watershed_feature_id), its name and its drainage area (km^2, NA
# when not known). Returns a one-row data.frame(accepted, leg, linear_feature_id, distance_m,
# upstream_area_km2, area_ratio, reason).
rg_snap_pick <- function(cand, name, area_km2) {
  if (length(name) != 1L || is.na(name) || length(area_km2) != 1L) {
    stop("one station: a name and one drainage area (NA when not known)", call. = FALSE)
  }
  if (!is.na(area_km2) && (!is.finite(area_km2) || area_km2 <= 0)) {
    stop("a drainage area must be a positive number or NA", call. = FALSE)
  }
  need <- c("linear_feature_id", "gnis_name", "distance_m", "upstream_area_km2", "watershed_feature_id")
  if (length(setdiff(need, names(cand)))) stop("cand needs ", paste(need, collapse = ", "), call. = FALSE)
  out <- function(i, leg, reason = "") {
    data.frame(accepted = !is.na(i) & !nzchar(reason), leg = leg,
               linear_feature_id = if (is.na(i)) NA_real_ else cand$linear_feature_id[i],
               distance_m = if (is.na(i)) NA_real_ else cand$distance_m[i],
               upstream_area_km2 = if (is.na(i)) NA_real_ else cand$upstream_area_km2[i],
               area_ratio = if (is.na(i)) NA_real_ else cand$upstream_area_km2[i] / area_km2,
               reason = reason)
  }
  usable <- !is.na(cand$watershed_feature_id) & !is.na(cand$upstream_area_km2)
  cand <- cand[usable, , drop = FALSE]
  if (!nrow(cand)) return(out(NA_integer_, "", "no candidate within tolerance"))
  s <- stream_of(name)
  cs <- rep(NA_character_, nrow(cand))
  cs[!is.na(cand$gnis_name)] <- stream_of(cand$gnis_name[!is.na(cand$gnis_name)])
  on_name <- nzchar(s) & !is.na(cs) & cs == s
  ratio <- cand$upstream_area_km2 / area_km2
  area_ok <- is.na(area_km2) | abs(ratio - 1) <= rg_snap_max_dev
  if (any(on_name)) {
    ok <- which(on_name & area_ok)
    if (!length(ok)) {
      j <- which(on_name)
      j <- j[order(cand$distance_m[j], cand$linear_feature_id[j])][1]
      return(out(j, "name", sprintf("the named stream's area ratio %.2f is outside 1 +/- %.2f", ratio[j],
                                    rg_snap_max_dev)))
    }
    j <- ok[order(cand$distance_m[ok], cand$linear_feature_id[ok])][1]
    return(out(j, if (is.na(area_km2)) "name" else "name and area"))
  }
  if (is.na(area_km2)) return(out(NA_integer_, "", "no candidate on the named stream and no drainage area"))
  o <- order(abs(log(ratio)), cand$distance_m, cand$linear_feature_id)
  j <- o[1]
  if (!area_ok[j]) {
    return(out(j, "area", sprintf("area ratio %.2f outside 1 +/- %.2f", ratio[j], rg_snap_max_dev)))
  }
  out(j, "area")
}

# The status of each station. `name_regulated` and `snapped` are logical; for snapped stations
# `dams_up` (regulating dams upstream), `outside_bc`, `power_up` and `novol_up` (a licence with no
# volume upstream, Amendment 2) must be known, and L_share and S_share are NA together, where the
# segment has no published flow. Returns data.frame(regulation, why).
rg_status <- function(name_regulated, snapped, dams_up, L_share, S_share, outside_bc, power_up, novol_up) {
  n <- length(name_regulated)
  args <- list(snapped, dams_up, L_share, S_share, outside_bc, power_up, novol_up)
  if (any(lengths(args) != n)) stop("every argument needs one value per station", call. = FALSE)
  if (!is.logical(name_regulated) || !is.logical(snapped) || anyNA(name_regulated) || anyNA(snapped)) {
    stop("name_regulated and snapped must be TRUE or FALSE", call. = FALSE)
  }
  s <- snapped
  if (anyNA(dams_up[s]) || anyNA(outside_bc[s]) || anyNA(power_up[s]) || anyNA(novol_up[s]) || any(dams_up[s] < 0)) {
    stop("a snapped station needs its dams, border, power and no-volume tests", call. = FALSE)
  }
  if (any(is.na(L_share[s]) != is.na(S_share[s])) ||
      any(!is.na(L_share[s]) & (!is.finite(L_share[s]) | L_share[s] < 0 | !is.finite(S_share[s]) | S_share[s] < 0))) {
    stop("L_share and S_share must both be non-negative numbers, or both NA (no published flow)", call. = FALSE)
  }
  pct <- function(x) sprintf("%.1f %%", 100 * x)
  res <- lapply(seq_len(n), function(i) {
    why <- character()
    if (name_regulated[i]) why <- c(why, "name")
    if (!s[i]) {
      return(list(if (name_regulated[i]) "regulated" else "unknown", c(why, "no accepted snap")))
    }
    flow <- !is.na(L_share[i])
    hit_dam <- dams_up[i] > 0
    hit_L <- flow && L_share[i] >= rg_share
    hit_S <- flow && S_share[i] >= rg_share
    if (hit_dam) why <- c(why, sprintf("%d regulating dam%s upstream", dams_up[i], if (dams_up[i] > 1) "s" else ""))
    if (hit_L) why <- c(why, paste("licensed use", pct(L_share[i])))
    if (hit_S) why <- c(why, paste("licensed storage", pct(S_share[i])))
    if (outside_bc[i]) why <- c(why, "upstream area outside BC")
    if (power_up[i]) why <- c(why, "power licence upstream")
    if (novol_up[i]) why <- c(why, "licence with no volume upstream")
    if (!flow) why <- c(why, "no published flow")
    reg <- if (name_regulated[i] || hit_dam || hit_L || hit_S) {
      "regulated"
    } else if (outside_bc[i] || power_up[i] || novol_up[i] || !flow) {
      "unknown"
    } else {
      why <- sprintf("no regulating dam; licensed use %s, storage %s", pct(L_share[i]), pct(S_share[i]))
      "natural"
    }
    list(reg, why)
  })
  data.frame(regulation = vapply(res, `[[`, "", 1),
             why = vapply(res, function(r) paste(r[[2]], collapse = "; "), ""))
}
