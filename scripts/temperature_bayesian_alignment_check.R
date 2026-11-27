# The Bayesian alignment check of the water-temperature fill and baseline (#218)
# ---------------------------------------------------------------------------
# Does research/temperature_bayesian_alignment.md quote its two books truly, give every modelling choice of the
# water-temperature fill and the whole-station baseline one verdict at the line that makes it, and state only the
# figures it can trace? (#218). Run with MD=research/temperature_network_model.md for #217's file: its quotes, if
# any, and its figures only.
#
# The quote half is copied from NewGraphEnvironment/knowledge's data-raw/bayesian_alignment_check.R at f0a6cbd0
# (no shared helper exists; a page-anchored quote check is offered to cred). Its rules, unchanged:
# QUOTES. A quoted passage is checked when it is written
#   "<passage>" (<citekey>, p. N)       or  (<citekey>, pp. N-M) for one that runs onto the next page
# inline in a sentence (it may wrap across lines), and is looked for on printed page N (to M) of that book's PDF,
# the group library's own attachment. A printed page is the PDF page less the book's front matter (`offset`), and
# the page's running head or foot must carry N, so a wrong offset fails rather than reading a neighbouring page.
# Passage and page are compared as token sequences: ligatures spelled out, words and numbers as written, symbols
# dropped, a line-end hyphen joined in one reading and kept in the other. An ellipsis splits a passage into
# fragments that must appear in order, each of at least `frag_min` tokens. Then every checked passage is blanked
# and every page citation in the file enumerated: a quote mark left within `near` characters of one fails, so a
# quote with no checked form of its own fails. The number of checked quotes must be `n_quotes`.
#
# CHOICES (the research file only). The table under "## Choices" has a row per id of `choices` below: first cell
# the id in backticks, second `file:line`, which must name the anchor's file and the line it stands on (the anchor
# must occur once in that file), last cell exactly one of `verdicts`. A missing, duplicate or stale row fails, and
# so does a choice whose code moved: rerun this check after any change to the scope's files and update the rows.
# COVERAGE. Every formal with a default of wet_temp_fill() and wet_temp_gsdd(), and every top-level assignment of a
# numeric constant in `scope`, must be named in `registry` with the choice that covers it; a registry entry naming
# nothing found, or a choice that is not in `choices`, fails.
# FIGURES (both files). Each entry of `figures` must appear in the file as written, and its `literal` must occur
# once in its `source`, a tracked report or the research file that states it. Outside code, citations and checked
# quotes, every number written with a unit (°C-days, °C, %, degC) must be part of some entry's text.
#
# INPUT:  the research file (or MD=); the scope's code; the two PDFs under ZOTERO_DIR/storage (default ~/Zotero),
#         by the attachment keys below (the group library's, as knowledge's review reads them)
# OUTPUT: data/checks/temperature_bayesian_alignment_<yyyymmdd>.txt for the research file with no MD set and the
#         quotes checked; none for any MD= or without the books. Exits 1 on any failure.
# RUN:    Rscript scripts/temperature_bayesian_alignment_check.R   (from the repo root; needs pdftotext for the
#         quotes; without it or the PDFs the rest runs and it prints QUOTES NOT CHECKED)
# ---------------------------------------------------------------------------
options(warn = 1)

books <- list(
  mcelreath2020StatisticalRethinking = list(
    file = "PVGNFJC9/McElreath - 2020 - Statistical Rethinking - A Bayesian Course with Ex.pdf", offset = 16L),
  gelman_etal2013Bayesiandata = list(file = "JP3BM8T9/BDA3.pdf", offset = 10L)
)
verdicts <- c("aligned", "differs", "differs by design", "outside the books")
frag_min <- 4L
near <- 200L      # characters either side of a page citation in which a quote mark makes the page a quote's
# the quotes each file checks; change a count with its file
n_quotes <- c(temperature_bayesian_alignment.md = 20L, temperature_network_model.md = 0L)
review <- "research/temperature_bayesian_alignment.md"

