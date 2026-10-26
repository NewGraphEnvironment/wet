# The per-year routed-PCIC fixture under inst/extdata/pcic_years/ (#122), for
# wet_routed_years()'s example and tests.
#
#   Rscript data-raw/pcic_years_fixture.R
#
# SYNTHETIC: four sub-basins over 1951-2012 in the shape wet reads from
# NewGraphEnvironment/fwapg#42's per-year product (subid, year, month, day,
# q_local, q_acc; one row per sub-basin and calendar day), made up here so
# the tests need nothing from fwapg. The flows are a seasonal curve scaled by
# a year factor, rounded to 4 decimals so the files stay small; the real
# product is unrounded float64. Sub-basins 101 and 102 are headwaters, 103
# takes both, 104 takes 103, and 104's own inflow turns negative in late
# summer (a losing reach), so a segment on it alone is clamped at 0.
#
# Writes, under inst/extdata/pcic_years/:
#   days/part-0.parquet   the per-year days (zstd), sorted by subid and date
#   days/manifest.json    the sidecar: what made the days and from which commit
#   weights.csv           four segments in pcic.segment_weights' shape, the
#                         upstream_subids joined by ";"
#   climatology.csv       the mean of each (month, day) bin over 1951-2012 per
#                         sub-basin, in pcic.subbasin_daily's shape (n_days,
#                         q_local, q_acc), to 17 significant digits
#
# A second mode, cutting the same shape from the real product for one small
# segment, is added once fwapg#42's product exists.

if (!requireNamespace("duckdb", quietly = TRUE)) stop("install duckdb")
out <- "inst/extdata/pcic_years"
dir.create(file.path(out, "days"), recursive = TRUE, showWarnings = FALSE)

set.seed(122)
years <- 1951:2012
date <- seq(as.Date("1951-01-01"), as.Date("2012-12-31"), by = "day")
yr <- as.integer(format(date, "%Y"))
doy <- as.integer(format(date, "%j"))
shared <- stats::setNames(stats::rnorm(length(years), 0, 0.25), years)
local_q <- function(base, peak, own_sd) {
  f <- exp(shared[as.character(yr)] + stats::setNames(stats::rnorm(length(years), 0, own_sd), years)[as.character(yr)])
  base * (0.15 + exp(-((doy - peak) / 30)^2)) * f
}
ql <- list(`101` = local_q(4, 160, 0.10), `102` = local_q(9, 175, 0.15), `103` = local_q(2, 170, 0.10))
ql$`104` <- 1.5 * exp(-((doy - 150) / 25)^2) - 0.4 * exp(-((doy - 240) / 30)^2) * exp(shared[as.character(yr)])
ql <- lapply(ql, round, 4)
qa <- list(`101` = ql$`101`, `102` = ql$`102`)
qa$`103` <- ql$`103` + qa$`101` + qa$`102`
qa$`104` <- ql$`104` + qa$`103`
d <- do.call(rbind, lapply(names(ql), function(s) {
  data.frame(subid = as.integer(s), year = yr, month = as.integer(format(date, "%m")),
             day = as.integer(format(date, "%d")), q_local = ql[[s]], q_acc = qa[[s]])
}))

duck <- DBI::dbConnect(duckdb::duckdb())
DBI::dbWriteTable(duck, "d", d)
f_days <- file.path(out, "days", "part-0.parquet")
unlink(f_days)
invisible(DBI::dbExecute(duck, sprintf("COPY (SELECT * FROM d ORDER BY subid, year, month, day) TO '%s'
  (FORMAT parquet, COMPRESSION zstd)", f_days)))
DBI::dbDisconnect(duck, shutdown = TRUE)

jsonlite::write_json(list(
  product = "synthetic per-year sub-basin flows (data-raw/pcic_years_fixture.R)",
  model = "synthetic", scenario = "historical", years = "1951-2012",
  fwapg_commit = "synthetic"
), file.path(out, "days", "manifest.json"), auto_unbox = TRUE, pretty = TRUE)

w <- data.frame(linear_feature_id = c(1L, 2L, 3L, 4L), subid = c(101L, 103L, 104L, 104L),
                share = c(0.4, 0.5, 1, 1), upstream_subids = c("", "101;102", "103", ""))
utils::write.csv(w, file.path(out, "weights.csv"), row.names = FALSE)

key <- interaction(d$subid, d$month, d$day, drop = TRUE, lex.order = TRUE)
cl <- data.frame(subid = tapply(d$subid, key, `[`, 1), month = tapply(d$month, key, `[`, 1),
                 day = tapply(d$day, key, `[`, 1), n_days = as.integer(tapply(d$year, key, length)),
                 q_local = tapply(d$q_local, key, mean), q_acc = tapply(d$q_acc, key, mean))
cl <- cl[order(cl$subid, cl$month, cl$day), ]
stopifnot(nrow(cl) == 4 * 366, all(cl$n_days[cl$month == 2 & cl$day == 29] == 16))
num <- function(v) sprintf("%.17g", v)
writeLines(c("subid,month,day,n_days,q_local,q_acc",
             paste(cl$subid, cl$month, cl$day, cl$n_days, num(cl$q_local), num(cl$q_acc), sep = ",")),
           file.path(out, "climatology.csv"))
message("wrote ", out, ": ", nrow(d), " days, ", format(file.size(f_days), big.mark = ","), " bytes of parquet")
