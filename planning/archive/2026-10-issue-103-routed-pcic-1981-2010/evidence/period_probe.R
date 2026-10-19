# #103 probe: routed PCIC's monthly error at the calibration gauges, 1951-2012 run against 1981-2010 run,
# both against the gauges' 1981-2010 observed months (as vignettes/monthly-flow.Rmd scores it)
suppressMessages(source("scripts/wb_cv_lib.R"))
fits <- readRDS(file.path(fit_dir, "fits.rds"))
cvr <- readRDS(file.path(fit_dir, sprintf("cv_aet-%s.rds", fits$aet)))
stopifnot(identical(cvr$station_number, cal$station_number))
ho <- long(cal, cvr$cv_ann, cvr$cv_share)
days <- c(365.25, wet_month_days())
conn <- DBI::dbConnect(RPostgres::Postgres(), host = Sys.getenv("PGHOST", "localhost"), dbname = "fwapg",
                       user = Sys.getenv("PGUSER", "postgres"), password = Sys.getenv("PGPASSWORD", "postgres"))
ids <- paste(unique(as.integer(cal$linear_feature_id)), collapse = ", ")
rd <- function(per) {
  r <- DBI::dbGetQuery(conn, sprintf("SELECT linear_feature_id::int AS lf, month::int AS month, q_m3s
    FROM pcic.discharge_monthly WHERE (model, scenario, period) = ('PNWNAmet', 'historical', '%s')
    AND linear_feature_id IN (%s) ORDER BY 1, 2", per, ids))
  a <- aggregate(q_m3s ~ lf, r, function(x) if (length(x) == 12) mean(x) else NA)
  rbind(r, data.frame(lf = a$lf, month = 0L, q_m3s = a$q_m3s))
}
g <- data.frame(station_number = ho$station_number, month = ho$month, obs = ho$obs)
g$area <- cal$upstream_area_m2[match(g$station_number, cal$station_number)]
g$lf <- as.integer(cal$linear_feature_id[match(g$station_number, cal$station_number)])

for (per in c("1951-2012", "1981-2010")) {
  r <- rd(per)
  q <- r$q_m3s[match(paste(g$lf, g$month), paste(r$lf, r$month))]
  g[[per]] <- q * days[g$month + 1] * 86400 / g$area * 1000 / g$obs
}
DBI::dbDisconnect(conn)
ann <- g[g$month == 0, ]
far <- ann$station_number[is.na(ann$`1981-2010`) | ann$`1981-2010` < 0.2 | ann$`1951-2012` < 0.2]
m <- g[!g$station_number %in% far & g$month > 0, ]
cat("gauges scored:", length(unique(m$station_number)), "\n")
med <- function(x) round(100 * (stats::median(x) - 1), 1)
tab <- data.frame(month = 1:12,
  r5112 = tapply(m$`1951-2012`, m$month, med), r8110 = tapply(m$`1981-2010`, m$month, med))
tab$move <- tab$r8110 - tab$r5112
print(tab, row.names = FALSE)
for (mo in list(spring = 3:4, summer = 7:8)) {
  x <- m[m$month %in% mo, ]
  cat(paste(range(mo), collapse = "-"), ": season median 5112", med(x$`1951-2012`), " 8110", med(x$`1981-2010`), "\n")
}
bg <- function(col, mo) tapply(m[[col]][m$month %in% mo], m$station_number[m$month %in% mo], mean)
lo <- bg("1981-2010", 3:4) < 1; hi <- bg("1981-2010", 7:8) > 1
cat("per gauge 1981-2010: low Mar-Apr", round(100 * mean(lo)), "% high Jul-Aug", round(100 * mean(hi)), "% both", round(100 * mean(lo & hi)), "%\n")
lo5 <- bg("1951-2012", 3:4) < 1; hi5 <- bg("1951-2012", 7:8) > 1
cat("per gauge 1951-2012: low Mar-Apr", round(100 * mean(lo5)), "% high Jul-Aug", round(100 * mean(hi5)), "% both", round(100 * mean(lo5 & hi5)), "%\n")
