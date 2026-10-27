# The per-year routed-PCIC fixture under inst/extdata/pcic_years/ (#122), for
# wet_routed_years()'s example and tests.
#
#   Rscript data-raw/pcic_years_fixture.R
#
# SYNTHETIC: four sub-basins over 1951-2012, laid out as the per-year product
# of NewGraphEnvironment/fwapg#42 is: one file per year, named
# pcic.subbasin_days.<model>_<scenario>.<year>.parquet, holding an int32
# subid, the date, and float32 q_local and q_acc. Made up here so the tests
# need nothing from fwapg. The flows are a seasonal curve scaled by a year factor; q_acc is
# accumulated in float64 and both columns are then stored as float32, as
# fwapg stores them. Sub-basins 101 and 102 are headwaters, 103 takes both,
# 104 takes 103, and 104's own inflow turns negative in late summer (a losing
# reach), so a segment on it alone is clamped at 0.
#
# Writes, under inst/extdata/pcic_years/:
#   days/pcic.subbasin_days.synthetic_historical.<year>.parquet
#                         the days of one year, sorted by subid and date
#   days/pcic.series.csv  the catalogue in fwapg's pcic.series shape: per
#                         year rows, subbasins, q_local_sum and q_acc_sum
#                         (sum of floor(double(v) * 1000 + 0.5) over the
#                         stored float32 values) and bytes
#   weights.csv           four segments in pcic.segment_weights' shape, the
#                         upstream_subids joined by ";"
#   climatology.csv       the mean of each (month, day) bin over 1951-2012 of
#                         the stored values per sub-basin, in
#                         pcic.subbasin_daily's shape, to 17 significant digits
#
# It is synthetic only: scripts/departure_pcic.R checks every sub-basin it
# reads from the real product against pcic.subbasin_daily, which is what a
# real cut would have shown (#122).

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
qa <- list(`101` = ql$`101`, `102` = ql$`102`)
qa$`103` <- ql$`103` + qa$`101` + qa$`102`
qa$`104` <- ql$`104` + qa$`103`
d <- do.call(rbind, lapply(names(ql), function(s) {
  data.frame(subid = as.integer(s), year = yr, month = as.integer(format(date, "%m")),
             day = as.integer(format(date, "%d")), q_local = ql[[s]], q_acc = qa[[s]])
}))

duck <- DBI::dbConnect(duckdb::duckdb())
DBI::dbWriteTable(duck, "d", d)
unlink(list.files(file.path(out, "days"), full.names = TRUE))
fname <- function(y) file.path(out, "days", sprintf("pcic.subbasin_days.synthetic_historical.%d.parquet", y))
sql_copy <- "COPY (SELECT subid::INTEGER AS subid, make_date(year, month, day) AS date,
  q_local::FLOAT AS q_local, q_acc::FLOAT AS q_acc FROM d WHERE year = %d ORDER BY subid, date)
  TO '%s' (FORMAT parquet, COMPRESSION zstd)"
for (y in years) invisible(DBI::dbExecute(duck, sprintf(sql_copy, y, fname(y))))
# everything below is computed from the stored float32 values, read back
files <- paste0("'", fname(years), "'", collapse = ", ")
sql_back <- "SELECT subid, date, q_local, q_acc FROM read_parquet([%s]) ORDER BY subid, date"
back <- DBI::dbGetQuery(duck, sprintf(sql_back, files))
sql_fp <- "SELECT year(date)::INTEGER AS year, count(*)::INTEGER AS rows,
  count(DISTINCT subid)::INTEGER AS subbasins,
  sum(CAST(floor(CAST(q_local AS DOUBLE) * 1000 + 0.5) AS BIGINT))::BIGINT AS q_local_sum,
  sum(CAST(floor(CAST(q_acc AS DOUBLE) * 1000 + 0.5) AS BIGINT))::BIGINT AS q_acc_sum
  FROM read_parquet([%s]) GROUP BY 1 ORDER BY 1"
fp <- DBI::dbGetQuery(duck, sprintf(sql_fp, files))
DBI::dbDisconnect(duck, shutdown = TRUE)
fp <- data.frame(model = "synthetic", scenario = "historical", fp[1], crosswalk_md5 = "synthetic", fp[-1],
                 bytes = file.size(fname(fp$year)))
utils::write.csv(fp, file.path(out, "days", "pcic.series.csv"), row.names = FALSE)

w <- data.frame(linear_feature_id = c(1L, 2L, 3L, 4L), subid = c(101L, 103L, 104L, 104L),
                share = c(0.4, 0.5, 1, 1), upstream_subids = c("", "101;102", "103", ""))
utils::write.csv(w, file.path(out, "weights.csv"), row.names = FALSE)

back$month <- as.integer(format(back$date, "%m"))
back$day <- as.integer(format(back$date, "%d"))
key <- interaction(back$subid, back$month, back$day, drop = TRUE, lex.order = TRUE)
cl <- data.frame(subid = tapply(back$subid, key, `[`, 1), month = tapply(back$month, key, `[`, 1),
                 day = tapply(back$day, key, `[`, 1), n_days = as.integer(tapply(back$q_acc, key, length)),
                 q_local = tapply(back$q_local, key, mean), q_acc = tapply(back$q_acc, key, mean))
cl <- cl[order(cl$subid, cl$month, cl$day), ]
stopifnot(nrow(cl) == 4 * 366, all(cl$n_days[cl$month == 2 & cl$day == 29] == 16), nrow(back) == nrow(d))
num <- function(v) sprintf("%.17g", v)
writeLines(c("subid,month,day,n_days,q_local,q_acc",
             paste(cl$subid, cl$month, cl$day, cl$n_days, num(cl$q_local), num(cl$q_acc), sep = ",")),
           file.path(out, "climatology.csv"))
message("wrote ", out, ": ", nrow(d), " days in ", length(years), " files, ",
        format(sum(fp$bytes), big.mark = ","), " bytes of parquet")
