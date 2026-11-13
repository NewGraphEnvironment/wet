# The zone adjustment's gate (#47), one rule for the fit and its score:
# sourced by scripts/wb_cv_lib.R (so scripts/wb_validate.R and
# scripts/wb_aet_compare.R apply it) and by scripts/wb_gate_score.R (which
# scores it on both fits from their stored cross-validation). Needs nothing.
#
# Registered here, in a commit of its own, before it was scored on any fit.
# The rule: keep the zone adjustment if it beats raw P - AET on headwater
# gauges (blocked-CV MAE, %). Otherwise keep it unless both of these hold:
#   * it is worse on headwater gauges by more than 1.0 point, the margin #83
#     set for accepting a refit (scripts/wb_fit_accept.R);
#   * it is no better on nested gauges.
# Before #47 the gate scored headwater gauges alone, so an adjustment that
# corrects the main stems, which only nested gauges measure, could be dropped
# over a tie on headwater ones; #43's refit kept it only through a per-fit
# override (adjust_override.txt, a 0.03-point tie within a 0.5-point cap).
# Disclosed: both fits' headwater and nested MAEs, adjusted and raw, were
# public before this rule was written (the #47 body; research/
# water_balance_method.md section 0; every wb_validation report), so the rule
# was not written blind to them. The margin is #83's, set for another purpose.

gate_margin_pts <- 1.0

# Whether the adjustment ships, and by which arm of the rule: "headwater"
# (it beats raw on headwater gauges), "margin" (worse there by no more than
# gate_margin_pts), "nested" (worse by more, but better on nested gauges) or
# "dropped". An NA MAE refuses, rather than reaching a comparison.
wb_gate <- function(hw_adj, hw_raw, nes_adj, nes_raw) {
  x <- c(hw_adj = hw_adj, hw_raw = hw_raw, nes_adj = nes_adj, nes_raw = nes_raw)
  if (length(x) != 4L || !all(is.finite(x))) {
    stop("the gate needs four finite MAEs (headwater and nested, adjusted and raw): ",
         paste(names(x), format(x), sep = " = ", collapse = ", "), call. = FALSE)
  }
  arm <- if (hw_adj < hw_raw) {
    "headwater"
  } else if (hw_adj - hw_raw <= gate_margin_pts) {
    "margin"
  } else if (nes_adj < nes_raw) {
    "nested"
  } else {
    "dropped"
  }
  list(keep = arm != "dropped", arm = arm)
}
