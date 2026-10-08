# Spike: 08E water temperature and air at the station coordinates, cached.
pkgload::load_all("/Users/airvine/Projects/repo/wet", quiet = TRUE)
out <- "/Users/airvine/Projects/repo/wet/data/temp_fill"
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")
DBI::dbExecute(con, "CREATE SECRET a (TYPE s3, PROVIDER config, REGION 'us-west-2')")
st <- DBI::dbGetQuery(con, "SELECT DISTINCT STATION_NUMBER s FROM read_parquet('s3://water-temp-bc/data/canonical/Parameter=5/*.parquet') WHERE STATION_NUMBER LIKE '08E%'")$s
DBI::dbDisconnect(con, shutdown = TRUE)
print(sort(st))
t0 <- Sys.time()
w <- wet_temp_daily(sort(st), from = "2011-01-01", to = "2025-12-31")
saveRDS(w, file.path(out, "spike_08E_water.rds"))
print(Sys.time() - t0); print(table(w$station_number))
a <- tidyhydat::allstations
p <- a[a$STATION_NUMBER %in% unique(w$station_number), c("STATION_NUMBER", "LONGITUDE", "LATITUDE")]
names(p) <- c("id", "lon", "lat")
air <- cd::cd_extract_daily(as.data.frame(p), "2011-01-01", "2025-12-31", variables = "tmean")
saveRDS(air, file.path(out, "spike_08E_air.rds"))
print(Sys.time() - t0); print(range(air$date))
