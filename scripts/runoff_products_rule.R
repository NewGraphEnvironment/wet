# Runoff products no report scored before (#243, #225): the rule, registered
# in this file before scripts/runoff_products_compare.R existed and before any
# value of either product was read, and the functions that apply it.
# scripts/runoff_products_compare.R sources this file and refuses to run when
# it differs from its registering commit. No database, no download: the
# script supplies every input. The thresholds are the owner's (2026-11-27).
#
# ---- question --------------------------------------------------------------------------------
#
# Where do TerraClimate's runoff and the BC 1961-1990 runoff isolines disagree
# materially with the held-out balance about mean annual runoff at the gauges,
# and is each disagreement ours, theirs or unresolved?
#
# ---- products --------------------------------------------------------------------------------
#
# TerraClimate runoff: the 1981-2010 climatology TerraClimate_19812010_q.nc
# (variable q, 12 monthly layers, mm per month), read at its own 1/24 degree
# lattice with no resampling. Annual runoff is the sum of the 12 months. Its
# coverage at a gauge is the share of the basin's area on a TerraClimate cell
# with a value.
#
# Runoff isolines: WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE (Normal
# Annual Runoff Isolines, 1961-1990; OGL-BC), annual runoff in mm, gridded to
# two surfaces on one fixed 1 km BC Albers grid: a TIN (linear, no
# extrapolation beyond the triangulation) and inverse distance (power 2,
# radius 50 km, at most 12 points). The verdict is the TIN's. Its coverage at
# a gauge is the share of the basin's area on a cell where both surfaces have
# a value.
#
# ---- gauges and scores -----------------------------------------------------------------------
#
# The shipped fit's 315 calibration gauges (HYDAT 20260717, cv_aet-cfu.rds).
# Observed annual runoff and the held-out balance (cv_ann) come from
# inst/vignette-data/monthly_values.rds, held equal to cv_aet-cfu.rds. A
# product is scored at a gauge where its coverage is at least rp_coverage. A
# gauge's product value is the area-weighted mean over the covered part of its
# basin (wet_ws_sample(), wet_upstream_means()).
#
# Error at a gauge (rp_error()): 100 * (modelled / observed - 1), in %. Within
# means |error| <= rp_within. A zone is the gauge's hydrologic zone (cal$zone,
# the zone holding most of its basin).
#
# For each product, on the gauges it scores: the product's median error and
# the held-out balance's median error over the same gauges.
#
# ---- verdict ---------------------------------------------------------------------------------
#
# Per hydrologic zone, and once over every scored gauge (province-wide), by
# rp_verdict():
#   - fewer than rp_min_gauges scored gauges: "too few" (the province-wide
#     test has no minimum);
#   - the two medians differ by rp_material points or less (exactly
#     rp_material included): "not material";
#   - otherwise, both inside +-rp_within: "not material";
#   - product outside and balance inside: "theirs";
#   - product inside and balance outside: "ours";
#   - both outside: "unresolved".
#
# Isolines only, the period (1961-1990 against observed years in 1981-2010):
# where the verdict would be "theirs", the isoline values are multiplied by
# the zone's period ratio (rp_period_ratio(); province-wide, the median over
# every period gauge). When the median error of the scaled values is within
# +-rp_within, the verdict is "unresolved (period)". A zone without a ratio
# keeps "theirs", printed "theirs (period untested)".
#
# Period gauges: natural BC HYDAT gauges (wet_station_select(), REGULATED =
# 0) with at least rp_period_years complete years (all 12 months with at
# least 20 days) in 1961-1990 and again in 1981-2010. A gauge's ratio is its
# mean annual flow over its complete 1981-2010 years divided by that over its
# complete 1961-1990 years (wet_station_monthly(), month 0). Its zone is the
# hydrologic zone its HYDAT location falls in. A zone's ratio is the median
# over its period gauges, when it has at least rp_period_min; otherwise it has
# none.
#
# Stability (rp_judge()): the verdict is recomputed with each scored gauge
# left out in turn (no minimum count on the subsets); a verdict any subset
# changes is printed "unstable (<verdict>)". The isolines' verdict on the
# inverse-distance surface is printed beside the TIN's; where it differs, the
# TIN verdict is marked "surface-dependent".
#
# ---- reported, deciding nothing --------------------------------------------------------------
#
#   - Per product, province-wide and by zone: n, median error and middle half,
#     share within +-rp_within, beside the balance and routed PCIC (routed
#     over those gauges that are also among its 283 shared gauges).
#   - TerraClimate's monthly NSE and share NSE (twelve monthly shares, so
#     volume does not enter), beside the balance's and routed PCIC's.
#   - The gauges each product does not score, by zone and reason.
#   - The isolines' TIN against inverse distance at each gauge, and each
#     gauge's share of basin area on flat triangles (all three vertices at one
#     level), which both surfaces share and their spread cannot show.
#   - For TerraClimate, the four-term split of its gap to the balance at each
#     gauge: precipitation, AET, TerraClimate's storage and fill, and the
#     zone adjustment, summing to the gap.
#   - A plumbing check, not a finding: TerraClimate's annual runoff against
#     the province run's ppt_tc - aet_tc at gauges TerraClimate fully covers;
#     a median absolute difference above 5 % stops the run.
#
# ---- as seen before registration -------------------------------------------------------------
#
# 2026-11-27. Public before this file: TerraClimate precipitation beside ours
# and PCIC's at the dry-zone gauges (data/checks/wb_term_diagnose_20260717.txt,
# data/checks/wb_small_basin_20260717.txt, research/water_balance_method.md);
# climr precipitation minus TerraClimate AET scored as the AET variant "tc"
# (data/checks/wb_aet_compare_20260717.txt); the province run's ppt_tc and
# aet_tc at the calibration gauges, never compared with observed as
# ppt_tc - aet_tc. The isolines' line count and levels (66 lines; 50 to 4,000
# mm at nine levels), read while planning. No value of TerraClimate's runoff
# or of an isoline surface at a gauge had been read.
#
# ---- what it does not decide -----------------------------------------------------------------
#
# Nothing the balance or the published product uses: both products are
# references here (CLAUDE.md, "Own estimates first"). Later products (#244,
# #245) are scored under this rule and appended to the same log.
#
# ---- amendments ------------------------------------------------------------------------------
#
# Any change to this file after its registering commit is an amendment:
# dated, appended below with its reason and what had been seen, never an edit
# of the text above; the script's rule_commit moves to it; and the report gives
# the verdict under each version since the first score existed.
#
# (none)

