# Old pin (20261028) against the cached portal export (20261125): per-station Jan-Sep 2021
# share of compared hours equal at 3 decimals, and the off-hour spans under two matchings.
devtools::load_all(quiet = TRUE)  # from the package root
raw <- file.path(Sys.getenv("WET_DATA_ROOT", "data"), "station_sources", "raw", "portal", "20261125")
st <- c("08NE0001", "08MH0056", "08MH0054", "08NM0054", "08NM0050", "08NM0057", "08NM0004",
        "07FC0001", "08HB0031", "08NM0002")
rd <- function(s) {
  l <- readLines(file.path(raw, sprintf("%s_discharge_working.csv", s)), warn = FALSE)
  h <- which(l == "Timestamp (UTC),Value (m^3/s),Grade Code,Approval Level")
  x <- utils::read.csv(text = l[h:length(l)], colClasses = "character", check.names = FALSE)
  x <- x[nzchar(x[[2]]) & !(x[[3]] == "-3" & x[[2]] == "NaN") & x[[3]] != "-2", ]
  data.frame(s = s, t = as.POSIXct(x[[1]], format = "%Y-%m-%d %H:%M:%S", tz = "UTC"), v = as.numeric(x[[2]]))
}
po <- do.call(rbind, lapply(st, rd))
con <- DBI::dbConnect(duckdb::duckdb())
wet_bcenv_hours(con, wet_bcenv("20261028"))
hr <- DBI::dbGetQuery(con, sprintf("SELECT id AS s, CAST(t AS TIMESTAMP) AS t, value AS v FROM h
  WHERE grade <> 'Unusable' AND id IN (%s)", paste(DBI::dbQuoteString(con, st), collapse = ", ")))
DBI::dbDisconnect(con, shutdown = TRUE)
attr(hr$t, "tzone") <- "UTC"
hr <- hr[!is.na(hr$v), ]
cat("pinned off-minute stamps:", sum(format(hr$t, "%M:%S") != "00:00"), "\n")
eq <- function(p, q) abs(round(p, 3) - q) < 5e-7
# Jan-Sep 2021, on the hour
p0 <- po[format(po$t, "%M:%S") == "00:00", ]
m <- merge(setNames(p0, c("s", "t", "p")), setNames(hr, c("s", "t", "q")))
m <- m[m$t >= as.POSIXct("2021-01-01", tz = "UTC") & m$t < as.POSIXct("2021-10-01", tz = "UTC"), ]
m$ok <- eq(m$p, m$q)
print(do.call(rbind, lapply(split(m, m$s), function(d) data.frame(s = d$s[1], n = nrow(d), share = 100 * mean(d$ok)))))
m$mon <- format(m$t, "%Y-%m")
print(stats::aggregate(ok ~ s + mon, m, function(x) round(100 * mean(x), 1)))
# off-hour spans
spans <- list(c("08HB0031", "2023"), c("08MH0056", "2025"), c("08NM0050", "2025"), c("08NM0050", "2026"),
              c("08NM0054", "2026"))
for (sp in spans) {
  q <- hr[hr$s == sp[1] & format(hr$t, "%Y") == sp[2], ]
  p <- po[po$s == sp[1] & format(po$t, "%Y") == sp[2], ]
  p$key <- format(p$t, "%Y-%m-%d %H")
  q$key <- format(q$t, "%Y-%m-%d %H")
  p <- p[order(p$t), ]
  has0 <- unique(p$key[format(p$t, "%M:%S") == "00:00"])
  q <- q[q$key %in% p$key & !q$key %in% has0, ]
  first <- p[!duplicated(p$key), ]
  any_ok <- vapply(seq_len(nrow(q)), function(i) any(eq(p$v[p$key == q$key[i]], q$v[i])), FALSE)
  f_ok <- eq(first$v[match(q$key, first$key)], q$v)
  # previous hour's last point (hour-ending reading)
  last <- p[!duplicated(p$key, fromLast = TRUE), ]
  pk <- format(q$t - 3600, "%Y-%m-%d %H")
  l_ok <- eq(last$v[match(pk, last$key)], q$v)
  cat(sp, "hours", nrow(q), "first", round(100 * mean(f_ok), 2), "any", round(100 * mean(any_ok), 2),
      "prev-last", round(100 * mean(l_ok, na.rm = TRUE), 2), "\n")
}