# each modelling choice, with a line of the code (or of its documentation) that makes it
choices <- list(
  each_station_alone   = c("R/wet_temp_fill.R", "open <- lapply(fit_st, function(s) wet_a2s_fit(series[[s]]$y, series[[s]]$a))"),
  open_loop_lsq        = c("R/wet_temp_fill.R", "v <- mean((s[i] - y[i])^2)"),
  two_starts           = c("R/wet_temp_fill.R", "for (a3 in c(0.05, 0.15)) {"),
  ice_floor            = c("R/wet_temp_fill.R", "s[t] <- if (v > 0) v else 0"),
  air_exact            = c("R/wet_temp_fill.R", "a <- stats::approx(as.numeric(as_$date), as_$value, xout = as.numeric(date), rule = 1)$y"),
  air_gap              = c("R/wet_temp_fill.R", "wet_air_gap <- 3"),
  air_day_offset       = c("R/wet_temp_fill.R", "#' Kootenays) the two are an hour apart. That is not corrected. Gaps of up to"),
  min_days             = c("R/wet_temp_fill.R", "short <- setdiff(stations[n_obs < min_days], air_gap)"),
  fill_range           = c("R/wet_temp_fill.R", "list(date = date, a = a, y = y, fill = date >= f_lo & date <= f_hi)"),
  pool_by_hand         = c("R/wet_temp_fill.R", "group <- if (is.null(pool)) stats::setNames(rep(\"all\", length(stations)), stations) else pool[stations]"),
  ar1_kalman           = c("R/wet_temp_fill.R", "mt <- rho * m + u[t]"),
  stationary_start     = c("R/wet_temp_fill.R", "p <- q / (1 - rho^2)"),
  obs_sd_fixed         = c("R/wet_temp_fill.R", "sv <- pt + r2"),
  gaussian_error       = c("R/wet_temp_fill.R", "ll <- ll - 0.5 * (log(2 * pi * sv) + v * v / sv)"),
  departure_ml         = c("R/wet_temp_fill.R", "o <- stats::optim(th, nll, method = \"BFGS\", control = list(maxit = 500))"),
  departure_caps       = c("R/wet_temp_fill.R", "rho <- min(par[[\"rho\"]], 0.999)"),
  peers_first_fit      = c("R/wet_temp_fill.R", "first <- lapply(dep, function(r) wet_kf_fit(r, NULL, r2))"),
  peer_clip            = c("R/wet_temp_fill.R", "lim <- 4 * first[[k]]$par[[\"sigma\"]]"),
  peer_mean            = c("R/wet_temp_fill.R", "ebar <- ifelse(cnt > 0, rowSums(m, na.rm = TRUE) / pmax(cnt, 1), 0)"),
  peer_threshold       = c("R/wet_temp_fill.R", "if (sum(cnt > 0 & !is.na(z$y)) < 180) ebar <- NULL"),
  plugin_interval      = c("R/wet_temp_fill.R", "half <- stats::qnorm(1 - (1 - level) / 2) * sqrt(st$var)"),
  interval_floor       = c("R/wet_temp_fill.R", "data.frame(date = st$date, t_mean_c = pmax(est, 0), t_lo_c = pmax(est - half, 0),"),
  observed_untouched   = c("R/wet_temp_fill.R", "ts$t_lo_c <- ts$t_mean_c"),
  gsdd_season          = c("R/wet_temp_gsdd.R", "g <- gsdd::gsdd(data.frame(date = date, temperature = s[[value]][k]),"),
  gsdd_daily_mean      = c("R/wet_temp_gsdd.R", "wet_temp_gsdd <- function(x, value = \"t_mean_c\", by = \"station_number\","),
  gsdd_no_interval     = c("R/wet_temp_gsdd.R", "#'   [wet_temp_fill()] result does not carry into GSDD: daily bounds do not add"),
  fill_holdout         = c("scripts/temp_fill_validate.R", "shapes <- list(season = list(c(\"03-01\", \"11-30\")),"),
  fill_rule            = c("scripts/temp_fill_validate.R", "pass <- season[[\"median_diff\"]] < 0 && season[[\"share_full_better\"]] >= 0.6 &&"),
  truth_complete       = c("scripts/temp_fill_validate.R", "if (any(!rl$values & rl$lengths > 2)) return(NULL)"),
  gsdd_year_interp     = c("scripts/temp_fill_validate.R", "if (anyNA(v)) v <- stats::approx(as.numeric(d)[!is.na(v)], v[!is.na(v)], as.numeric(d))$y"),
  truth_stuck          = c("scripts/temp_baseline_traits.R", "stuck_sd <- 0.1"),
  kept_stations        = c("scripts/temp_baseline_traits.R", "min_frac <- 0.95  # basin share inside BC and on the grids, as scripts/wb_cv_lib.R"),
  trait_set            = c("scripts/temp_baseline_lib.R", "tb_traits <- c(\"elev\", \"e_km\", \"n_km\", \"snowmelt_doy_50\", \"swe_max\", \"log_area\", \"glacier\", \"lake_cover\")"),
  theta_transform      = c("scripts/temp_baseline_lib.R", "out <- cbind(eq0 = par[, \"a1\"] / a3, eq1 = par[, \"a2\"] / a3, rate = stats::qlogis(a3))"),
  cand_mean            = c("scripts/temp_baseline_lib.R", "s[] <- rep(apply(th, 2, stats::sd) * sqrt(1 + 1 / n), each = nrow(x_new))"),
  cand_regression      = c("scripts/temp_baseline_lib.R", "beta <- xtx_inv %*% crossprod(xd, th)"),
  regression_interval  = c("scripts/temp_baseline_lib.R", "s[] <- outer(sqrt(1 + lev), res_sd)"),
  cand_donor           = c("scripts/temp_baseline_lib.R", "w <- wet:::wet_donor_mean(zn, z, diag(n), k)   # weights over the training rows, summing to 1"),
  donor_weights        = c("R/wet_donor_mean.R", "wt <- if (any(zero)) as.numeric(zero) else 1 / (dd + 1e-6 * stats::median(dist))"),
  donor_k              = c("scripts/temp_baseline_lib.R", "tb_k <- 5        # donors, as the monthly shares' donor"),
  donor_interval       = c("scripts/temp_baseline_lib.R", "s[] <- sqrt(pmax(v, 0) * k / (k - 1) * (1 + rowSums(w^2)))"),
  zscore_training      = c("scripts/temp_baseline_lib.R", "z <- sweep(sweep(x, 2, mu), 2, sg, \"/\")"),
  no_spread_dropped    = c("scripts/temp_baseline_lib.R", "spread <- apply(x, 2, stats::sd) > 0"),
  t_interval           = c("scripts/temp_baseline_lib.R", "h <- stats::qt(1 - (1 - level) / 2, p$df) * p$sd"),
  interval_level       = c("scripts/temp_baseline_lib.R", "tb_level <- 0.9  # the interval scored for coverage"),
  folds_blocked        = c("R/wet_cv_folds.R", "fold <- if (block == \"station\") stations$station_number else substr(stations$station_number, 1, 4)"),
  pool_blocked         = c("scripts/temp_baseline_lib.R", "lapply(unique(fold), function(f) list(te = which(fold == f), tr = fold != f))"),
  pool_leakfree        = c("scripts/temp_baseline_lib.R", "lapply(seq_len(n), function(i) list(te = i, tr = fold != fold[i] & !related[i, ]))"),
  related_pairs        = c("scripts/wb_cv_lib.R", "up | t(up)"),
  open_loop_run        = c("scripts/temp_baseline.R", "cbind(station_number = st$station_number[i], run = w, tb_score(z, tb_run(z, p), years[[i]], gsdd_year),"),
  benchmark_own        = c("scripts/temp_baseline.R", "runs <- list(benchmark = th)"),
  theta_coverage       = c("scripts/temp_baseline.R", "cover = colMeans(th >= iv$lo & th <= iv$hi))"),
  statistic_station    = c("scripts/temp_baseline_lib.R", "by_station <- tapply(abs(d$gsdd - d$gsdd_obs), list(d$station_number, d$run), mean)[, runs, drop = FALSE]"),
  statistic_paired     = c("scripts/temp_baseline_lib.R", "ok <- tapply(!is.na(sc$gsdd) & !is.na(sc$gsdd_obs), key, all)"),
  rule_displace        = c("scripts/temp_baseline_rule.R", "tb_displace <- 10   # degC-days: a trait candidate replaces the population mean when at least this better"),
  rule_close           = c("scripts/temp_baseline_rule.R", "tb_close <- 50      # degC-days: the baseline is close when within this of the benchmark"),
  rule_tie             = c("scripts/temp_baseline_rule.R", "won[order(lf, match(won, tb_trait))][1]"),
  sim_known_values     = c("scripts/temp_baseline_recover.R", "share <- c(traits = 0.5, network = 0.25, noise = 0.25)  # of theta's variance"),
  sim_network_part     = c("scripts/temp_baseline_lib.R", "w <- up * pmin(outer(1 / area, area), 1)"),
  sim_independent      = c("scripts/temp_baseline_lib.R", "net <- vapply(seq_len(q), function(j) drop(wt %*% stats::rnorm(n)), numeric(n))"),
  sim_coverage         = c("scripts/temp_baseline_recover.R", "acc$cover[r, j] <- colMeans(sim$theta >= iv$lo & sim$theta <= iv$hi)"),
  sim_size             = c("scripts/temp_baseline_recover.R", "n_sim <- 1600"),
  leak_check           = c("scripts/temp_baseline_recover.R", "acc$leak[r, j] <- colMeans(e^2 - (cv[[m]]$mean - theta_alt)^2)"),
  e2e_departure        = c("scripts/temp_baseline_recover.R", "sigma <- fr$fit$rmse_open * sqrt(1 - rho^2)  # innovations that give the departure its observed spread")
)

