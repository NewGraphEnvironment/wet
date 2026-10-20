# Compare the annual AET variants of the ET experiments and apply the decision
# rules fixed in planning before any variant was scored: #15 (stage 1: cgiar,
# lc, tc, fu and cfu) and #18 (stage 2: stage 1's winner against the MOD16
# variants mod16 and cmod16). Stage 1's incumbent is cfu, the shipped AET, with
# cgiar, lc, tc and fu its challengers (#89, registered 2026-10-16 before any
# release after 2026-07-17 was scored), so a later release cannot switch on a
# near-tie; #15's own run had cgiar as the incumbent (tag aet-15-record).
#
#   for v in cgiar lc tc fu cfu fu15 fu20 fu35 mod16 cmod16; do Rscript scripts/wb_validate.R $v; done
#   Rscript scripts/wb_aet_compare.R
#   Rscript scripts/wb_validate.R <winner>   # writes fits.rds and wb_validation.txt
#
# Reads <fit>/cv_aet-<v>.rds (scripts/wb_validate.R) and writes the tracked
# report wb_report("wb_aet_compare", release) and the winner to
# <fit>/aet_winner.txt (scripts/wb_fit_lib.R), which scripts/wb_validate.R ships (run it
# again for the winner to write fits.rds). Each stage also runs a fully nested
# selection: each outer blocked fold picks the AET variant (and whether to
# adjust) by the same rule applied to an inner blocked CV on its training
# stations, so the winner's error is estimated without having been selected on
# the stations it is scored on.
#
# It runs on the fit's own release (#81): the shipped fit re-decides its AET at
# each new release, under the rules as #15 and #18 fixed them, with stage 1's
# incumbent from #89. Each variant is scored as the fit ships it, under the
# fit's own decisions (a fixed pooled variant, a gate override;
# scripts/wb_cv_lib.R), and the nested selection
# applies the same decisions inside each fold. #15's own run, on HYDAT
# 2025-10-14, is reproduced at tag aet-15-record, not here.

source("scripts/wb_cv_lib.R")
# a winner is only ever the result of a complete comparison under this code;
# the old one goes first, so no early stop below leaves it in place
unlink(file.path(fit_dir, "aet_winner.txt"))
missing_cv <- setdiff(c("cgiar", "lc", "tc", "fu", "cfu", "fu15", "fu20", "fu35", "mod16", "cmod16"),
                      sub("^cv_aet-(.*)\\.rds$", "\\1", list.files(fit_dir, "^cv_aet-.*\\.rds$")))
if (length(missing_cv)) stop("run scripts/wb_validate.R first for: ", paste(missing_cv, collapse = " "))
incumbent1 <- "cfu"                              # stage 1's incumbent (#89; cgiar in #15)
eligible <- c("cgiar", "lc", "tc", "fu")         # stage 1's challengers
transparency <- c("fu15", "fu20", "fu35")
eligible2 <- c("mod16", "cmod16")                 # stage 2 (#18)
# in #15's order, so the report's rows and which.min ties among challengers are as before
variants_all <- c("cgiar", "lc", "tc", "fu", "cfu", transparency, eligible2)
res <- lapply(variants_all, function(v) {
  f <- file.path(fit_dir, sprintf("cv_aet-%s.rds", v))
  if (!file.exists(f)) stop("no ", f, ": run scripts/wb_validate.R ", v)
  x <- readRDS(f)
  if (!identical(x$station_number, cal$station_number)) stop(v, " was scored on other stations")
  if (!identical(x$code_md5, score_code_md5)) stop(v, " was scored by other code: rerun scripts/wb_validate.R ", v)
  x
})
names(res) <- variants_all