# ---- constants ---------------------------------------------------------------------------------

rp_release <- "20260717"
rp_coverage <- 0.95      # basin share a product must cover to be scored at a gauge
rp_min_gauges <- 5       # scored gauges a zone needs for a verdict
rp_within <- 20          # |error| <= this, in %, is within
rp_material <- 20        # medians further apart than this, in points, are material
rp_period_years <- 20    # complete years in each of 1961-1990 and 1981-2010
rp_period_min <- 3       # period gauges a zone needs for a ratio
rp_plumbing <- 5         # %: median |q - (ppt_tc - aet_tc)| / (ppt_tc - aet_tc) at full cover

# ---- functions ---------------------------------------------------------------------------------

rp_error <- function(mod, obs) {
  stopifnot(length(mod) == length(obs), all(is.finite(obs) & obs > 0))
  100 * (mod / obs - 1)
}

rp_inside <- function(e) abs(e) <= rp_within

# The verdict on one set of gauges. err_p, err_b: the product's and the balance's
# errors (%) at the same gauges. err_period: the product's errors after the period
# ratio, or NULL where no period test applies; NA (one value) where it applies but
# the zone has no ratio. check_n: apply the minimum count.
rp_verdict <- function(err_p, err_b, err_period = NULL, check_n = TRUE) {
  stopifnot(length(err_p) == length(err_b), !anyNA(err_p), !anyNA(err_b))
  if (check_n && length(err_p) < rp_min_gauges) return("too few")
  if (!length(err_p)) return("too few")
  mp <- stats::median(err_p)
  mb <- stats::median(err_b)
  if (abs(mp - mb) <= rp_material) return("not material")
  if (rp_inside(mp) && rp_inside(mb)) return("not material")
  if (rp_inside(mp)) return("ours")
  if (!rp_inside(mb)) return("unresolved")
  if (is.null(err_period)) return("theirs")
  if (length(err_period) == 1 && is.na(err_period)) return("theirs (period untested)")
  stopifnot(length(err_period) == length(err_p), !anyNA(err_period))
  if (rp_inside(stats::median(err_period))) "unresolved (period)" else "theirs"
}

# The verdict with leave-one-gauge-out stability. The minimum count applies to the
# whole set, not to the subsets.
rp_judge <- function(err_p, err_b, err_period = NULL, check_n = TRUE) {
  v <- rp_verdict(err_p, err_b, err_period, check_n)
  if (v == "too few" || length(err_p) < 2) return(v)
  sub_period <- function(i) {
    if (is.null(err_period) || (length(err_period) == 1 && is.na(err_period))) err_period else err_period[-i]
  }
  loo <- vapply(seq_along(err_p), function(i) {
    rp_verdict(err_p[-i], err_b[-i], sub_period(i), check_n = FALSE)
  }, "")
  if (any(loo != v)) sprintf("unstable (%s)", v) else v
}

# A zone's period ratio: the median of its gauges' 1981-2010 / 1961-1990 mean annual
# flow ratios, NA with fewer than rp_period_min gauges.
rp_period_ratio <- function(ratios) {
  ratios <- ratios[!is.na(ratios)]
  stopifnot(all(is.finite(ratios) & ratios > 0))
  if (length(ratios) < rp_period_min) NA_real_ else stats::median(ratios)
}