# the files whose formals and top-level numeric constants must each be covered, and the functions whose formals
scope <- c("R/wet_temp_fill.R", "R/wet_temp_gsdd.R", "R/wet_donor_mean.R", "R/wet_cv_folds.R",
           "scripts/temp_fill_validate.R", "scripts/temp_baseline.R", "scripts/temp_baseline_lib.R",
           "scripts/temp_baseline_rule.R", "scripts/temp_baseline_traits.R", "scripts/temp_baseline_recover.R")
scope_formals <- c(wet_temp_fill = "R/wet_temp_fill.R", wet_temp_gsdd = "R/wet_temp_gsdd.R")
# each formal with a default and each top-level numeric constant in `scope`, and the choice that covers it
registry <- c(
  pool = "pool_by_hand", from = "fill_range", to = "fill_range", min_days = "min_days",
  obs_sd = "obs_sd_fixed", level = "plugin_interval",
  value = "gsdd_daily_mean", by = "gsdd_daily_mean", start_date = "gsdd_season", end_date = "gsdd_season",
  wet_air_gap = "air_gap", r2 = "obs_sd_fixed", tb_k = "donor_k", tb_level = "interval_level",
  tb_close = "rule_close", tb_displace = "rule_displace", tb_digits = "rule_tie", min_frac = "kept_stations",
  stuck_sd = "truth_stuck", n_sim = "sim_size", n_e2e = "sim_size", seed = "sim_size",
  share = "sim_known_values", z_max = "leak_check"
)

