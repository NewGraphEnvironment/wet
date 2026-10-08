# Held-out skill of wet_temp_fill() at the water-temperature stations (#40).
#
#   Rscript scripts/temp_fill_validate.R
#
# Truth: station-years whose 1 March - 30 November is observed with no gap
# longer than 2 days. Each one is hidden in turn, in four shapes, with every
# other station left in; the station is refitted without the hidden days and
# filled. Peers are the station's WSC sub-drainage (first 3 characters).
#
#   season    1 Mar - 30 Nov
#   shoulders 1 Mar - 15 May and 1 Oct - 30 Nov (a seasonal logger's missing ends)
#   gap30     1 - 30 Jul
#   gap7      10 - 16 Jul
#
# Methods, each adding one ingredient:
#   open      air2stream open-loop (S alone)
#   forward   S plus the departure carried forward from the last observed day, b = 0
#   smooth    S plus the smoothed departure (both ends of the gap), b = 0
#   full      smooth plus the peer anomaly: wet_temp_fill()
#   linear    straight line across the gap (gap7, gap30 only)
#
# Scores: daily RMSE on the observed hidden days (never the interpolated ones),
# 95 % interval coverage of `full`, and GSDD error, against the truth GSDD
# (gaps of 1-2 days interpolated). The decision rule was pre-registered in
# planning/active/findings.md before this script was first run.
#
# Inputs (cached under data/temp_fill/, fetched when absent):
#   water_2002_2025.rds  wet_temp_daily() for every station in the archive
#   air_2002_2025.rds    cd::cd_extract_daily() tmean at tidyhydat coordinates
# Output: data/checks/temp_fill_validate.txt, data/temp_fill/validate_scores.rds

pkgload::load_all(".", quiet = TRUE)
options(width = 160)
stopifnot(utils::packageVersion("cd") >= "0.6.1", requireNamespace("gsdd", quietly = TRUE))
dir <- "data/temp_fill"
fs::dir_create(dir)
# The daily cube covers BC (48-60 N, 114-140 W); cd names the points it
# cannot place, and a station at 59.99 N is among them, so drop what it names.
wet_air_inside <- function(p) {
  repeat {
    e <- tryCatch({
      cd::cd_extract_daily(as.data.frame(p), "2002-01-01", "2002-01-01",
                           variables = "tmean")
      NULL
    }, error = function(e) conditionMessage(e))
    if (is.null(e)) return(p)
    out <- regmatches(e, gregexpr("[0-9]{2}[A-Z]{2}[A-Z0-9]{3}", e))[[1]]
    if (!length(out)) stop(e, call. = FALSE)
    message("outside the air cube, dropped: ", paste(out, collapse = ", "))
    p <- p[!p$id %in% out, ]
  }
}
f_water <- file.path(dir, "water_2002_2025.rds")
f_air <- file.path(dir, "air_2002_2025.rds")
if (!file.exists(f_water)) {
  con <- DBI::dbConnect(duckdb::duckdb())
  DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
  DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')")
  st <- DBI::dbGetQuery(con, paste0("SELECT DISTINCT STATION_NUMBER s FROM read_parquet(",
                                    "'s3://water-temp-bc/data/canonical/Parameter=5/*.parquet')"))$s
  DBI::dbDisconnect(con, shutdown = TRUE)
  saveRDS(suppressWarnings(wet_temp_daily(sort(st), from = "2002-01-01", to = "2025-12-31")), f_water)
}
water <- readRDS(f_water)
if (!file.exists(f_air)) {
  a <- tidyhydat::allstations
  p <- a[a$STATION_NUMBER %in% unique(water$station_number), c("STATION_NUMBER", "LONGITUDE", "LATITUDE")]
  names(p) <- c("id", "lon", "lat")
  p <- wet_air_inside(p)
  saveRDS(cd::cd_extract_daily(as.data.frame(p), "2002-01-01", "2025-12-31", variables = "tmean"), f_air)
}
air <- readRDS(f_air)
water <- water[water$station_number %in% air$id, ]
pool <- stats::setNames(substr(unique(water$station_number), 1, 3), unique(water$station_number))

