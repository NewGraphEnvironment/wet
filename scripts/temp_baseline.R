# Water temperature at a station with no record (#213): air2stream parameters predicted from
# catchment traits, with a whole station held out at a time.
#
#   Rscript scripts/temp_baseline.R
#
# ---- The rule -------------------------------------------------------------------------------
# Registered in this header and in scripts/temp_baseline_rule.R before any real score was
# computed; the thresholds are the owner's (2026-11-25). The commit that added this header is
# the registration, and the next commit writes its sha here.
#
# Truth. The station-years of scripts/temp_fill_validate.R (1 March - 30 November observed with
#   no gap longer than 2 days), at the stations the holdout frame keeps
#   (scripts/temp_baseline_traits.R: snapped to the FWA, at least 95 % of the basin inside BC
#   and on the trait grids).
# Held out. A whole station: its parameters are predicted from other stations only.
# Parameters. Open-loop air2stream, S[t] = S[t-1] + a1 + a2 A[t] - a3 S[t-1], as wet_temp_fill()
#   fits it. A candidate predicts theta = (a1 / a3, a2 / a3, qlogis(a3)): the equilibrium
#   intercept, the equilibrium slope and the response rate. theta is turned back to a1, a2, a3.
# Candidates.
#   mean        the training stations' mean theta (what a model with no covariates gives)
#   regression  ordinary least squares of each theta on the traits
#   donor       wet:::wet_donor_mean() over the k = 5 nearest training stations in trait space,
#               the traits z-scored on the training stations
# Traits. Upstream means of elevation, easting, northing, snowmelt_doy_50 and swe_max; log10
#   upstream area; glacier cover and lake cover (lakes and reservoirs), each a share of
#   upstream area.
# Pools.
#   blocked     wet_cv_folds(): the stations of one WSC sub-sub-drainage are held out together
#   leak-free   each held-out station is predicted from its fold's training stations less those
#               upstream or downstream of it, with every candidate refitted
# Run. wet:::wet_a2s_run() with the predicted parameters on the station's own daily air.
# Benchmark. The same run with the station's own parameters, fitted to its whole record.
# Scores, per station-year. Daily RMSE on the observed days of 1 March - 30 November, and GSDD
#   error: wet_temp_gsdd() on the predicted series against the observed year.
#
# The statistic the rule reads, for each candidate and pool and for the benchmark: the mean,
# over held-out stations, of the station's mean absolute GSDD error over its truth years
# (degC-days).
#
# 1. Which candidate is reported as the baseline. The population mean, unless a trait candidate
#    (regression, donor) beats it by at least 10 degC-days in both pools. When both do, the one
#    with the lower leak-free score; regression when the two are equal at one decimal.
# 2. Close. The baseline is close to the benchmark when its score is within 50 degC-days of the
#    benchmark's in both pools: half the width of the band between the cutthroat thresholds
#    (under 800 degree days unsuitable, 900 and over best). Within 50 in one pool only is
#    reported as that, and is not close.
# 3. A difference exactly on a threshold counts: 10 displaces, 50 is close.
# 4. A candidate scored later on this frame (network kriging, #223) is scored in both pools and
#    reported beside the baseline. It does not become the baseline under this rule.
#
# Printed beside the rule and deciding nothing: the relative gap to the benchmark; the same
# means taken over station-years; daily RMSE and bias; the hidden-season score of
# scripts/temp_fill_validate.R on the same station-years; the breakdowns by WSC sub-drainage,
# lake influence and glacier cover; and how often each candidate's interval holds the station's
# own theta.
#
# Recovery first. This script refuses to score unless data/checks/temp_baseline_recover.txt is
# committed and names the md5s of scripts/temp_baseline_lib.R and scripts/temp_baseline_rule.R
# as they stand, and the holdout frame it ran on (scripts/temp_baseline_recover.R: every
# candidate on stations simulated from known trait-to-parameter relationships with a part
# shared along the stream network).
# ---------------------------------------------------------------------------------------------

source("scripts/temp_baseline_rule.R")
stop("scripts/temp_baseline.R holds the registered rule only; the scores are built in a later commit",
     call. = FALSE)
