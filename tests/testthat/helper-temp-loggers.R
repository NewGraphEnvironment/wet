# A logger series "tst" at version "1", in the layout of a pinned Zenodo record
# (#235): a cached data zip whose members are site CSVs in the Nechako format
# (station_code, timestamp (UTC), wtmp (°C), wtmp_flag), a tracked manifest and
# a site registry, all under one temporary directory. `readings` holds columns
# code, time (POSIXct UTC), t and flag; each code becomes site TST_<code>.
logger_readings <- function(code, start, n, t, flag = "P", step = 15) {
  data.frame(code = code, time = as.POSIXct(start, tz = "UTC") + (seq_len(n) - 1) * step * 60,
             t = rep_len(t, n), flag = rep_len(flag, n))
}

logger_fixture <- function(readings, dir = withr::local_tempdir(.local_envir = parent.frame()), fetch = TRUE,
                           subdrainage = "08J", day_offset = -8) {
  # utils::zip() runs the zip program R_ZIPCMD names, else `zip`
  testthat::skip_if(!nzchar(Sys.getenv("R_ZIPCMD", Sys.which("zip"))), "no zip program to build the fixture")
  ext <- file.path(dir, "extdata")
  cache <- file.path(dir, "cache")
  rec <- file.path(cache, "temp_loggers", "tst", "1")
  src <- file.path(dir, "src", "01_Data")
  dir.create(ext, recursive = TRUE)
  dir.create(rec, recursive = TRUE)
  dir.create(src, recursive = TRUE)
  codes <- sort(unique(readings$code), method = "radix")
  for (k in codes) {
    r <- readings[readings$code == k, ]
    x <- data.frame(station_code = k, ts = format(r$time, "%Y-%m-%d %H:%M", tz = "UTC"),
                    t = ifelse(is.na(r$t), "NA", sprintf("%.2f", r$t)), flag = r$flag)
    names(x) <- c("station_code", "timestamp (UTC)", "wtmp (°C)", "wtmp_flag")
    utils::write.csv(x, file.path(src, paste0(k, "_Site.csv")), row.names = FALSE, fileEncoding = "UTF-8")
  }
  zip <- file.path(rec, "01_Data.zip")
  withr::with_dir(file.path(dir, "src"), utils::zip(zip, file.path("01_Data", paste0(codes, "_Site.csv")),
                                                    flags = "-q -X"))
  inner <- file.path("01_Data", paste0(codes, "_Site.csv"))
  m <- file.path(dir, "src", inner)
  man <- rbind(
    data.frame(file = "01_Data.zip", bytes = file.size(zip), md5 = unname(tools::md5sum(zip)),
               url = "https://zenodo.org/records/1/files/01_Data.zip?download=1", fetch = fetch),
    data.frame(file = paste0("01_Data.zip/", inner), bytes = file.size(m), md5 = unname(tools::md5sum(m)),
               url = NA_character_, fetch = NA)
  )
  utils::write.csv(man, file.path(ext, "tst_1.csv"), row.names = FALSE, na = "")
  reg <- data.frame(station_number = paste0("TST_", codes), code = codes, record = "1",
                    member = paste0("01_Data.zip/", inner), name = paste("Site", codes), lon = -124, lat = 54,
                    elevation_m = 700, clock_offset = 0, day_offset = day_offset, subdrainage = subdrainage,
                    nearest_hydat = "08JA001", nearest_eccc = "08JA001", eccc_km = 10, first_reading = "2020-01-01",
                    last_reading = "2020-12-31", licence = "CC BY 4.0", credit = "test", prior_record = NA,
                    prior_code = NA, prior_member = NA)
  utils::write.csv(reg, file.path(ext, "tst_1_sites.csv"), row.names = FALSE, na = "")
  list(dir = dir, ext = ext, cache = cache, zip = zip, manifest = man, registry = reg)
}

# Points wet's logger lookups at the fixture, and makes the network fail.
local_logger_fixture <- function(fx, env = parent.frame()) {
  local_mocked_bindings(wet_logger_path = function(f) {
    p <- file.path(fx$ext, f)
    if (file.exists(p)) p else ""
  }, wet_logger_versions = c(tst = "1"), wet_logger_cache = function() fx$cache, .env = env)
  local_mocked_bindings(curl_download = function(...) stop("network"), curl_fetch_disk = function(...) stop("network"),
                        .package = "curl", .env = env)
}
