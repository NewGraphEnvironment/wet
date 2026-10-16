# Sandbox for #89: scripts/wb_aet_compare.R on copies of the shipped fit's
# scores, with fu optionally replaced by a synthetic variant a set number of
# points better than cfu on headwater MAE. Run from the root of a worktree
# whose data/wb this script may own, on the machine with the full province run:
#
#   Rscript planning/active/sandbox_89.R <main checkout> <case>
#
# case: real (the shipped fit's scores as they are), fu15 or fu25 (fu replaced
# by cfu's held-out predictions shrunk toward the observed runoff, so its
# headwater MAE is 1.5 or 2.5 points below cfu's).
#
# The copies are re-stamped with this worktree's score_code_md5. That is valid
# only because no score reads scripts/wb_aet_compare.R; the re-stamp check
# (scripts/wb_validate.R cfu in the sandbox, compared with the main
# checkout's copy) tests it.

args <- commandArgs(trailingOnly = TRUE)
main <- normalizePath(args[1], mustWork = TRUE)
case <- args[2]
stopifnot(case %in% c("real", "fu15", "fu25"))
if (normalizePath(".") == main) stop("run from a worktree, not the main checkout")
rel <- "20260717"
key <- "e675918817"

# ---- the sandbox data/wb ------------------------------------------------------------------
marker <- "data/wb/.sandbox_89"
if (file.exists("data/wb") && !file.exists(marker)) stop("data/wb exists and is not this sandbox's")
unlink("data/wb", recursive = TRUE)
dir.create(file.path("data/wb", key, paste0("fit_", rel)), recursive = TRUE)
file.create(marker)
file.symlink(file.path(main, "data/wb", sprintf("stations_%s.rds", rel)), "data/wb")
src_key <- file.path(main, "data/wb", key)
for (f in setdiff(list.files(src_key), list.files(src_key, "^fit_"))) {
  file.symlink(file.path(src_key, f), file.path("data/wb", key, f))
}
src_fit <- file.path(src_key, paste0("fit_", rel))
fit <- file.path("data/wb", key, paste0("fit_", rel))
cp <- c(list.files(src_fit, "^cv_aet-.*\\.rds$"), "pooled_variant.txt", "adjust_override.txt", "pooled_test.txt")
stopifnot(all(file.copy(file.path(src_fit, cp), fit)))
stopifnot(!file.exists(file.path(src_fit, "aet_decision.txt")))

# ---- re-stamp under this worktree's code --------------------------------------------------
devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
release <- rel
source("scripts/wb_score_md5.R")
for (f in list.files(fit, "^cv_aet-.*\\.rds$", full.names = TRUE)) {
  x <- readRDS(f)
  x$code_md5 <- score_code_md5
  saveRDS(x, f)
}

# ---- a synthetic fu -----------------------------------------------------------------------
# as scripts/wb_aet_compare.R's metrics(): headwater stations observing >= 10 mm
hw_mae <- function(obs, mod, nesting) {
  keep <- !is.na(obs) & obs >= 10 & nesting == "headwater"
  mean(abs(100 * (mod[keep] - obs[keep]) / obs[keep]))
}
if (case != "real") {
  gap <- c(fu15 = 1.5, fu25 = 2.5)[[case]]
  x <- readRDS(file.path(fit, "cv_aet-cfu.rds"))
  stopifnot(x$keep_adjust)  # cfu ships adjusted, so cv_ann is what is scored
  hw_cfu <- hw_mae(x$obs, x$cv_ann, x$nesting)
  k <- (hw_cfu - gap) / hw_cfu
  # every error scales by k (obs > 0 and k > 0), so every MAE does
  x$aet <- "fu"
  x$raw <- x$obs + k * (x$raw - x$obs)
  x$cv_ann <- x$obs + k * (x$cv_ann - x$obs)
  is_hw <- function(sm) sm$group == "nesting" & sm$value == "headwater"
  x$cv_v$summary$mae_pct[is_hw(x$cv_v$summary)] <- hw_mae(x$obs, x$cv_ann, x$nesting)
  x$raw_v$summary$mae_pct[is_hw(x$raw_v$summary)] <- hw_mae(x$obs, pmax(x$raw, 0), x$nesting)
  saveRDS(x, file.path(fit, "cv_aet-fu.rds"))
  message(sprintf("synthetic fu: k %.4f, headwater MAE %.2f against cfu %.2f", k,
                  hw_mae(x$obs, x$cv_ann, x$nesting), hw_cfu))
}
message("sandbox ready: ", case, "; score_code_md5 ", score_code_md5)
