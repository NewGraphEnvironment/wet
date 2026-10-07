# The md5 of what a variant's scores depend on (#15), sourced by
# scripts/wb_cv_lib.R (to stamp scores and fits) and scripts/wb_output.R (to
# refuse a fit made under other code). One recipe, so the two cannot drift.
# Needs wet_md5_text() (devtools::load_all()), scripts/wb_fit_lib.R and `release`.

# md5 of what a variant's scores depend on besides the province run itself
# (its own run directory): the scoring code, the decision rule (so a winner
# chosen under an older rule is never shipped) and the fit's stations file,
# which scripts/wb_stations.R writes from one HYDAT release (#43). Stored with each variant's results
# so scripts/wb_aet_compare.R never compares variants scored from different
# code or observations. A missing file stops here: tools::md5sum() would hash
# it as NA on both sides and the check would pass.
score_files_for <- function(rel) {
  f <- c("scripts/wb_score_md5.R", "scripts/wb_cv_lib.R", "scripts/wb_validate.R",
         "scripts/wb_aet_compare.R", wb_stations_path(rel),
         "R/wet_wb_fit.R", "R/wet_wb_adjust.R", "R/wet_share_fit.R", "R/wet_share_predict.R",
         "R/wet_flow_validate.R", "R/wet_cv_folds.R", "R/wet_wb_raw.R", "R/wet_mm_to_m3s.R")
  if (!all(file.exists(f))) stop("missing: ", paste(f[!file.exists(f)], collapse = ", "))
  f
}
# the md5 a fit's AET choice is current under, for any release (#43: a carry
# checks the fit it carries from is current, not only self-consistent)
aet_md5_for <- function(rel) wet_md5_text(unname(tools::md5sum(score_files_for(rel))))
score_files <- score_files_for(release)
# The AET choice (aet_winner.txt) is made, or carried, before any pooled-zone
# variant is fixed, so it is checked against the md5 without one
# (aet_code_md5). A variant fixed for this fit (scripts/wb_pooled_test.R, #43)
# changes its scores and fits, so a fit made before it is stale after it:
# score_code_md5 covers it.
aet_code_md5 <- aet_md5_for(release)
f_pooled_md5 <- file.path(wb_fit_dir(wb_key_dir(), release), "pooled_variant.txt")
score_code_md5 <- if (file.exists(f_pooled_md5)) {
  wet_md5_text(unname(tools::md5sum(c(score_files, f_pooled_md5))))
} else {
  aet_code_md5
}