# each figure the files state: its text as written, where it comes from, and a literal found once there
fig <- function(text, source, literal) list(text = text, source = source, literal = literal)
figures <- list(
  fig("89 to 94 %", "R/wet_temp_fill.R", "The interval covered 89-94 % of held-out days at a nominal 95 %."),
  fig("nominal 95 %", "R/wet_temp_fill.R", "The interval covered 89-94 % of held-out days at a nominal 95 %."),
  fig("130.4 \u00B0C-days", "data/checks/temp_fill_validate.txt", "season 897      -0.165             0.828    897        130.43        128.74"),
  fig("128.7 \u00B0C-days", "data/checks/temp_fill_validate.txt", "season 897      -0.165             0.828    897        130.43        128.74"),
  fig("about 11 \u00B0C-days", "research/station_temperature_fill.md", "So the benchmark here is in-sample by about 11 \u00B0C-days."),
  fig("\u22120.49", "research/station_temperature_fill.md", "(correlation \u22120.49)"),
  fig("87 to 94 %", "research/station_temperature_fill.md", "87 to 94 % of the time at a nominal 90 %"),
  fig("nominal 90 %", "research/station_temperature_fill.md", "87 to 94 % of the time at a nominal 90 %"),
  fig("89.6 to 90.2 %", "research/station_temperature_fill.md", "89.6 to 90.2 % of the time"),
  fig("97.5 \u00B0C-days", "data/checks/temp_baseline.txt", "Gap from the baseline to the own-parameter benchmark (97.5 degC-days)"),
  fig("298.0 \u00B0C-days", "data/checks/temp_baseline.txt", "leakfree regression    298.0"),
  fig("4.1 \u00B0C-days", "research/station_temperature_fill.md", "costs the nearest-stations mean 11.5 \u00B0C-days and the regression 4.1"),
  fig("11.5 \u00B0C-days", "research/station_temperature_fill.md", "costs the nearest-stations mean 11.5 \u00B0C-days and the regression 4.1"),
  fig("0 \u00B0C", "R/wet_temp_fill.R", "floored at 0 \u00B0C for ice"),
  fig("0.1 \u00B0C", "R/wet_temp_fill.R", "obs_sd = 0.1, level = 0.95"),
  fig("0.01 \u00B0C", "research/station_temperature_fill.md", "\u03C3 \u2265 0.01 \u00B0C"),
  fig("5 \u00B0C", "R/wet_temp_gsdd.R", "5 \u00B0C and stays there"),
  fig("4 \u00B0C", "R/wet_temp_gsdd.R", "below 4 \u00B0C, and GSDD is the sum"),
  fig("0.1 degC", "scripts/temp_baseline_traits.R", "0.1 degC is a sensor reading one value"),
  fig("95 % of the basin", "scripts/temp_baseline_traits.R", "Kept: snapped and accepted, at least 95 % of the basin inside BC"),
  fig("traits 50 %, network 25 %, noise 25 %", "data/checks/temp_baseline_recover.txt", "theta's variance: traits 50 %, network 25 %, noise 25 %"),
  fig("10 \u00B0C-days", "scripts/temp_baseline_rule.R", "tb_displace <- 10"),
  fig("50 \u00B0C-days", "scripts/temp_baseline_rule.R", "tb_close <- 50"),
  fig("90 % interval", "scripts/temp_baseline_lib.R", "tb_level <- 0.9")
)
unit_rx <- "[0-9]+(?:\\.[0-9]+)?\\s?(?:\u00B0C-days|\u00B0C|degC|%)"

