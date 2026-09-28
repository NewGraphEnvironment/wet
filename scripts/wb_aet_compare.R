# Compare the annual AET variants of the ET experiment (#15) and apply the
# decision rule fixed in planning before any variant was scored.
#
#   for v in cgiar lc tc fu cfu fu15 fu20 fu35; do Rscript scripts/wb_validate.R $v; done
#   Rscript scripts/wb_aet_compare.R
#   Rscript scripts/wb_validate.R <winner>   # writes fits.rds and wb_validation.txt
#
# Reads data/wb/<key>/cv_aet-<v>.rds (scripts/wb_validate.R) and writes the
# tracked report data/checks/wb_aet_compare.txt, and the winner to
# data/wb/<key>/aet_winner.txt, which scripts/wb_validate.R ships (run it
# again for the winner to write fits.rds). It also runs a fully nested
# selection: each outer blocked fold picks the AET variant (and whether to
# adjust) by the same rule applied to an inner blocked CV on its training
# stations, so the winner's error is estimated without having been selected on
# the stations it is scored on.

source("scripts/wb_cv_lib.R")
# a winner is only ever the result of a complete comparison under this code
unlink(file.path(key_dir, "aet_winner.txt"))
eligible <- c("lc", "tc", "fu", "cfu")
transparency <- c("fu15", "fu20", "fu35")
variants_all <- c("cgiar", eligible, transparency)
res <- lapply(variants_all, function(v) {
  f <- file.path(key_dir, sprintf("cv_aet-%s.rds", v))
  if (!file.exists(f)) stop("no ", f, ": run scripts/wb_validate.R ", v)
  x <- readRDS(f)
  if (!identical(x$station_number, cal$station_number)) stop(v, " was scored on other stations")
  if (!identical(x$code_md5, score_code_md5)) stop(v, " was scored by other code: rerun scripts/wb_validate.R ", v)
  x
})
names(res) <- variants_all

# ---- the rule -------------------------------------------------------------------------------------
margin_hw <- 2.0     # (a) headwater MAE at least this many points below cgiar
slack_nes_mae <- 1.0 # (c) nested MAE at most this many points above cgiar
slack_nes_in20 <- 3  # (c) nested within +/-20 % at most this many points below cgiar
# m: one row per variant with hw, all, nes_mae, nes_in20 (%), cgiar among them
decide <- function(m) {
  cg <- m[m$aet == "cgiar", ]
  ok <- m$aet %in% eligible &
    m$hw <= cg$hw - margin_hw & m$all <= cg$all &
    m$nes_mae <= cg$nes_mae + slack_nes_mae & m$nes_in20 >= cg$nes_in20 - slack_nes_in20
  if (!any(ok)) return("cgiar")
  cand <- m[ok, ]
  cand$aet[which.min(cand$hw)]
}
# as wet_flow_validate() computes them: stations observing under 10 mm a year
# (its min_obs) are left out
metrics <- function(obs, mod, nesting) {
  keep <- !is.na(obs) & obs >= 10
  obs <- obs[keep]
  mod <- mod[keep]
  nesting <- nesting[keep]
  e <- 100 * (mod - obs) / obs
  hw <- nesting == "headwater"
  c(hw = mean(abs(e[hw])), all = mean(abs(e)), nes_mae = mean(abs(e[!hw])),
    nes_in20 = 100 * mean(abs(e[!hw]) <= 20))
}

# ---- (a)-(c): each variant as shipped, from its own run --------------------------------------------
shipped <- function(x) if (x$keep_adjust) x$cv_ann else pmax(x$raw, 0)
top <- do.call(rbind, lapply(variants_all, function(v) {
  x <- res[[v]]
  data.frame(aet = v, gate = x$keep_adjust, t(metrics(cal$obs, shipped(x), cal$nesting)),
             raw_hw = metrics(cal$obs, pmax(x$raw, 0), cal$nesting)[["hw"]],
             raw_all = metrics(cal$obs, pmax(x$raw, 0), cal$nesting)[["all"]])
}))
# the MAE here and wet_flow_validate()'s must be one number, or the rule reads
# a different metric from the reports
for (v in variants_all) {
  x <- res[[v]]
  sm <- (if (x$keep_adjust) x$cv_v else x$raw_v)$summary
  ref <- sm$mae_pct[sm$group == "nesting" & sm$value == "headwater"]
  if (abs(ref - top$hw[top$aet == v]) > 1e-9) stop(v, ": headwater MAE ", top$hw[top$aet == v], " != report ", ref)
}
winner_top <- decide(top)
stamp("top-level rule: ", winner_top)

# ---- (d): fully nested selection -------------------------------------------------------------------
# Inside each outer fold the training stations score every variant as shipped
# under an inner blocked CV (their own WSC folds). To bound the cost the pooled
# variant is chosen once per training set, not again inside each inner fold.
as_shipped_cv <- function(d, fold) {
  pv <- choose_variant(d)
  adj <- cv_annual(d, fold, pv)
  raw <- pmax(d$raw, 0)
  keep <- metrics(d$obs, adj, d$nesting)[["hw"]] < metrics(d$obs, raw, d$nesting)[["hw"]]
  list(pred = if (keep) adj else raw, keep = keep, pv = pv)
}
cands <- c("cgiar", eligible)
nested_pred <- rep(NA_real_, nrow(cal))
chosen <- character()
for (f in unique(cal$fold)) {
  tr <- cal$fold != f
  m <- do.call(rbind, lapply(cands, function(v) {
    d <- cal[tr, ]
    d$raw <- res[[v]]$raw[tr]
    s <- as_shipped_cv(d, d$fold)
    data.frame(aet = v, t(metrics(d$obs, s$pred, d$nesting)), keep = s$keep, pv = s$pv)
  }))
  v <- decide(m)
  chosen <- c(chosen, v)
  d <- cal
  d$raw <- res[[v]]$raw
  if (m$keep[m$aet == v]) {
    fit <- wet_wb_fit(d[tr, ], pooled_adjust = m$pv[m$aet == v])
    nested_pred[!tr] <- wet_wb_adjust(fit, d[!tr, ])
  } else {
    nested_pred[!tr] <- pmax(d$raw[!tr], 0)
  }
}
nested <- metrics(cal$obs, nested_pred, cal$nesting)
cg <- top[top$aet == "cgiar", ]
pass_d <- nested[["hw"]] < cg$hw
winner <- if (winner_top != "cgiar" && pass_d) winner_top else "cgiar"
stamp("nested selection headwater MAE ", round(nested[["hw"]], 1), "; winner ", winner)

