# Natural stations outside HYDAT as departure donors (#211, #202): the rule,
# registered in this file before scripts/departure_donors.R or any score
# existed, and the functions that apply it. scripts/departure_donors.R sources
# this file and refuses to run when it differs from its registering commit.
# No database, no download: the script supplies every input.
#
# ---- question --------------------------------------------------------------------------------
#
# Does adding the natural stations outside HYDAT, each on an estimated
# 1981-2010 baseline, bring a carried departure closer to the observed one in
# the years those stations have records?
#
# ---- population ------------------------------------------------------------------------------
#
# HYDAT 20260717: natural BC gauges (STN_REGULATION.REGULATED = 0) with
# coordinates and a gross drainage area, approved days only
# (wet_station_daily(sources = "hydat")).
#
# Outside HYDAT: every wet_station_list() row of snapshot 20261028 whose
# `regulation` is "natural", its days from wet_station_daily(sources =
# c("bcenv", "bcwatertool"), to = NULL), provisional and unchecked alike. A
# station's drainage area and watershed codes come from the segment the
# regulation run placed it on (regulation_20261028.csv's linear_feature_id),
# through fwa_streams_watersheds_lut to fwa_watersheds_poly (wscode_ltree,
# localcode_ltree) and fwa_watersheds_upstream_area (upstream_area_ha / 100),
# the joins of rg_sql_snap in scripts/station_regulation_lib.R. A station
# with no upstream area is not a candidate.
#
# ---- windows and statistics ------------------------------------------------------------------
#
# The Bulkley chinook migration and spawning windows
# (inst/vignette-data/life_history_bulk.csv); mean, min7 and cov_day scored,
# max reported; a complete window-year at min_frac = 0.8 (wet_window_stats());
# baseline 1981-2010; the log-ratio scale (days for cov_day). All #120's. A
# usable value is one that is not NA and, unless the statistic is cov_day,
# above 0 (dd_usable()).
#
# ---- per held-out gauge g ----------------------------------------------------------------------
#
# The box is 3.8 deg by 2.2 deg centred on g's HYDAT longitude and latitude,
# each rounded to 2 decimals, bounds inclusive (dd_box()), as #126 centres a
# site's box. Its pools are scripts/departure_site.R's (dd_pools()): the box
# pool, the natural HYDAT gauges in the box with at least 3 complete
# migration-mean window-years; the extension pool, those of them with at
# least 30 and a run of 5 consecutive; the departure pool of a statistic and
# window, those with at least 10 usable baseline values of it.
#
# Held-out gauges, per statistic and window: every natural BC HYDAT gauge in
# its own box's departure pool of that statistic and window (so in its box
# pool too), held out one at a time.
#
# Candidates (dd_candidate()): the stations outside HYDAT that are natural,
# lie in the box, have an upstream area, have at least 3 complete
# migration-mean window-years, and are not at g's own site (`hydat_site` is
# not g). NA in any of these is not a candidate.
#
# One station table per g: the box pool plus every candidate. It is the
# `stations` of every extension and of the carry with the stations, for every
# statistic and both pools, so the predictor SDs do not depend on which
# extensions succeed.
#
# Without (#120's carry): wet_departure_carry(), inverse distance, k = 5,
# baseline 1981-2010; `x` the departure pool's rows less g's; `stations` the
# box pool. A gauge with no HYDAT donor left is not scored, and is counted.
#
# Eligible, per statistic and window, a candidate whose every test below
# passes, each checked before the call and counted under its own reason when
# it fails:
#   - its fit years (dd_fit_years()), the years of its usable values through
#     2024, number at least 3. 2024 is the last year HYDAT 20260717's approved
#     record is broadly complete (272 natural BC gauges hold May-July 2024,
#     120 hold 2025, none 2026);
#   - at least one gauge of the extension pool less g holds a usable value
#     in every fit year;
#   - wet_window_extend(method = "ols", k = 5), with `x` the station's
#     fit-year rows and the extension pool's rows less g's, returns a value in
#     at least 10 baseline years (dd_baseline_rows()). A donor whose values do
#     not vary over the fit years is a reason of its own. Any other error
#     stops the run.
#
# With: the same carry, `x` joined by each eligible station's rows: all its
# usable observed window-years, 2025 and 2026 included, plus its extended
# values in the baseline years it did not observe. Outside the baseline only
# observed values enter. `stations` the table above.
#
# Scored years (dd_scored_years()): the 2011-2025 years in which g has an
# observed window-year, both carries return a departure, and the carry with
# the stations names at least one of them among its donors. Both carries are
# scored on the same years. A gauge with fewer than 3 is not scored.
#
# Score (dd_rmse()): the RMSE, over the scored years, of g's observed
# departure (from its own 1981-2010 mean) minus the carried one, for each
# carry. The paired difference is with minus without.
#
# Leak-free pool: every gauge or station upstream or downstream of g
# (wet:::wet_fwa_upstream() on the watershed codes: wet_station_snap()'s for
# a HYDAT gauge, the lookup above for a station) is dropped from g's donors
# and from the extension donors, in both carries; a related station is not
# eligible (its own reason); the station tables keep their rows. A HYDAT
# gauge whose snap is not accepted keeps every donor, as the site script's
# section 3 does.
#
# ---- verdict ---------------------------------------------------------------------------------
#
# On the migration-window mean (dd_ship()): the estimated-baseline route
# ships if the median over scored gauges of the paired difference is at most
# -0.01 under leave-one-gauge-out and in the leak-free pool, with at least 10
# gauges scored under each. Otherwise the donor pool stays HYDAT-only. One
# verdict, holding for every statistic and window. (The bar is the owner's,
# 2026-11-25, at the plan gate.)
#
# ---- reported, deciding nothing --------------------------------------------------------------
#
#   - n, quartiles and median of each carry's RMSE and of the paired
#     difference, per statistic and window, both pools; how many gauges are
#     better and how many worse; an interval on the median from 2,000
#     resamples of the gauges under set.seed(211).
#   - The paired difference over every 2011-2025 year both carries return, at
#     the gauges with a station among their 5 nearest, split into the years a
#     station is among the donors and the years none is.
#   - Each carry's mean signed error; section 3's centred log NSE on the
#     scored years.
#   - The distinct stations behind the scored gauges, and the median paired
#     difference by station (each gauge under the station it weighted most).
#   - Each eligible station's fit years, slope and extension chain; the
#     stations not eligible, by reason; the stations at a HYDAT site, with
#     HYDAT's flag there.
#   - The gauge-years in which the HYDAT donors of the carry with the
#     stations are not among the carry without's (the SDs differ between the
#     two tables, so the fifth and sixth nearest can swap).
#   - Sensitivities, each a rerun of the whole test: stations with at least
#     5 fit years of the statistic only; window-years with no unchecked day
#     only (a station's window-year is dropped when any of its days with a
#     value inside the window is "unchecked", read from the daily rows); the
#     carry's k at 3 and at 8, the extension's staying 5; without the
#     stations at a HYDAT site whose gauge is in the box pool or flagged
#     regulated by HYDAT.
#
# ---- as seen before registration -------------------------------------------------------------
#
# 2026-11-25, throwaway probes; the report's section 1 is their tracked
# producer, and a count that differs is named there, not corrected here: 75
# natural stations; 36 with at least 3 migration window-years, 33 through
# 2024; none with 10 baseline years; 185 window-years, 58 unchecked
# throughout; by a proxy, 44 of 274 HYDAT gauges with a station among their 5
# nearest. No carried departure with these stations had been computed.
#
# ---- amendments ------------------------------------------------------------------------------
#
# Any change to this file after its registering commit is an amendment:
# dated, appended below the rule with its reason and what had been seen,
# never an edit of the text above; the script's rule_commit moves to it; and
# the report gives the verdict under each version since the first score
# existed.
#
# ---- what it does not decide -----------------------------------------------------------------
#
# Any site report, article number or shipped function. A pass files the
# follow-up that builds the entry point, which must carry a station's
# observed years only: its extended values set its baseline mean and nothing
# else.
#
# ---- amendments, in order --------------------------------------------------------------------
#
# (none)