# Truth station-years
truth_years <- function(w) {
  do.call(rbind, lapply(split(w, w$station_number), function(x) {
    do.call(rbind, lapply(unique(format(x$date, "%Y")), function(y) {
      d <- seq(as.Date(paste0(y, "-03-01")), as.Date(paste0(y, "-11-30")), by = "day")
      h <- d %in% x$date
      if (!h[1] || !h[length(h)]) return(NULL)
      rl <- rle(h)
      if (any(!rl$values & rl$lengths > 2)) return(NULL)
      data.frame(station_number = x$station_number[1], year = as.integer(y))
    }))
  }))
}
ty <- truth_years(water)
shapes <- list(season = list(c("03-01", "11-30")),
               shoulders = list(c("03-01", "05-15"), c("10-01", "11-30")),
               gap30 = list(c("07-01", "07-30")), gap7 = list(c("07-10", "07-16")))
hidden_days <- function(year, shape) {
  do.call(c, lapply(shapes[[shape]], function(r) {
    seq(as.Date(paste0(year, "-", r[1])), as.Date(paste0(year, "-", r[2])), by = "day")
  }))
}
# GSDD of one year's 1 Mar - 30 Nov, by wet_temp_gsdd() itself, with 1-2 day
# gaps interpolated
gsdd_year <- function(date, value, year) {
  d <- seq(as.Date(paste0(year, "-03-01")), as.Date(paste0(year, "-11-30")), by = "day")
  v <- value[match(d, date)]
  if (anyNA(v)) v <- stats::approx(as.numeric(d)[!is.na(v)], v[!is.na(v)], as.numeric(d))$y
  g <- wet_temp_gsdd(data.frame(station_number = "x", date = d, t_mean_c = v))
  g$value[g$year == year]
}

# Every station prepared once from its whole record; a held-out station is
# prepared again without its hidden days. Peers' errors depend only on their
# own data, so this is what wet_temp_fill() computes for the held station.
r2 <- 0.1^2
air_by <- split(air, air$id)
t_prep <- Sys.time()
full_prep <- wet_fill_prepare(water, air, pool, NULL, NULL, 365, r2)
message("prepared ", length(full_prep$fit_st), " stations in ",
        format(round(Sys.time() - t_prep, 1)))

score_one <- function(i, shape) {
  s <- ty$station_number[i]
  y <- ty$year[i]
  hid <- hidden_days(y, shape)
  x <- water[water$station_number == s, ]
  tr <- x[x$date %in% hid, c("date", "t_mean_c")]
  keep <- x[!x$date %in% hid, ]
  # fill exactly the station's whole record range, as the default would
  p1 <- wet_fill_prepare(keep, air_by[[s]], pool[s], min(x$date), max(x$date), 365, r2)
  if (!s %in% p1$fit_st) return(NULL)
  prep <- wet_fill_swap(full_prep, p1, s)
  full <- wet_fill_station(prep, s, r2)
  b0 <- wet_fill_station(prep, s, r2, peers = FALSE)
  k <- match(tr$date, full$date)
  # smooth and full are what wet_temp_fill() returns; open and forward are
  # the baselines, floored the same way
  vf <- wet_fill_values(full, 0.95)
  est <- list(open = pmax(full$s_open[k], 0), forward = pmax(b0$s_open[k] + b0$fmean[k], 0),
              smooth = wet_fill_values(b0, 0.95)$t_mean_c[k], full = vf$t_mean_c[k])
  if (shape %in% c("gap30", "gap7")) {
    est$linear <- stats::approx(as.numeric(keep$date), keep$t_mean_c, as.numeric(tr$date))$y
  }
  # GSDD: truth from the observed year; each method from observed + its fill
  g_true <- gsdd_year(x$date, x$t_mean_c, y)
  rows <- lapply(names(est), function(m) {
    v <- c(keep$t_mean_c, est[[m]])
    d <- c(keep$date, tr$date)
    data.frame(station_number = s, year = y, pool = pool[[s]], shape = shape, method = m,
               n = nrow(tr), rmse = sqrt(mean((est[[m]] - tr$t_mean_c)^2)),
               bias = mean(est[[m]] - tr$t_mean_c),
               cover = if (m == "full") {
                 mean(tr$t_mean_c >= vf$t_lo_c[k] & tr$t_mean_c <= vf$t_hi_c[k])
               } else {
                 NA_real_
               },
               gsdd_true = g_true, gsdd = gsdd_year(d, v, y), b = full$par[["b"]],
               month_bias = I(list(tapply(est[[m]] - tr$t_mean_c, format(tr$date, "%m"), mean))))
  })
  do.call(rbind, rows)
}

