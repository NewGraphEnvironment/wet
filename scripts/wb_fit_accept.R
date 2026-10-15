# Does a fit on a newer HYDAT release ship in place of the shipped one? The
# rule, pre-registered for #43 and restated for #83 before any later release
# was scored (research/water_balance_method.md, section 0, "Accepting the next
# refit"):
#
#   blocked-CV MAE on annual runoff (mean |err_pct| of each fit's cv_v, NAs
#   for observed < 10 mm dropped), each fit as it ships: the headline CV of
#   its shipped AET under its own decision files (pooled_variant.txt,
#   adjust_override.txt, aet_decision.txt), on the calibration gauges common
#   to both fits and headwater in both, each fit scored against its own
#   release's observed runoff; the new fit ships unless its MAE exceeds the
#   shipped fit's by more than 1.0 point. If it passes but its headwater gate
#   fails, the decision goes to the user. The new fit is compared only once
#   its chain is complete (AET decided, pooled-zone test run, wb_validate.R
#   rerun), so its fits.rds and winner are current under its decision files
#   and its scores use the test's outcome. The new release must be later than
#   the shipped one.
#
#   Rscript scripts/wb_fit_accept.R <shipped release> <new release>
#
# #43 (20251014 -> 20260717) scored both fits with the pooled variant chosen
# inside each fold; that report, data/checks/wb_fit_accept_20260717.txt, is
# its record and is not rewritten. The two fits may ship different AETs: a
# switch exists only through a user-recorded aet_decision.txt (#81).
#
# Reads each fit's cv_aet-<AET>.rds for its shipped AET (scripts/wb_validate.R)
# and writes the tracked report wb_report("wb_fit_accept", <new>). It decides
# nothing on disk: switching the shipped release is wb_shipped_release in
# scripts/wb_fit_lib.R, set by hand from this report.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("usage: Rscript scripts/wb_fit_accept.R <shipped release> <new release>")
if (!identical(args[1], wb_shipped_release)) stop("the old fit must be the shipped one, fit_", wb_shipped_release)
# newer than the shipped one, so a run can never rewrite an older release's
# report, #43's wb_fit_accept_20260717.txt included
if (!grepl("^[0-9]{8}$", args[2]) || args[2] <= args[1]) stop("the new fit must be a release after the shipped one")
margin <- 1.0
key_dir <- wb_key_dir()
# a release's score_code_md5: its scoring code, stations and decision files,
# by the recipe the scoring scripts stamp with (scripts/wb_score_md5.R)
score_md5_for <- function(r) {
  e <- new.env()
  e$release <- r
  sys.source("scripts/wb_score_md5.R", envir = e)
  e$score_code_md5
}
scores <- lapply(args, function(r) {
  d <- wb_fit_dir(key_dir, r)
  fits <- readRDS(file.path(d, "fits.rds"))
  x <- readRDS(file.path(d, sprintf("cv_aet-%s.rds", fits$aet)))
  # as it ships: the gate (fits.rds), the MAE (cv_aet) and the AET choice
  # all current under this release's code and decision files, as
  # scripts/wb_output.R and scripts/discharge_publish.R require
  md5 <- score_md5_for(r)
  if (!identical(fits$code_md5, md5) || !identical(x$code_md5, md5)) {
    stop("fit ", r, " is not current under its code and decision files: complete its chain (scripts/wb_validate.R)")
  }
  f_winner <- file.path(d, "aet_winner.txt")
  if (!file.exists(f_winner) || !identical(readLines(f_winner)[1:2], c(fits$aet, md5))) {
    stop("fit ", r, " has no current AET winner for ", fits$aet, ": rerun scripts/wb_aet_compare.R")
  }
  if (!identical(x$release, r) || !identical(fits$release, r)) stop("fit ", r, "'s scores carry another release")
  # the pooled-zone test has run, and the scores use its outcome: a fixed
  # variant, or the nested choice when it was uninformative. Its outcome file
  # is not hashed, and pooled_variant.txt exists only when it fixed one.
  f_test <- file.path(d, "pooled_test.txt")
  if (!file.exists(f_test)) stop("fit ", r, " has no pooled-zone test: run scripts/wb_pooled_test.R, then rescore")
  tested <- readLines(f_test)[1]
  if (!identical(x$cv_variant, if (identical(tested, "uninformative")) "nested" else tested)) {
    stop("fit ", r, " was scored with pooled variant ", x$cv_variant, ", but its pooled-zone test gave ", tested)
  }
  e <- x$cv_v$stations
  data.frame(station_number = x$station_number, nesting = x$nesting,
             err = e$err_pct[match(x$station_number, e$station_number)], aet = fits$aet,
             variant = if (identical(x$cv_variant, "nested")) "chosen inside each fold" else
               sprintf("fixed to '%s'", x$cv_variant),
             # the gate itself, and whether an override keeps the adjustment
             gate = if (is.null(fits$gate_pass)) fits$keep_adjust else fits$gate_pass,
             keep_adjust = fits$keep_adjust)
})
old <- scores[[1]]
new <- scores[[2]]
# paired: headwater in both, with an error in both (observed >= 10 mm in each)
common <- intersect(old$station_number[old$nesting == "headwater" & !is.na(old$err)],
                    new$station_number[new$nesting == "headwater" & !is.na(new$err)])
stopifnot(length(common) > 0)
mae_of <- function(x) mean(abs(x$err[match(common, x$station_number)]))
m_old <- mae_of(old)
m_new <- mae_of(new)
ships <- m_new - m_old <= margin
gate_ok <- isTRUE(new$gate[1])
gate_txt <- function(x) {
  if (isTRUE(x$gate[1])) "PASS" else if (isTRUE(x$keep_adjust[1])) "FAIL (adjustment kept by override)" else "FAIL"
}

con <- file(wb_report("wb_fit_accept", args[2]), "w")
writeLines(c(
  sprintf("# Does the fit on HYDAT %s ship in place of %s? (#43, #83)", args[2], args[1]), "",
  sprintf("calibration gauges: %s %d, %s %d; in both %d; headwater in both %d",
          args[1], nrow(old), args[2], nrow(new), length(intersect(old$station_number, new$station_number)),
          length(common)),
  sprintf("only in %s: %s", args[1], paste(setdiff(old$station_number, new$station_number), collapse = " ")),
  sprintf("only in %s: %s", args[2], paste(setdiff(new$station_number, old$station_number), collapse = " ")),
  sprintf("AET: %s %s, %s %s%s", args[1], old$aet[1], args[2], new$aet[1],
          if (identical(old$aet[1], new$aet[1])) "" else " (switched)"),
  sprintf("pooled variant: %s %s, %s %s", args[1], old$variant[1], args[2], new$variant[1]),
  sprintf("headwater gate (adjusted beats raw P - AET): %s %s, %s %s", args[1], gate_txt(old), args[2], gate_txt(new)),
  "each fit is scored as it ships, against its own release's observed runoff: a revised flow moves target and training together",
  "",
  "blocked-CV MAE (%), each fit as it ships, headwater gauges in both:",
  sprintf("  %s %.2f", args, c(m_old, m_new)),
  sprintf("rule: ships unless worse by more than %.1f point", margin),
  sprintf("VERDICT: %s (%+.2f points)%s", if (ships) "SHIPS" else "DOES NOT SHIP", m_new - m_old,
          if (ships && !gate_ok) "; its gate FAILS, so the decision goes to the user" else "")
), con)
close(con)
message("fit ", args[2], if (ships) " ships" else " does not ship", sprintf(" (%+.2f points)", m_new - m_old))