# ---- constants ---------------------------------------------------------------------------------

dd_release <- "20260717"
dd_snapshot <- "20261028"
dd_half <- c(lon = 1.9, lat = 1.1)
dd_baseline <- 1981:2010
dd_test_years <- 2011:2025
dd_fit_last <- 2024
dd_min_years <- 3          # complete migration-mean window-years: box pool and candidates
dd_min_fit <- 3            # fit years of the statistic, for eligibility
dd_min_ext <- 30           # extension pool: window-years, with a run of dd_run
dd_run <- 5
dd_min_baseline <- 10      # departure pool, and a station's baseline values
dd_min_scored_years <- 3
dd_k <- 5
dd_ext_k <- 5
dd_margin <- 0.01
dd_min_gauges <- 10
dd_n_boot <- 2000
dd_seed <- 211
dd_eps <- 1e-9

# ---- functions ---------------------------------------------------------------------------------

dd_is_days <- function(v) grepl("_cov_day$", v)

# A usable value: not NA and, unless the statistic is a day of the window, above 0.
dd_usable <- function(value, variable) {
  !is.na(value) & (dd_is_days(variable) | value > 0)
}

# g's box: centre rounded to 2 decimals, widened by dd_half, as #126 centres a site's box.
dd_box <- function(lon, lat) {
  stopifnot(length(lon) == 1, length(lat) == 1, is.finite(lon), is.finite(lat))
  lo <- round(lon, 2)
  la <- round(lat, 2)
  c(lon_min = round(lo - dd_half[["lon"]], 2), lon_max = round(lo + dd_half[["lon"]], 2),
    lat_min = round(la - dd_half[["lat"]], 2), lat_max = round(la + dd_half[["lat"]], 2))
}

