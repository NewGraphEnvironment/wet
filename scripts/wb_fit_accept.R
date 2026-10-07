# Does a fit on a newer HYDAT release ship (#43)? The rule pre-registered in
# planning before either fit was scored:
#
#   blocked-CV MAE on annual runoff (mean |err_pct| of each fit's cv_v, NAs
#   for observed < 10 mm dropped), pooled variant chosen inside each fold, on
#   the calibration gauges common to both fits and headwater in both, each
#   fit scored against its own release's observed runoff; the new fit ships
#   unless its MAE exceeds the old fit's by more than 1.0 point. If it passes
#   but its headwater gate fails (raw P - AET would ship), the decision goes
#   to the user.
#
#   Rscript scripts/wb_fit_accept.R 20251014 20260717
#
# Reads each fit's cv_aet-<AET>.rds for its shipped AET (scripts/wb_validate.R)
# and writes the tracked report wb_report("wb_fit_accept", <new>). It decides
# nothing on disk: switching the shipped release is wb_shipped_release in
# scripts/wb_fit_lib.R, set by hand from this report.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("usage: Rscript scripts/wb_fit_accept.R <old release> <new release>")
release <- args[2]
source("scripts/wb_score_md5.R")  # aet_md5_for()
margin <- 1.0
key_dir <- wb_key_dir()
scores <- lapply(args, function(r) {
  d <- wb_fit_dir(key_dir, r)
  fits <- readRDS(file.path(d, "fits.rds"))
  x <- readRDS(file.path(d, sprintf("cv_aet-%s.rds", fits$aet)))
  # the gate (fits.rds) and the MAE (cv_aet) must come from one scoring run,
  # current under this code
  if (!identical(x$code_md5, fits$code_md5)) stop("fit ", r, ": fits.rds and its scores were made under other code")
  if (!identical(fits$aet_md5, aet_md5_for(r))) stop("fit ", r, " is not current under this code: rerun its chain")
  if (!identical(x$cv_variant, "nested")) {
    stop("fit ", r, " was scored with the pooled variant fixed; the rule uses the nested CV")
  }
  if (!identical(x$release, r)) stop("fit ", r, "'s scores carry release ", x$release)
  e <- x$cv_v$stations
  data.frame(station_number = x$station_number, nesting = x$nesting,
             err = e$err_pct[match(x$station_number, e$station_number)], aet = fits$aet,
             gate = fits$keep_adjust)
})
old <- scores[[1]]
new <- scores[[2]]
if (!identical(old$aet[1], new$aet[1])) stop("the fits ship different AETs: ", old$aet[1], " and ", new$aet[1])
# paired: headwater in both, with an error in both (observed >= 10 mm in each)
common <- intersect(old$station_number[old$nesting == "headwater" & !is.na(old$err)],
                    new$station_number[new$nesting == "headwater" & !is.na(new$err)])
stopifnot(length(common) > 0)
mae_of <- function(x) mean(abs(x$err[match(common, x$station_number)]))
m_old <- mae_of(old)
m_new <- mae_of(new)
ships <- m_new - m_old <= margin
gate_ok <- isTRUE(new$gate[1])

con <- file(wb_report("wb_fit_accept", args[2]), "w")
writeLines(c(
  sprintf("# Does the fit on HYDAT %s ship in place of %s? (#43)", args[2], args[1]), "",
  sprintf("calibration gauges: %s %d, %s %d; in both %d; headwater in both %d",
          args[1], nrow(old), args[2], nrow(new), length(intersect(old$station_number, new$station_number)),
          length(common)),
  sprintf("only in %s: %s", args[1], paste(setdiff(old$station_number, new$station_number), collapse = " ")),
  sprintf("only in %s: %s", args[2], paste(setdiff(new$station_number, old$station_number), collapse = " ")),
  sprintf("AET: %s %s, %s %s", args[1], old$aet[1], args[2], new$aet[1]),
  sprintf("headwater gate (adjusted beats raw P - AET): %s %s, %s %s", args[1],
          if (isTRUE(old$gate[1])) "PASS" else "FAIL", args[2], if (gate_ok) "PASS" else "FAIL"),
  "each fit is scored against its own release's observed runoff: a revised flow moves target and training together",
  "",
  "blocked-CV MAE (%), pooled variant chosen inside each fold, headwater gauges in both:",
  sprintf("  %s %.2f", args, c(m_old, m_new)),
  sprintf("rule: ships unless worse by more than %.1f point", margin),
  sprintf("VERDICT: %s (%+.2f points)%s", if (ships) "SHIPS" else "DOES NOT SHIP", m_new - m_old,
          if (ships && !gate_ok) "; its gate FAILS, so the decision goes to the user" else "")
), con)
close(con)
message("fit ", args[2], if (ships) " ships" else " does not ship", sprintf(" (%+.2f points)", m_new - m_old))
