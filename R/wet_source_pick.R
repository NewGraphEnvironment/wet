# The default source of a segment's flow (#57): PCIC's routed flow
# (NewGraphEnvironment/fwapg#6) unless its mean annual flow is under far_low
# of the open water balance's, where the balance is picked instead; whichever
# has a value where only one does, NA where neither does. One pick per
# segment, made on annual flow and applied to every month. A far-low routed
# value is a side channel, a reservoir lake or a misplaced outlet more often
# than PCIC's runoff (#58), and the balance is the closer estimate at 9 of the
# 10 calibration gauges this rule flags. A zero balance never displaces
# routed. far_low has no default: scripts/pcic_routed_lib.R's routed_far_low
# is the one definition, shared with the gauge report.
wet_source_pick <- function(q_routed, q_balance, far_low) {
  if (missing(far_low) || length(far_low) != 1 || is.na(far_low) || far_low < 0 || far_low >= 1) {
    stop("far_low must be one number in [0, 1)", call. = FALSE)
  }
  if (length(q_routed) != length(q_balance)) stop("q_routed and q_balance must be the same length", call. = FALSE)
  if (any(q_routed < 0, na.rm = TRUE) || any(q_balance < 0, na.rm = TRUE)) {
    stop("negative flow: the routed table and the balance are clamped at zero", call. = FALSE)
  }
  low <- !is.na(q_routed) & !is.na(q_balance) & q_routed < far_low * q_balance
  out <- ifelse(is.na(q_routed), "wet_balance", "pcic_routed")
  out[low] <- "wet_balance"
  out[is.na(q_routed) & is.na(q_balance)] <- NA_character_
  out
}