dd_in_box <- function(lon, lat, box) {
  !is.na(lon) & !is.na(lat) & lon >= box[["lon_min"]] & lon <= box[["lon_max"]] &
    lat >= box[["lat_min"]] & lat <= box[["lat_max"]]
}

# The pools of one box, as scripts/departure_site.R computes them, from the
# box's HYDAT window statistics `ws` (long format) over the station numbers
# `ids` (the natural box gauges with coordinates and area). Returns
# list(box, ext, dep), dep a function of variable and window.
dd_pools <- function(ws, ids) {
  mig <- ws[ws$period == "migration" & ws$variable == "q_mean", ]
  years_of <- function(s) sort(mig$year[mig$station_number == s])
  n_mig <- vapply(ids, function(s) length(years_of(s)), 0L)
  box <- sort(ids[n_mig >= dd_min_years], method = "radix")
  has_run <- function(y) {
    if (length(y) < dd_run) return(FALSE)
    r <- split(y, cumsum(c(1, diff(y) != 1)))
    any(lengths(r) >= dd_run)
  }
  ext <- box[vapply(box, function(s) {
    y <- years_of(s)
    length(y) >= dd_min_ext && has_run(y)
  }, TRUE)]
  wsb <- ws[ws$station_number %in% box, ]
  dep <- function(v, p) {
    g <- wsb[wsb$variable == v & wsb$period == p & dd_usable(wsb$value, v) & wsb$year %in% dd_baseline, ]
    nb <- table(g$station_number)
    sort(names(nb)[nb >= dd_min_baseline], method = "radix")
  }
  list(box = box, ext = ext, dep = dep)
}

# Candidates for held-out gauge g: `st` holds the stations outside HYDAT with
# station_number, regulation, lon, lat, drainage_area_gross_km2, hydat_site and
# n_mig (complete migration-mean window-years). NA in any test is not a candidate.
dd_candidate <- function(st, g, box) {
  ok <- st$regulation %in% "natural" &
    dd_in_box(st$lon, st$lat, box) &
    !is.na(st$drainage_area_gross_km2) & is.finite(st$drainage_area_gross_km2) & st$drainage_area_gross_km2 > 0 &
    !is.na(st$n_mig) & st$n_mig >= dd_min_years &
    (is.na(st$hydat_site) | st$hydat_site != g)
  ok & !is.na(ok)
}

# A station's fit years for one statistic: years of its usable values through dd_fit_last.
dd_fit_years <- function(year, value, variable) {
  stopifnot(length(year) == length(value), length(variable) == 1)
  y <- year[dd_usable(value, variable) & year <= dd_fit_last]
  sort(unique(as.integer(y)))
}

# One station's rows for the carry with the stations: every usable observed
# row (`obs`, long format, 2025 and 2026 included) and the extended rows of
# its wet_window_extend() result `ext` in baseline years it did not observe.
# Fewer than dd_min_baseline baseline values: no rows. A `source` column says
# which each row is.
dd_baseline_rows <- function(obs, ext) {
  cols <- c("station_number", "variable", "period", "year", "value")
  obs <- obs[dd_usable(obs$value, obs$variable), cols]
  obs$source <- rep("observed", nrow(obs))
  ex <- ext[ext$source == "extended" & ext$year %in% dd_baseline & !ext$year %in% obs$year, cols]
  ex$source <- rep("extended", nrow(ex))
  out <- rbind(obs, ex)
  if (sum(out$year %in% dd_baseline) < dd_min_baseline) out <- out[0, ]
  out <- out[order(out$year), ]
  rownames(out) <- NULL
  stopifnot(!anyDuplicated(out[c("station_number", "variable", "period", "year")]))
  out
}

