# The md5 of what a variant's scores depend on (#15), sourced by
# scripts/wb_cv_lib.R (to stamp scores and fits) and scripts/wb_output.R (to
# refuse a fit made under other code). One recipe, so the two cannot drift.
# Needs wet_md5_text() (devtools::load_all()).

# md5 of what a variant's scores depend on besides the province run itself
# (its own run directory): the scoring code, the decision rule (so a winner
# chosen under an older rule is never shipped) and the stations file, which
# scripts/wb_stations.R rewrites from HYDAT. Stored with each variant's results
# so scripts/wb_aet_compare.R never compares variants scored from different
# code or observations. A missing file stops here: tools::md5sum() would hash
# it as NA on both sides and the check would pass.
score_files <- c("scripts/wb_score_md5.R", "scripts/wb_cv_lib.R", "scripts/wb_validate.R",
                 "scripts/wb_aet_compare.R", "data/wb/stations.rds",
                 "R/wet_wb_fit.R", "R/wet_wb_adjust.R", "R/wet_share_fit.R", "R/wet_share_predict.R",
                 "R/wet_flow_validate.R", "R/wet_cv_folds.R", "R/wet_wb_raw.R", "R/wet_mm_to_m3s.R")
if (!all(file.exists(score_files))) stop("missing: ", paste(score_files[!file.exists(score_files)], collapse = ", "))
score_code_md5 <- wet_md5_text(unname(tools::md5sum(score_files)))
