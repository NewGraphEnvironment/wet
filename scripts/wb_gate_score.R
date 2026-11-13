# The main-stem gate (#47) scored on every AET variant of both fits, from
# their stored blocked cross-validation (cv_aet-<AET>.rds), with no refit.
#
#   Rscript scripts/wb_gate_score.R
#
# Applies wb_gate() (scripts/wb_gate_rule.R, registered before this script
# first ran) to each variant's headwater and nested MAE, adjusted and raw, and
# sets beside it the headwater-only gate each fit was made under, so it runs
# on scores made before the rule and refuses any made under it. The nested
# gauges are the ones on main stems; the main-stem ratios themselves are in
# data/checks/wb_output_<release>.txt.
#
# fit_20260717 is read from the one complete province run (wb_key_dir()).
# fit_20251014 is #15's frozen record, which scripts/wb_cv_lib.R refuses to
# rescore, so this script does not source it. Two copies exist on the machine
# with the full runs: data/wb/_pre76/e675918817/fit_20251014 (the run with
# the snow layers, the copy tag aet-15-record reproduces and #15's unsuffixed
# reports were last written from) and data/wb/_pre16/962a9cc2c4/fit_20251014
# (the run before the snow layers). It reads the first.
# Writes data/checks/wb_gate_main_stems.txt.

source("scripts/wb_fit_lib.R")
source("scripts/wb_gate_rule.R")
aets <- c("cgiar", "lc", "tc", "fu", "cfu", "fu15", "fu20", "fu35", "mod16", "cmod16")
fits <- c("20251014" = "data/wb/_pre76/e675918817/fit_20251014",
          "20260717" = wb_fit_dir(wb_key_dir(), "20260717"))
mae <- function(v, value) {
  s <- v$summary
  m <- s$mae_pct[s$group == "nesting" & s$value == value]
  if (length(m) != 1L) stop("no single ", value, " row in a summary", call. = FALSE)
  m
}
rows <- do.call(rbind, lapply(names(fits), function(rel) {
  do.call(rbind, lapply(aets, function(a) {
    f <- file.path(fits[[rel]], sprintf("cv_aet-%s.rds", a))
    if (!file.exists(f)) stop("missing ", f, call. = FALSE)
    x <- readRDS(f)
    stopifnot(identical(x$aet, a), identical(x$release, rel))
    # scores made under the rule itself record its arm: they cannot show what
    # the fit was made under, so the comparison would read the rule against itself
    if (!is.null(x[["gate_arm"]])) {
      stop(f, " was scored under #47's rule (it records gate_arm): score the gate on scores made before it",
           call. = FALSE)
    }
    hw <- c(adj = mae(x$cv_v, "headwater"), raw = mae(x$raw_v, "headwater"))
    nes <- c(adj = mae(x$cv_v, "nested"), raw = mae(x$raw_v, "nested"))
    g <- wb_gate(hw[["adj"]], hw[["raw"]], nes[["adj"]], nes[["raw"]])
    data.frame(release = rel, aet = a, hw_adj = hw[["adj"]], hw_raw = hw[["raw"]], nes_adj = nes[["adj"]],
               nes_raw = nes[["raw"]], made_keep = isTRUE(x$keep_adjust), made_pass = isTRUE(x$gate_pass),
               keep = g$keep, arm = g$arm, code_md5 = x$code_md5)
  }))
}))
rows$flip <- rows$keep != rows$made_keep

f_out <- "data/checks/wb_gate_main_stems.txt"
yn <- function(x) ifelse(x, "keep", "drop")
writeLines(c(
  "# The zone adjustment's gate scored on the main stems (#47): every AET variant, both fits",
  "",
  paste("Rule (scripts/wb_gate_rule.R, registered before this score): keep the adjustment if it beats raw",
        "P - AET on headwater gauges; otherwise keep it unless it is worse there by more than",
        sprintf("%.1f point and no better on nested gauges. Blocked-CV MAE, %%, from each fit's", gate_margin_pts),
        "stored cv_aet-<AET>.rds (no refit)."),
  sprintf("fit_20251014: %s (#15's frozen record; the copy tag aet-15-record reproduces)", fits[["20251014"]]),
  sprintf("fit_20260717: %s", fits[["20260717"]]),
  paste("made: what the fit was made under (the headwater gate, and since #43 on fit_20260717 the",
        "override's 0.10-point tolerance); new: the rule above, and the arm that decided."),
  "",
  sprintf("%-8s %-6s %7s %7s %7s %7s  %-5s %-5s %-9s %s", "release", "aet", "hw_adj", "hw_raw", "nes_adj",
          "nes_raw", "made", "new", "arm", "changed"),
  sprintf("%-8s %-6s %7.2f %7.2f %7.2f %7.2f  %-5s %-5s %-9s %s", rows$release, rows$aet, rows$hw_adj,
          rows$hw_raw, rows$nes_adj, rows$nes_raw, yn(rows$made_keep), yn(rows$keep), rows$arm,
          ifelse(rows$flip, "FLIPS", "")),
  "",
  sprintf("variants whose keep or drop changes: %d of %d", sum(rows$flip), nrow(rows)),
  sprintf("fit_20260717 cfu (shipped): %s by the %s arm (made: %s, headwater gate %s)",
          yn(rows$keep[rows$release == "20260717" & rows$aet == "cfu"]),
          rows$arm[rows$release == "20260717" & rows$aet == "cfu"],
          yn(rows$made_keep[rows$release == "20260717" & rows$aet == "cfu"]),
          if (rows$made_pass[rows$release == "20260717" & rows$aet == "cfu"]) "PASS" else "FAIL"),
  "",
  "scoring code md5 of each fit's stored scores:",
  sprintf("  fit_%s: %s", unique(rows$release), tapply(rows$code_md5, rows$release, function(m) {
    paste(unique(substr(m, 1, 12)), collapse = ", ")
  })[unique(rows$release)])
), f_out)
message("wrote ", f_out, "; flips: ", sum(rows$flip))