md_path <- Sys.getenv("MD", review)
is_review <- identical(normalizePath(md_path, mustWork = FALSE), normalizePath(review, mustWork = FALSE))
zot <- path.expand(Sys.getenv("ZOTERO_DIR", "~/Zotero"))
pdfs <- vapply(books, function(b) file.exists(file.path(zot, "storage", b$file)), logical(1))
with_books <- nzchar(Sys.which("pdftotext")) && all(pdfs)
md <- readLines(md_path, warn = FALSE, encoding = "UTF-8")
log <- character()
say <- function(...) {
  x <- paste0(...)
  cat(x, "\n", sep = "")
  log <<- c(log, x)
}
fail <- 0L
bad <- function(...) {
  say("FAIL ", ...)
  fail <<- fail + 1L
}
say("Bayesian alignment check of ", md_path, " (#218)")
if (!with_books) {
  say("QUOTES NOT CHECKED: ", if (!nzchar(Sys.which("pdftotext"))) "no pdftotext" else
    paste("no PDF under ZOTERO_DIR/storage for", paste(names(books)[!pdfs], collapse = ", ")))
}

# ---- text, as knowledge's check cleans it
clean <- function(x) {
  x <- chartr("\u2018\u2019\u201A\u2032`\u201C\u201D\u201E\u2033", "''''\"\"\"\"\"", x)
  x <- gsub("[\u2010-\u2015\u2212]", "-", x)
  x <- gsub("[\u00AD\u200B-\u200D\uFEFF]", "", x)
  x <- gsub("\uFB00", "ff", x)
  x <- gsub("\uFB01", "fi", x)
  x <- gsub("\uFB02", "fl", x)
  x <- gsub("\uFB03", "ffi", x)
  x <- gsub("\uFB04", "ffl", x)
  tolower(x)
}
tokens <- function(x) regmatches(x, gregexpr("[0-9]+(?:[.,][0-9]+)*|[[:alpha:]]+", x, perl = TRUE))[[1]]
# the page's tokens in two readings: line-end hyphens between letters joined, and kept
page_tokens <- function(txt) {
  x <- clean(paste(txt, collapse = "\n"))
  list(tokens(gsub("([[:alpha:]])-[ \t]*\n[ \t]*([[:alpha:]])", "\\1\\2", x, perl = TRUE)), tokens(x))
}
# where `q` sits contiguous in `p` at or after position `from`, or NA
seq_at <- function(q, p, from = 1L) {
  n <- length(q)
  if (!n || length(p) < n) return(NA_integer_)
  for (i in which(p == q[1])) {
    if (i < from || i + n - 1L > length(p)) next
    if (identical(p[i:(i + n - 1L)], q)) return(i)
  }
  NA_integer_
}
page_text <- function(key, p) {
  b <- books[[key]]
  pdf <- file.path(zot, "storage", b$file)
  pp <- p + b$offset
  txt <- system2("pdftotext", c("-layout", "-enc", "UTF-8", "-f", pp, "-l", pp, shQuote(pdf), "-"), stdout = TRUE)
  if (!is.null(attr(txt, "status"))) stop("pdftotext failed on ", key, " page ", p, call. = FALSE)
  txt <- gsub("\f", "", txt, fixed = TRUE)   # the page break pdftotext ends a page with
  # the folio, in the running head or at the foot, past BDA3's one-line notice of its free electronic edition
  lines <- grep("electronic edition", txt[nzchar(trimws(txt))], value = TRUE, invert = TRUE)
  ends <- trimws(c(utils::head(lines, 1), utils::tail(lines, 1)))
  list(txt = txt, folio = any(grepl(paste0("(^|\\s)", p, "(\\s|$)"), ends)))
}