# ---- the rule -------------------------------------------------------------------------------------
margin_hw <- 2.0     # (a) headwater MAE at least this many points below the incumbent
slack_nes_mae <- 1.0 # (c) nested MAE at most this many points above the incumbent
slack_nes_in20 <- 3  # (c) nested within +/-20 % at most this many points below the incumbent
# m: one row per variant with hw, all, nes_mae, nes_in20 (%), the incumbent
# among them. The same thresholds serve both stages; only the incumbent and
# the eligible challengers differ.
decide <- function(m, incumbent, elig) {
  im <- m[m$aet == incumbent, ]
  ok <- m$aet %in% elig &
    m$hw <= im$hw - margin_hw & m$all <= im$all &
    m$nes_mae <= im$nes_mae + slack_nes_mae & m$nes_in20 >= im$nes_in20 - slack_nes_in20
  if (!any(ok)) return(incumbent)
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
  data.frame(aet = v, gate = x$keep_adjust, gate_pass = x$gate_pass, t(metrics(cal$obs, shipped(x), cal$nesting)),
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
winner_top <- decide(top, incumbent1, eligible)
stamp("stage 1 top-level rule: ", winner_top)

# ---- (d): fully nested selection -------------------------------------------------------------------
# Inside each outer fold the training stations score every variant as shipped
# under an inner blocked CV (their own WSC folds). To bound the cost the pooled
# variant is chosen once per training set, not again inside each inner fold;
# a fit that fixes it uses its own throughout. The adjustment is kept as
# scripts/wb_validate.R keeps it (keep_adjust_for(): the gate, or the fit's
# recorded override).
# Each fold's scores are worked out once, over every candidate of both stages,
# and each selection below applies its own rule to them.
as_shipped_cv <- function(d, fold) {
  pv <- if (is.na(fixed_variant)) choose_variant(d) else fixed_variant
  adj <- cv_annual(d, fold, pv)
  raw <- pmax(d$raw, 0)
  keep <- keep_adjust_for(metrics(d$obs, adj, d$nesting)[["hw"]], metrics(d$obs, raw, d$nesting)[["hw"]])
  list(pred = if (keep) adj else raw, keep = keep, pv = pv)
}
cands <- variants_all[variants_all %in% c(incumbent1, eligible)]  # stage 1, in #15's order
cands_all <- c(cands, eligible2)
fold_m <- list()
for (f in unique(cal$fold)) {
  tr <- cal$fold != f
  fold_m[[as.character(f)]] <- do.call(rbind, lapply(cands_all, function(v) {
    d <- cal[tr, ]
    d$raw <- res[[v]]$raw[tr]
    s <- as_shipped_cv(d, d$fold)
    data.frame(aet = v, t(metrics(d$obs, s$pred, d$nesting)), keep = s$keep, pv = s$pv)
  }))
}
# held-out predictions of a selection: pick(m) names each fold's variant
nested_select <- function(pick) {
  pred <- rep(NA_real_, nrow(cal))
  chosen <- character()
  for (f in unique(cal$fold)) {
    tr <- cal$fold != f
    m <- fold_m[[as.character(f)]]
    v <- pick(m)
    chosen <- c(chosen, v)
    d <- cal
    d$raw <- res[[v]]$raw
    if (m$keep[m$aet == v]) {
      fit <- wet_wb_fit(d[tr, ], pooled_adjust = m$pv[m$aet == v])
      pred[!tr] <- wet_wb_adjust(fit, d[!tr, ])
    } else {
      pred[!tr] <- pmax(d$raw[!tr], 0)
    }
  }
  list(metrics = metrics(cal$obs, pred, cal$nesting), chosen = chosen)
}
ns1 <- nested_select(function(m) decide(m[m$aet %in% cands, ], incumbent1, eligible))
nested <- ns1$metrics
chosen <- ns1$chosen
inc1_row <- top[top$aet == incumbent1, ]
pass_d <- nested[["hw"]] < inc1_row$hw
winner1 <- if (winner_top != incumbent1 && pass_d) winner_top else incumbent1
stamp("stage 1 nested selection headwater MAE ", round(nested[["hw"]], 1), "; winner ", winner1)

tab1 <- table(factor(chosen, levels = cands))

# ---- stage 2 (#18): stage 1's winner against mod16 and cmod16 -------------------------------------
# MOD16's gaps are filled with cfu whatever stage 1 chose (scripts/wb_province.R);
# the report discloses it
inc <- winner1
winner_top2 <- decide(top, inc, eligible2)
ns2 <- nested_select(function(m) decide(m[m$aet %in% c(inc, eligible2), ], inc, eligible2))
inc_row <- top[top$aet == inc, ]
pass_d2 <- ns2$metrics[["hw"]] < inc_row$hw
winner <- if (winner_top2 != inc && pass_d2) winner_top2 else inc
# What ships (#81). Without a recorded decision, the rule's winner ships only
# if it is #15's cfu: any other winner goes to the user, and no winner file is
# written, so no later run of scripts/wb_validate.R can ship it on its own
# authority. With one (<fit>/aet_decision.txt, scripts/wb_cv_lib.R; hashed into
# score_code_md5, so this run is stamped with it), the user's AET ships, whatever
# the rule picks; the report shows both. The decision is read from that file,
# never from fits.rds, which scripts/wb_validate.R rewrites. Deleting it returns
# the fit to #15's default. Either way, an AET that would ship raw under a fixed
# pooled variant (which scripts/wb_validate.R refuses, #43) goes to the user.
# #18's stage 2 was registered with cfu as the incumbent, and MOD16's gaps are
# cfu, so a stage 1 other than cfu is reported as outside that registration.
ship <- if (is.null(aet_decision)) winner else aet_decision[1]
ship_raw <- !is.na(fixed_variant) && !res[[ship]]$keep_adjust
to_user <- (is.null(aet_decision) && winner != "cfu") || ship_raw
stamp("stage 2 top-level rule: ", winner_top2, "; nested headwater MAE ", round(ns2$metrics[["hw"]], 1),
      "; winner ", winner)
# transparency: the incumbent alone under the same nested procedure. Its inner
# gate varies by fold, so this is not its as-shipped score, and (d) (against
# the as-shipped score, as #15's rule was) is the stricter of the two bars.
ns_inc <- nested_select(function(m) inc)
# transparency: both stages inside each fold, stage 2 against that fold's own stage-1 winner
ns12 <- nested_select(function(m) {
  v1 <- decide(m[m$aet %in% cands, ], incumbent1, eligible)
  decide(m[m$aet %in% c(v1, eligible2), ], v1, eligible2)
})

# transparency: how much of each basin MOD16 actually covers (the rest is cfu)
fr16 <- cal$frac_mod16
hi16 <- fr16 >= 0.8 & cal$nesting == "headwater"
hi16_mae <- vapply(c(inc, eligible2), function(v) {
  e <- 100 * (shipped(res[[v]]) - cal$obs) / cal$obs
  mean(abs(e[hi16 & cal$obs >= 10]))
}, numeric(1))
m16_fill <- readLines(file.path(key_dir, "ex_filled_cells.txt"))
m16_fill <- m16_fill[grepl("^aet_mod16 ", m16_fill)]

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
                   ifelse(top$gate, ifelse(top$gate_pass, "adjusted", "adjusted*"), "raw"), top$hw, top$all, top$nes_mae, top$nes_in20,
                   top$raw_hw, top$raw_all,
                   ifelse(top$aet %in% transparency, "(transparency)", ifelse(top$aet %in% eligible2, "(stage 2)", "")))
fmt_det <- sprintf("%-6s %7.1f %7.1f %7.1f %7.1f %8.1f   %6.0f %6.0f %6.0f", detail$aet, detail$z15, detail$z17,
                   detail$z23, detail$z24, detail$small, detail$greata_aet, detail$greata_raw, detail$greata_mod)
tab <- tab1
tab2 <- table(factor(ns2$chosen, levels = c(inc, eligible2)))
tab12 <- table(factor(ns12$chosen, levels = cands_all))
fmt_ns <- function(x) {
  sprintf("headwater %.1f, all %.1f, nested %.1f, nested in +/-20 %% %.1f",
          x[["hw"]], x[["all"]], x[["nes_mae"]], x[["nes_in20"]])
}
con <- file(wb_report("wb_aet_compare", release), "w")
writeLines(c(
  "# ET experiments (#15, #18): annual AET variants scored as shipped under blocked CV", "",
  sprintf("province run: %s; stations: %d (headwater %d, nested %d); folds: %d", basename(key_dir),
          nrow(cal), sum(cal$nesting == "headwater"), sum(cal$nesting != "headwater"), length(unique(cal$fold))),
  sprintf("HYDAT release: %s; pooled zones: %s; headwater gate: %s", release,
          if (is.na(fixed_variant)) "chosen inside each fold" else sprintf("fixed to '%s' (%s)", fixed_variant,
                                                                           basename(f_pooled)),
          if (is.na(tie_tol)) "strict" else sprintf("kept within %.2f point (%s)", tie_tol, basename(f_override))),
  paste("Variants: cgiar (CGIAR SWB v3), lc (CGIAR x Chapman Table 3 land-cover ratio, NRCan 2020),",
        "tc (TerraClimate 1981-2010), fu (Fu-Budyko, climr P and Hargreaves PET, omega 2.6),",
        "cfu (max of CGIAR and fu); fu15/fu20/fu35 are fu at omega 1.5/2.0/3.5, transparency only;",
        "mod16 (MOD16A3GF v061, mean 2001-2020, gaps filled with cfu by area), cmod16 (max of CGIAR and mod16)."),
  "The monthly shares are the same for every variant (scripts/wb_validate.R); differences here are annual only.",
  "",
  sprintf("## Stage 1 (#15; incumbent since #89): %s against %s", incumbent1, paste(eligible, collapse = ", ")), "",
  sprintf("Rule (#15's thresholds; incumbent set by #89 on 2026-10-16): a variant replaces %s only if, under blocked CV and as shipped,",
          incumbent1),
  sprintf(paste("(a) headwater MAE is at least %.1f points below %s, (b) all-station MAE is no higher,",
                "(c) nested MAE is at most %.1f points higher and nested within +/-20 %% at most %d points lower,",
                "and (d) a fully nested selection beats %s's headwater MAE."),
          margin_hw, incumbent1, slack_nes_mae, slack_nes_in20, incumbent1),
  paste("Disclosed: #15 ran this stage with cgiar as the incumbent (tag aet-15-record). The incumbent is",
        incumbent1, "since #89, chosen after cfu and fu were seen to be close, so a near-tie keeps the shipped",
        "AET; the incumbent's score is itself post-selection (the fit's decision files were made on its fit),",
        "so (d) in particular leans toward keeping it."),
  "",
  "## As shipped (adjusted if it passes the headwater gate, raw otherwise), blocked CV, MAE %",
  sprintf("%-6s %-10s %6s %6s %6s %7s %8s %8s", "aet", "shipped", "head", "all", "nested", "nes_in20",
          "raw_head", "raw_all"),
  fmt_top,
  if (any(top$gate & !top$gate_pass)) {
    sprintf(paste("adjusted*: the gate failed and the override kept the adjustment (within %.2f point). The",
                  "tolerance was recorded for the AET shipped when it was set; it applies here to every variant",
                  "and every fold, as does the fixed pooled variant, which leans toward that AET."), tie_tol)
  },
  "",
  sprintf("(a)-(c) choose: %s", winner_top),
  sprintf(paste("(d) nested selection (outer: %d WSC folds; inner: blocked CV on each fold's training stations,",
                "pooled variant %s): headwater %.1f, all %.1f, nested %.1f,",
                "nested in +/-20 %% %.1f; %s as shipped: headwater %.1f -> %s"),
          length(unique(cal$fold)),
          if (is.na(fixed_variant)) "chosen once per training set" else sprintf("fixed to '%s'", fixed_variant),
          nested[["hw"]], nested[["all"]], nested[["nes_mae"]], nested[["nes_in20"]],
          incumbent1, inc1_row$hw, if (pass_d) "pass" else "fail"),
  sprintf("    variant chosen by the outer folds: %s", paste(sprintf("%s %d", names(tab), tab), collapse = ", ")),
  sprintf("Stage 1 winner: %s", winner1),
  if (winner1 != "cfu") {
    paste("Stage 1 did not choose cfu: stage 2 below is not the comparison #18 registered (cfu the",
          "incumbent), and MOD16's gaps are still cfu.")
  },
  "",
  sprintf("## Stage 2 (#18): %s against mod16 and cmod16", inc), "",
  paste("Rule (fixed before scoring): the same (a)-(c) thresholds with", inc, "as the incumbent, and (d) a fully",
        "nested selection among", paste(c(inc, eligible2), collapse = ", "), "beating the as-shipped headwater MAE",
        "of", paste0(inc, " on this run.")),
  paste("Disclosed: MOD16 is 2001-2020; climr P and T (so fu) and TerraClimate are 1981-2010; CGIAR AET (so",
        "cgiar and the CGIAR half of cfu and cmod16) is a WorldClim-based climatology (WorldClim 2.1, about",
        "1970-2000; research/water_balance_method.md section 7 item 3); MOD16's gaps (codes 65529-65535: unclassified,",
        "urban, permanent wetland, snow/ice, barren, water, fill) take cfu, which dilutes a challenger's margin;",
        "the incumbent's score is itself post-selection, so the comparison leans toward keeping it."),
  paste("MOD16 cover, cells on the analysis grid (mod16_whole: all MOD16; cfu_whole: no MOD16, all cfu;",
        "cfu_part: both):", paste(sub("^aet_mod16 ", "", m16_fill), collapse = "; ")),
  "",
  sprintf("(a)-(c) choose: %s", winner_top2),
  sprintf("(d) nested selection: %s; %s as shipped: headwater %.1f -> %s", fmt_ns(ns2$metrics), inc, inc_row$hw,
          if (pass_d2) "pass" else "fail"),
  sprintf("    variant chosen by the outer folds: %s", paste(sprintf("%s %d", names(tab2), tab2), collapse = ", ")),
  "", sprintf("WINNER: %s", winner),
  if (to_user) {
    sprintf("DECISION TO USER: %s; no aet_winner.txt is written, so nothing ships (#81)",
            if (ship_raw) sprintf("%s ships raw P - AET under the fixed pooled variant '%s'", ship, fixed_variant)
            else "the rule did not choose cfu (#15's), and no aet_decision.txt records the user's choice")
  } else if (is.null(aet_decision)) {
    "SHIPS: cfu, the rule's winner and #15's AET; scripts/wb_validate.R ships it"
  } else {
    sprintf("SHIPS: %s, the user's decision in %s (%s); the rule chose %s; scripts/wb_validate.R ships it", ship,
            basename(f_aet_decision), paste(aet_decision[-1], collapse = " "), winner)
  },
  "",
  "## Transparency (never deciding)",
  sprintf("%s alone under the same nested procedure (inner gate per fold): %s", inc, fmt_ns(ns_inc$metrics)),
  sprintf("Two-stage nested selection (stage 1 then stage 2 inside each fold): %s", fmt_ns(ns12$metrics)),
  sprintf("    variant chosen by the outer folds: %s", paste(sprintf("%s %d", names(tab12), tab12), collapse = ", ")),
  sprintf("Upstream MOD16 share of the %d stations: min %.2f, quartiles %s, max %.2f", nrow(cal), min(fr16),
          paste(sprintf("%.2f", stats::quantile(fr16, c(0.25, 0.5, 0.75))), collapse = " / "), max(fr16)),
  sprintf("Headwater MAE, stations whose basin is >= 80 %% MOD16 (n = %d): %s", sum(hi16 & cal$obs >= 10),
          paste(sprintf("%s %.1f", names(hi16_mae), hi16_mae), collapse = ", ")),
  "",
  "## Detail, as shipped: mean error % in the semi-arid zones, MAE % for basins < 100 km2,",
  "## and Greata Creek 08NM173 (upstream AET, raw P - AET, shipped; observed below)",
  sprintf("%-6s %7s %7s %7s %7s %8s   %6s %6s %6s", "aet", "z15", "z17", "z23", "z24", "<100km2",
          "G_aet", "G_raw", "G_mod"),
  fmt_det,
  sprintf("Greata Creek: upstream P %.0f mm, observed %.0f mm", cal$p_yr[g], cal$obs[g])
), con)
close(con)
if (to_user) {
  stamp("report written; winner ", winner, ": DECISION TO USER, no winner file written")
} else {
  writeLines(c(ship, score_code_md5), file.path(fit_dir, "aet_winner.txt"))
  stamp("report written; winner ", winner, "; ships ", ship)
}