# The station numbers named in a carry's `donors` string ("id:weight id:weight").
dd_donor_ids <- function(donors) {
  if (!length(donors) || is.na(donors) || !nzchar(donors)) return(character())
  sub(":.*$", "", strsplit(donors, " ", fixed = TRUE)[[1]])
}

# Scored years: in dd_test_years, g observed, both carries a departure, and the
# carry with the stations naming at least one of `outside` among its donors.
dd_scored_years <- function(obs_years, without, with, outside) {
  if (!length(obs_years) || !nrow(without) || !nrow(with)) return(integer(0))
  y <- intersect(intersect(dd_test_years, obs_years),
                 intersect(without$year[!is.na(without$anomaly)], with$year[!is.na(with$anomaly)]))
  keep <- vapply(y, function(yr) {
    any(dd_donor_ids(with$donors[with$year == yr]) %in% outside)
  }, TRUE)
  sort(as.integer(y[keep]))
}

dd_rmse <- function(obs, car) {
  stopifnot(length(obs) == length(car))
  if (length(obs) < dd_min_scored_years) return(NA_real_)
  sqrt(mean((obs - car)^2))
}

# The verdict: medians of the paired difference (with minus without) under
# leave-one-gauge-out and leak-free, and how many gauges each scored. Checked
# in site_carry_ship()'s order: counts, an NA median, leave-one-out, leak-free.
dd_ship <- function(loo, lf, n_loo, n_lf) {
  stopifnot(length(loo) == 1, length(lf) == 1, length(n_loo) == 1, length(n_lf) == 1)
  fail <- function(why) list(ship = FALSE, reason = why)
  if (!(n_loo >= dd_min_gauges) || !(n_lf >= dd_min_gauges)) {
    return(fail(sprintf("%d and %d gauges scored, under %d", n_loo, n_lf, dd_min_gauges)))
  }
  if (is.na(loo) || is.na(lf)) return(fail("a median is NA"))
  if (loo > -dd_margin + dd_eps) return(fail(sprintf("leave-one-out median difference %.4f, not at most -%.2f", loo, dd_margin)))
  if (lf > -dd_margin + dd_eps) return(fail(sprintf("leak-free median difference %.4f, not at most -%.2f", lf, dd_margin)))
  list(ship = TRUE, reason = sprintf("median difference %.4f leave-one-out, %.4f leak-free", loo, lf))
}

# OLS slope of the target on one donor over the target's years, on the
# extension's scale (logs, or days): reported, deciding nothing.
dd_slope <- function(xd, yt, days) {
  tr <- if (days) identity else log
  lx <- tr(xd)
  ly <- tr(yt)
  sxx <- sum((lx - mean(lx))^2)
  if (!(sxx > 0)) return(NA_real_)
  sum((lx - mean(lx)) * (ly - mean(ly))) / sxx
}