# ---- quotes
txt <- paste(md, collapse = " ")
ends <- cumsum(nchar(md) + 1L)
line_at <- function(pos) findInterval(pos - 1L, c(0L, ends))
sp_rx <- "[\\s\\x{00A0}]"
rx <- paste0("\"([^\"]+)\"", sp_rx, "*(\\(|\\[@)([A-Za-z0-9_]+),", sp_rx, "*pp?\\.", sp_rx, "*([0-9]+)(?:", sp_rx,
             "*[-\u2013]", sp_rx, "*([0-9]+))?(\\)|\\])")
sm <- gregexpr(rx, txt, perl = TRUE)[[1]]
strict <- if (sm[1] > 0) data.frame(start = as.integer(sm), end = as.integer(sm) + attr(sm, "match.length") - 1L,
                                    p_start = attr(sm, "capture.start")[, 1] - 1L,
                                    p_end = attr(sm, "capture.start")[, 1] + attr(sm, "capture.length")[, 1]) else
  data.frame(start = integer(), end = integer(), p_start = integer(), p_end = integer())
masked <- txt
for (k in seq_len(nrow(strict))) {
  substr(masked, strict$p_start[k], strict$p_end[k]) <- strrep(" ", strict$p_end[k] - strict$p_start[k] + 1L)
}
cm <- gregexpr("`[^`]*`", masked)[[1]]
for (k in seq_along(cm)) if (cm[k] > 0) substr(masked, cm[k], cm[k] + attr(cm, "match.length")[k] - 1L) <-
  strrep("x", attr(cm, "match.length")[k])