jobs <- expand.grid(i = seq_len(nrow(ty)), shape = names(shapes), stringsAsFactors = FALSE)
cl <- parallel::makeCluster(max(1, parallel::detectCores() - 2))
root <- normalizePath(".")
parallel::clusterExport(cl, "root")
invisible(parallel::clusterEvalQ(cl, pkgload::load_all(root, quiet = TRUE)))
parallel::clusterExport(cl, c("water", "air_by", "pool", "ty", "shapes", "hidden_days", "gsdd_year",
                              "r2", "full_prep", "score_one", "jobs"))
t0 <- Sys.time()
res <- parallel::parLapply(cl, seq_len(nrow(jobs)), function(j) {
  tryCatch(score_one(jobs$i[j], jobs$shape[j]), error = function(e) {
    data.frame(station_number = ty$station_number[jobs$i[j]], year = ty$year[jobs$i[j]],
               shape = jobs$shape[j], error = conditionMessage(e))
  })
})
parallel::stopCluster(cl)
elapsed <- Sys.time() - t0
errs <- Filter(function(r) !is.null(r) && "error" %in% names(r), res)
sc <- do.call(rbind, Filter(function(r) !is.null(r) && !"error" %in% names(r), res))
sc$gsdd_err <- sc$gsdd - sc$gsdd_true
saveRDS(sc, file.path(dir, "validate_scores.rds"))

# Report
lines <- c(sprintf("wet_temp_fill() held-out validation (#40), %s", format(Sys.time(), "%Y-%m-%d")),
           sprintf("wet %s, gsdd %s, cd %s", utils::packageVersion("wet"),
                   utils::packageVersion("gsdd"), utils::packageVersion("cd")),
           sprintf("water %s .. %s, %d stations; truth station-years %d at %d stations",
                   min(water$date), max(water$date), length(unique(water$station_number)), nrow(ty),
                   length(unique(ty$station_number))),
           sprintf("jobs %d, scored %d, errors %d, %.1f min", nrow(jobs),
                   nrow(unique(sc[c("station_number", "year", "shape")])), length(errs),
                   as.numeric(elapsed, units = "mins")), "")
fmt <- function(d) utils::capture.output(print(d, row.names = FALSE, digits = 3))
summ <- do.call(rbind, lapply(split(sc, list(sc$shape, sc$method), drop = TRUE), function(d) {
  data.frame(shape = d$shape[1], method = d$method[1], n = nrow(d), rmse_mean = mean(d$rmse),
             rmse_median = stats::median(d$rmse), bias = mean(d$bias),
             gsdd_mae = mean(abs(d$gsdd_err), na.rm = TRUE), gsdd_bias = mean(d$gsdd_err, na.rm = TRUE),
             gsdd_na = sum(is.na(d$gsdd_err)), cover = mean(d$cover))
}))
summ <- summ[order(match(summ$shape, names(shapes)),
                   match(summ$method, c("open", "forward", "smooth", "full", "linear"))), ]
lines <- c(lines, "## By shape and method (daily RMSE and bias in degC, GSDD in degC-days)", fmt(summ), "")