# One held-out gauge g, one statistic v and window p.
#   xh      the box's HYDAT window statistics (long format)
#   xo      the candidates' window statistics (long format), provisional and unchecked alike
#   st_tab  the station table: the box pool plus every candidate
#           (station_number, lon, lat, drainage_area_gross_km2)
#   cand    the candidates' station numbers
#   ext     the extension pool, dep the departure pool of v and p (HYDAT station numbers)
#   drop    gauges and stations related to g (the leak-free pool), else character()
#   k       the carry's k (the extension's is dd_ext_k)
# Returns list(scored, reason, years, rmse, diff, obs, without, with, eligible, rows).
dd_gauge <- function(g, v, p, xh, xo, st_tab, cand, ext, dep, drop = character(), k = dd_k) {
  days <- dd_is_days(v)
  sel <- function(x) {
    x <- x[x$variable == v & x$period == p, c("station_number", "variable", "period", "year", "value")]
    x[dd_usable(x$value, v), ]
  }
  h <- sel(xh)
  o <- sel(xo[xo$station_number %in% cand, ])
  st_box <- st_tab[!st_tab$station_number %in% cand, ]
  no_elig <- data.frame(station_number = character(), eligible = logical(), reason = character(),
                        n_fit = integer(), fit_years = character(), slope = numeric(), chain = character())
  res <- function(scored, reason, years = integer(0), rmse = c(without = NA_real_, with = NA_real_),
                  obs = NULL, without = NULL, with = NULL, eligible = no_elig, rows = NULL) {
    list(gauge = g, variable = v, period = p, scored = scored, reason = reason, years = years, rmse = rmse,
         diff = unname(rmse[["with"]] - rmse[["without"]]), obs = obs, without = without, with = with,
         eligible = eligible, rows = rows)
  }

  # g's observed departures from its own baseline mean
  go <- h[h$station_number == g, ]
  gb <- go$value[go$year %in% dd_baseline]
  if (length(gb) < dd_min_baseline) return(res(FALSE, "fewer than 10 baseline values at the gauge"))
  obs <- data.frame(year = go$year, dep = if (days) go$value - mean(gb) else log(go$value / mean(gb)))

  donors <- setdiff(dep, c(g, drop))
  if (!length(donors)) return(res(FALSE, "no HYDAT donor left", obs = obs))
  xw <- h[h$station_number %in% donors, ]
  xw$source <- rep("observed", nrow(xw))
  a0 <- wet_departure_carry(xw, st_box, g, k = k, baseline = dd_baseline, min_baseline = dd_min_baseline)

  # eligibility, each reason checked before the call
  ext_don <- setdiff(ext, c(g, drop))
  xe <- h[h$station_number %in% ext_don, ]
  elig <- lapply(sort(cand, method = "radix"), function(s) {
    row <- function(ok, why, fy = integer(0), slope = NA_real_, chain = NA_character_) {
      data.frame(station_number = s, eligible = ok, reason = why, n_fit = length(fy),
                 fit_years = paste(fy, collapse = " "), slope = slope, chain = chain)
    }
    so <- o[o$station_number == s, ]
    fy <- dd_fit_years(so$year, so$value, v)
    if (s %in% drop) return(list(row = row(FALSE, "related to the held-out gauge", fy)))
    if (length(fy) < dd_min_fit) return(list(row = row(FALSE, "fewer than 3 fit years", fy)))
    covers <- vapply(split(xe$year, xe$station_number), function(y) all(fy %in% y), TRUE)
    if (!any(covers)) return(list(row = row(FALSE, "no extension gauge covers its fit years", fy)))
    xt <- rbind(so[so$year %in% fy, ], xe)
    e <- tryCatch(wet_window_extend(xt, st_tab, s, method = "ols", k = dd_ext_k),
                  error = function(err) {
                    if (grepl("do not vary over the target's years", conditionMessage(err), fixed = TRUE)) {
                      return(structure(list(), class = "dd_novary"))
                    }
                    stop(err)
                  })
    if (inherits(e, "dd_novary")) return(list(row = row(FALSE, "an extension donor does not vary over its fit years", fy)))
    chain <- attr(e, "donors")[[paste(v, p, sep = "|")]]
    d1 <- xe[xe$station_number == chain[1], ]
    sl <- dd_slope(d1$value[match(fy, d1$year)], so$value[match(fy, so$year)], days)
    r <- dd_baseline_rows(so, e)
    if (!nrow(r)) return(list(row = row(FALSE, "fewer than 10 baseline values", fy, sl, paste(chain, collapse = " "))))
    list(row = row(TRUE, "eligible", fy, sl, paste(chain, collapse = " ")), rows = r)
  })
  eligible <- if (length(elig)) do.call(rbind, lapply(elig, `[[`, "row")) else no_elig
  rows <- do.call(rbind, lapply(elig, `[[`, "rows"))
  if (is.null(rows)) rows <- xw[0, ]

  a1 <- wet_departure_carry(rbind(xw, rows), st_tab, g, k = k, baseline = dd_baseline,
                            min_baseline = dd_min_baseline)
  yrs <- dd_scored_years(obs$year, a0, a1, cand)
  if (length(yrs) < dd_min_scored_years) {
    return(res(FALSE, sprintf("%d scored years, under %d", length(yrs), dd_min_scored_years), yrs,
               obs = obs, without = a0, with = a1, eligible = eligible, rows = rows))
  }
  ob <- obs$dep[match(yrs, obs$year)]
  rm <- c(without = dd_rmse(ob, a0$anomaly[match(yrs, a0$year)]),
          with = dd_rmse(ob, a1$anomaly[match(yrs, a1$year)]))
  res(TRUE, "scored", yrs, rm, obs = obs, without = a0, with = a1, eligible = eligible, rows = rows)
}