mark_rx <- "[\"\u201C\u201D\u2018]|(?<![[:alnum:]*_])'(?=[[:alnum:]])"
marks <- gregexpr(mark_rx, masked, perl = TRUE)[[1]]
marks <- if (marks[1] > 0) as.integer(marks) else integer()
pg <- gregexpr(paste0("\\b(pp?|pg|pages?)\\.?", sp_rx, "*[0-9]|\\[@"), masked, perl = TRUE)[[1]]
for (st in if (pg[1] > 0) as.integer(pg) else integer()) {
  hit <- marks[abs(marks - st) <= near]
  if (length(hit)) {
    bad("line ", line_at(st), ": a quote mark within ", near, " characters of a page citation, outside the checked form ",
        "(\"...\" (<citekey>, p. N)), at: ", substr(masked, max(1L, hit[1] - 30L), hit[1] + 30L))
  }
}
ms <- regmatches(txt, list(sm))[[1]]
for (k in seq_along(ms)) {
  i <- line_at(strict$start[k])
  m <- regmatches(ms[k], regexec(rx, ms[k], perl = TRUE))[[1]]
  if ((m[3] == "(") != (m[7] == ")")) {
    bad("line ", i, ": the citation opens with ", m[3], " and closes with ", m[7])
    next
  }
  key <- m[4]
  p1 <- as.integer(m[5])
  p2 <- if (nzchar(m[6])) as.integer(m[6]) else p1
  if (!key %in% names(books)) {
    bad("line ", i, ": ", key, " is not a book this check holds")
    next
  }
  if (p2 < p1 || p2 > p1 + 1L) {
    bad("line ", i, ": pages ", p1, "-", p2, " are not one page or two running on")
    next
  }
  frags <- lapply(strsplit(clean(m[2]), "\u2026|\\.\\.\\.")[[1]], tokens)
  frags <- frags[lengths(frags) > 0L]
  empty <- !length(frags)
  short <- any(lengths(frags) < frag_min)
  if (!with_books) {
    if (empty || short) bad("line ", i, " ", key, " p. ", p1, ": ", if (empty) "the passage has no word in it" else
      paste0("a fragment under ", frag_min, " words"))
    next
  }
  pgs <- lapply(seq(p1, p2), function(p) page_text(key, p))
  folio <- all(vapply(pgs, `[[`, logical(1), "folio"))
  hay <- page_tokens(unlist(lapply(pgs, `[[`, "txt")))
  found <- !empty && any(vapply(hay, function(h) {
    at <- 1L
    for (f in frags) {
      j <- seq_at(f, h, at)
      if (is.na(j)) return(FALSE)
      at <- j + length(f)
    }
    TRUE
  }, logical(1)))
  ok <- found && folio && !short
  why <- c(if (!folio) "the page's head or foot does not carry its number",
           if (empty) "the passage has no word in it",
           if (short) paste0("a fragment under ", frag_min, " words"),
           if (!found && !empty) "passage not on the page")
  if (ok) say("ok   line ", i, " ", key, " p. ", p1, if (p2 != p1) paste0("-", p2))
  else bad("line ", i, " ", key, " p. ", p1, if (p2 != p1) paste0("-", p2), ": ", paste(why, collapse = "; "))
}
say("quotes: ", length(ms), if (with_books) " checked" else " found, not checked on the page", " in ", md_path)
want <- n_quotes[basename(md_path)]
if (!is.na(want) && length(ms) != want) {
  bad(length(ms), " quotes in the checked form where ", want, " are expected: a quote left the checked form, or one ",
      "was added without changing `n_quotes`")
}

# ---- figures: every number with a unit, outside code, citations and checked quotes, is a listed figure
fig_txt <- masked
cite <- gregexpr("\\([A-Za-z0-9_]+, pp?\\. [0-9]+(?:[-\u2013][0-9]+)?\\)", fig_txt, perl = TRUE)[[1]]
for (k in seq_along(cite)) if (cite[k] > 0) substr(fig_txt, cite[k], cite[k] + attr(cite, "match.length")[k] - 1L) <-
  strrep(" ", attr(cite, "match.length")[k])
nums <- regmatches(fig_txt, gregexpr(unit_rx, fig_txt, perl = TRUE))[[1]]
listed <- vapply(figures, `[[`, character(1), "text")
in_file <- vapply(listed, function(f) grepl(f, txt, fixed = TRUE), logical(1))
for (x in unique(nums)) {
  if (!any(vapply(listed[in_file], function(f) grepl(x, f, fixed = TRUE), logical(1)))) {
    bad("figure \"", x, "\" is not in `figures`, or not written as its entry is")
  }
}
for (f in figures[in_file]) {
  if (!file.exists(f$source)) {
    bad("figure \"", f$text, "\": its source ", f$source, " is missing")
    next
  }
  n <- sum(vapply(readLines(f$source, warn = FALSE, encoding = "UTF-8"), function(l) {
    lengths(regmatches(l, gregexpr(f$literal, l, fixed = TRUE)))
  }, integer(1)))
  if (n != 1L) bad("figure \"", f$text, "\": its literal occurs ", n, " times in ", f$source, ", not once")
}
say("figures: ", length(unique(nums)), " numbers with a unit; ", sum(in_file), " of ", length(figures),
    " listed figures in this file, each held to its source")
if (is_review && !all(in_file)) {
  for (f in listed[!in_file]) bad("figure \"", f, "\" is listed but not in the file")
}