# Pre-registered rule (findings.md): paired by station-year on `season`
pr <- function(shape) {
  f <- sc[sc$shape == shape & sc$method == "full", ]
  o <- sc[sc$shape == shape & sc$method == "open", ]
  k <- match(paste(f$station_number, f$year), paste(o$station_number, o$year))
  d <- f$rmse - o$rmse[k]
  # GSDD over the station-years where both have one
  both <- !is.na(f$gsdd_err) & !is.na(o$gsdd_err[k])
  g <- abs(f$gsdd_err[both]) - abs(o$gsdd_err[k][both])
  c(n = length(d), median_diff = stats::median(d), share_full_better = mean(d < 0), n_gsdd = sum(both),
    gsdd_mae_full = mean(abs(f$gsdd_err[both])), gsdd_mae_open = mean(abs(o$gsdd_err[k][both])),
    gsdd_share_full_better = mean(g < 0))
}
rule <- t(sapply(names(shapes), pr))
lines <- c(lines, "## Paired full vs open, by station-year",
           fmt(data.frame(shape = rownames(rule), round(as.data.frame(rule), 3))), "")
season <- rule["season", ]
pass <- season[["median_diff"]] < 0 && season[["share_full_better"]] >= 0.6 &&
  season[["gsdd_mae_full"]] < season[["gsdd_mae_open"]]
lines <- c(lines, sprintf(paste("Rule (season: median paired RMSE difference < 0,",
                                "full better in >= 60 %%, GSDD MAE lower): %s"),
                          if (pass) "PASS" else "FAIL"), "")

# Peers: by whether another fitted station of the same sub-sub-drainage (first
# 4 characters) has at least 30 observed days in that year's 1 Mar - 30 Nov
m <- as.integer(format(water$date, "%m"))
seen <- water[water$station_number %in% full_prep$fit_st & m >= 3 & m <= 11, ]
seen <- stats::aggregate(list(n = seen$date), list(station_number = seen$station_number,
                                                   year = as.integer(format(seen$date, "%Y"))), length)
seen <- seen[seen$n >= 30, ]
sc$sub_peer <- vapply(seq_len(nrow(sc)), function(i) {
  o <- seen$station_number[seen$year == sc$year[i]]
  any(o != sc$station_number[i] & substr(o, 1, 4) == substr(sc$station_number[i], 1, 4))
}, logical(1))
of <- sc[sc$method %in% c("open", "full"), ]
by_peer <- do.call(rbind, lapply(split(of, list(of$shape, of$method, of$sub_peer), drop = TRUE), function(d) {
  data.frame(shape = d$shape[1], method = d$method[1], sub_sub_peer = d$sub_peer[1], n = nrow(d),
             rmse_mean = mean(d$rmse))
}))
lines <- c(lines, "## By whether a peer shares the sub-sub-drainage (a proxy for one on the same stem)",
           fmt(by_peer[order(by_peer$shape, by_peer$sub_sub_peer, by_peer$method), ]), "")

# Monthly bias of `full` and `open` on the season holdout (seasonal hysteresis)
mb <- function(m) {
  d <- sc[sc$shape == "season" & sc$method == m, ]
  mm <- do.call(rbind, lapply(d$month_bias, function(v) v[sprintf("%02d", 3:11)]))
  round(colMeans(mm, na.rm = TRUE), 2)
}
lines <- c(lines, "## Mean bias by month, season holdout (degC)",
           fmt(rbind(open = mb("open"), full = mb("full"))), "")

# By pool
se <- sc[sc$shape == "season" & sc$method %in% c("open", "full"), ]
bp <- do.call(rbind, lapply(split(se, list(se$pool, se$method), drop = TRUE), function(d) {
  data.frame(pool = d$pool[1], method = d$method[1], n = nrow(d), rmse_mean = mean(d$rmse),
             gsdd_mae = mean(abs(d$gsdd_err), na.rm = TRUE), b_median = stats::median(d$b))
}))
lines <- c(lines, "## Season holdout by WSC sub-drainage", fmt(bp[order(bp$pool, bp$method), ]), "")
if (length(errs)) {
  lines <- c(lines, "## Errors", vapply(errs, function(e) paste(e$station_number, e$year, e$shape, e$error),
                                        character(1)))
}
fs::dir_create("data/checks")
writeLines(lines, "data/checks/temp_fill_validate.txt")
cat(lines, sep = "\n")