# ---- per-variant detail ----------------------------------------------------------------------------
zone_mean <- function(x, z) {
  e <- 100 * (shipped(x) - cal$obs) / cal$obs
  mean(e[cal$zone == z])
}
small_mae <- function(x) {
  e <- 100 * (shipped(x) - cal$obs) / cal$obs
  mean(abs(e[cal$area_km2 < 100]))
}
g <- cal$station_number == "08NM173"
detail <- do.call(rbind, lapply(variants_all, function(v) {
  x <- res[[v]]
  col <- wet:::wet_wb_aet_cols()[[v]]
  data.frame(aet = v, z15 = zone_mean(x, "15"), z17 = zone_mean(x, "17"), z23 = zone_mean(x, "23"),
             z24 = zone_mean(x, "24"), small = small_mae(x),
             greata_aet = cal[[col]][g], greata_raw = x$raw[g], greata_mod = shipped(x)[g])
}))

# ---- report ---------------------------------------------------------------------------------------
fmt_top <- sprintf("%-6s %-10s %6.1f %6.1f %6.1f %7.1f %8.1f %8.1f %s", top$aet,
                   ifelse(top$gate, "adjusted", "raw"), top$hw, top$all, top$nes_mae, top$nes_in20,
                   top$raw_hw, top$raw_all, ifelse(top$aet %in% transparency, "(transparency)", ""))
fmt_det <- sprintf("%-6s %7.1f %7.1f %7.1f %7.1f %8.1f   %6.0f %6.0f %6.0f", detail$aet, detail$z15, detail$z17,
                   detail$z23, detail$z24, detail$small, detail$greata_aet, detail$greata_raw, detail$greata_mod)
tab <- table(factor(chosen, levels = cands))
con <- file("data/checks/wb_aet_compare.txt", "w")
writeLines(c(
  "# ET experiment (#15): annual AET variants scored as shipped under blocked CV", "",
  sprintf("province run: %s; stations: %d (headwater %d, nested %d); folds: %d", basename(key_dir),
          nrow(cal), sum(cal$nesting == "headwater"), sum(cal$nesting != "headwater"), length(unique(cal$fold))),
  paste("Variants: cgiar (CGIAR SWB v3), lc (CGIAR x Chapman Table 3 land-cover ratio, NRCan 2020),",
        "tc (TerraClimate 1981-2010), fu (Fu-Budyko, climr P and Hargreaves PET, omega 2.6),",
        "cfu (max of CGIAR and fu); fu15/fu20/fu35 are fu at omega 1.5/2.0/3.5, transparency only."),
  "Monthly shares use CGIAR monthly AET for every variant; differences here are annual only.",
  "",
  "Rule (fixed before scoring): a variant replaces cgiar only if, under blocked CV and as shipped,",
  sprintf(paste("(a) headwater MAE is at least %.1f points below cgiar, (b) all-station MAE is no higher,",
                "(c) nested MAE is at most %.1f points higher and nested within +/-20 %% at most %d points lower,",
                "and (d) a fully nested selection beats cgiar's headwater MAE."),
          margin_hw, slack_nes_mae, slack_nes_in20),
  "",
  "## As shipped (adjusted if it passes the headwater gate, raw otherwise), blocked CV, MAE %",
  sprintf("%-6s %-10s %6s %6s %6s %7s %8s %8s", "aet", "shipped", "head", "all", "nested", "nes_in20",
          "raw_head", "raw_all"),
  fmt_top, "",
  sprintf("(a)-(c) choose: %s", winner_top),
  sprintf(paste("(d) nested selection (outer: %d WSC folds; inner: blocked CV on each fold's training stations,",
                "pooled variant chosen once per training set): headwater %.1f, all %.1f, nested %.1f,",
                "nested in +/-20 %% %.1f; cgiar as shipped: headwater %.1f -> %s"),
          length(unique(cal$fold)), nested[["hw"]], nested[["all"]], nested[["nes_mae"]], nested[["nes_in20"]],
          cg$hw, if (pass_d) "pass" else "fail"),
  sprintf("    variant chosen by the outer folds: %s", paste(sprintf("%s %d", names(tab), tab), collapse = ", ")),
  "", sprintf("WINNER: %s", winner), "",
  "## Detail, as shipped: mean error % in the semi-arid zones, MAE % for basins < 100 km2,",
  "## and Greata Creek 08NM173 (upstream AET, raw P - AET, shipped; observed below)",
  sprintf("%-6s %7s %7s %7s %7s %8s   %6s %6s %6s", "aet", "z15", "z17", "z23", "z24", "<100km2",
          "G_aet", "G_raw", "G_mod"),
  fmt_det,
  sprintf("Greata Creek: upstream P %.0f mm, observed %.0f mm", cal$p_yr[g], cal$obs[g])
), con)
close(con)
writeLines(c(winner, score_code_md5), file.path(key_dir, "aet_winner.txt"))
stamp("report written; winner ", winner)