if (is_review) {
  # ---- choices
  h <- which(md == "## Choices")
  rows <- list()
  if (length(h) != 1L) {
    bad("the heading \"## Choices\" appears ", length(h), " times")
  } else {
    nxt <- grep("^## ", md)
    end <- c(nxt[nxt > h], length(md) + 1L)[1] - 1L
    r <- grep("^\\|", md[seq.int(h + 1L, end)], value = TRUE)
    r <- r[!grepl("^\\|[\\s:|-]+\\|?\\s*$", r, perl = TRUE)]
    rows <- lapply(r[-1], function(x) trimws(strsplit(sub("^\\|", "", sub("\\|\\s*$", "", x)), "|", fixed = TRUE)[[1]]))
  }
  unbacktick <- function(x) sub("^`([^`]+)`$", "\\1", x)
  ids <- vapply(rows, function(x) unbacktick(x[1]), character(1))
  vd <- vapply(rows, function(x) gsub("\\*", "", tolower(x[length(x)])), character(1))
  for (k in setdiff(names(choices), ids)) bad("Choices: no row for ", k)
  for (k in unique(ids[duplicated(ids)])) bad("Choices: ", k, " has more than one row")
  for (k in setdiff(ids, names(choices))) bad("Choices: ", k, " is not one of the choices this check holds")
  for (j in which(!vd %in% verdicts)) bad("Choices: ", ids[j], "'s last cell is not one verdict")
  say("Choices: ", length(rows), " rows for ", length(choices), "; ",
      paste(names(table(vd)), table(vd), sep = " ", collapse = ", "))
  crows <- stats::setNames(rows, ids)
  for (k in names(choices)) {
    src <- readLines(choices[[k]][1], warn = FALSE, encoding = "UTF-8")
    at <- which(grepl(choices[[k]][2], src, fixed = TRUE))
    if (length(at) != 1L) {
      bad("choice ", k, ": its anchor occurs ", length(at), " times in ", choices[[k]][1], ", not once")
      next
    }
    if (is.null(crows[[k]])) next
    w <- regmatches(crows[[k]][2], regexec("^`?([^`:]+):([0-9]+)`?$", crows[[k]][2]))[[1]]
    if (!length(w)) {
      bad("choice ", k, ": its second cell is not `file:line`")
    } else if (w[2] != choices[[k]][1] || as.integer(w[3]) != at) {
      bad("choice ", k, ": cites ", w[2], ":", w[3], " but its anchor is at ", choices[[k]][1], ":", at)
    }
  }

  # ---- coverage: formals with defaults and top-level numeric constants
  is_const <- function(e) {
    if (is.numeric(e)) return(TRUE)
    if (is.call(e) && is.name(e[[1]]) && as.character(e[[1]]) %in% c("c", "-", "+", "*", "/", "^", "(")) {
      return(all(vapply(as.list(e)[-1], is_const, logical(1))))
    }
    FALSE
  }
  is_assign <- function(e) is.call(e) && is.name(e[[1]]) && as.character(e[[1]]) %in% c("<-", "=") && is.name(e[[2]])
  found <- character()
  for (f in scope) {
    for (e in parse(f, keep.source = FALSE)) {
      if (is_assign(e) && is_const(e[[3]])) found <- c(found, as.character(e[[2]]))
    }
  }
  for (fn in names(scope_formals)) {
    def <- Filter(function(e) is_assign(e) && identical(as.character(e[[2]]), fn), parse(scope_formals[[fn]], keep.source = FALSE))
    if (length(def) != 1L || !is.call(def[[1]][[3]]) || !identical(def[[1]][[3]][[1]], as.name("function"))) {
      bad("coverage: ", fn, " is not defined once in ", scope_formals[[fn]])
      next
    }
    a <- as.list(def[[1]][[3]][[2]])
    found <- c(found, names(a)[!vapply(a, function(x) identical(x, quote(expr = )), logical(1))])
  }
  for (k in unique(found[duplicated(found)])) bad("coverage: ", k, " is assigned more than once in the scope")
  for (k in setdiff(found, names(registry))) bad("coverage: ", k, " has no entry in `registry`")
  for (k in setdiff(names(registry), found)) bad("coverage: `registry` names ", k, ", which the scope no longer sets")
  for (k in names(registry)[!registry %in% names(choices)]) bad("coverage: ", k, "'s choice ", registry[[k]], " is not in `choices`")
  say("coverage: ", length(unique(found)), " formals and constants, each covered by a choice")
}
say(if (fail) paste0("FAILED: ", fail, " problems") else "PASS")

if (is_review && !nzchar(Sys.getenv("MD")) && with_books) {
  out <- file.path("data", "checks", paste0("temperature_bayesian_alignment_", format(Sys.time(), "%Y%m%d", tz = "UTC"), ".txt"))
  writeLines(log, out)
}
if (fail) quit(status = 1L)
