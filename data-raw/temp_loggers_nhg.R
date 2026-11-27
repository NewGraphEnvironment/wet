# UNBC's Nechako water temperature loggers: pin both Zenodo records, seed wet's
# cache, back them up, write the site registry (#235, #215)
#
# Usage, from the package root:
#   [WET_BACKUP=1] Rscript data-raw/temp_loggers_nhg.R
#
# The Northern Hydrometeorology Group (University of Northern British Columbia)
# publishes its Nechako loggers on Zenodo, CC BY 4.0, in two records under
# separate concepts:
#   15053907  Kokoszka, Tavares, Broeke, Calder-Sutt and Déry (2025), 2019-2024,
#             32 sites, 10.5281/zenodo.15053907: the record wet reads;
#   6426024   Morris, Gilbert, Kaveney and Déry (2022), 2019-2021, 24 sites,
#             10.5281/zenodo.6426024: every one of its sites is in the later
#             record, so it is read only to compare the two
#             (scripts/temp_loggers.R).
# Zenodo's robots.txt (read 2026-11-27) allows /records/*/files and asks a
# 10 s crawl delay; each file is fetched once, 10 s apart, with user agent
# "wet", and kept only at the md5 Zenodo publishes for it.
#
# 1. Fetches each record's ReadMe and data zips into wet's cache,
#    <cache>/temp_loggers/nhg/<record>/, at Zenodo's md5s (a copy already there
#    is held to them instead).
# 2. Writes the tracked manifests inst/extdata/temp_loggers/nhg_<record>.csv:
#    the files (fetch TRUE: a Zenodo record never changes) and the zip members
#    wet reads, with their bytes and md5s.
# 3. With WET_BACKUP=1, puts every file and its .md5 in the private backup
#    s3://fresh-bc/temp_loggers/nhg/<record>/ and checks each object's size and
#    ETag.
# 4. Writes the site registry inst/extdata/temp_loggers/nhg_15053907_sites.csv:
#    id NHG_<site code>; name, coordinates and elevation from Site_Metadata.txt;
#    the readings' clock (UTC in both records, per their ReadMe files); the
#    sub-drainage and day offset of the nearest HYDAT station (as the Water
#    Tool's registry takes its sub-drainage), so a logger pools with its ECCC
#    peers in wet_temp_fill(); the nearest ECCC water temperature station and
#    its distance; the first and last day with a reading (UTC); and the earlier
#    record's code and file for the same site, matched below by name and
#    position. Refused: an id shaped like a HYDAT number or held by the ECCC
#    temperature archive.

devtools::load_all(quiet = TRUE)
source("scripts/station_sources_lib.R")  # albers(), hydat_stations()
source("scripts/wb_fit_lib.R")  # wb_hydat()

series <- "nhg"
version <- "15053907"
prior <- "6426024"
stopifnot(identical(wet_logger_versions[[series]], version))
hydat_release <- "20260717"
same_site_km <- 0.5
licence <- "CC BY 4.0"
credit <- paste("Kokoszka, J. E., Tavares, M. A., Broeke, D., Calder-Sutt, F. and Déry, S. J. (2025). Sub-hourly",
                "water temperature data collected by UNBC's Northern Hydrometeorology Group (NHG) across the Nechako",
                "Watershed, 2019-2024. Zenodo (CC BY 4.0), https://doi.org/10.5281/zenodo.15053907")

# Zenodo's files and checksums (/api/records/<record>/files, 2026-11-27); the earlier record's map
# (Logger Locations in Nechako Watershed.png) is not pinned: its ReadMe gives the coordinates.
files <- data.frame(
  record = c(version, version, version, prior, prior),
  file = c("ReadMe.txt", "01_Data.zip", "02_SupplementaryMaterials.zip", "NHG Data ReadMe.txt", "Data.zip"),
  bytes = c(5853, 13830401, 23591136, 8297, 3092827),
  md5 = c("7e0d696f4520dba176b6efc66dbe58c1", "d47b825dc74fd8d5e7b83843a8000921", "52e65a375a4db9d5ccd11964dab8f20a",
          "b68f4df218144556ea0f85b228f04acb", "9e02d845709aca59c50133f40cf2cd7e"))
files$url <- sprintf("https://zenodo.org/records/%s/files/%s?download=1", files$record,
                     vapply(files$file, utils::URLencode, "", reserved = TRUE))

# The earlier record's sites (three-letter codes, NHG Data ReadMe.txt) against the later record's codes.
# Names match after case, spelling (Terrezon/Tezzeron) and Whitesail's "Middle"; positions within
# same_site_km, except Stellako, which the earlier ReadMe places at Endako's position (6 km away).
prior_map <- c(CNR = "01NE006", CSC = "01FW003", CNE = "01FW022", CTL = "01FW018", ESR = "01FW002",
               KMR = "01FW023", KTE = "01FW001", LTL = "01NE005", MTL = "01FW019", NFL = "01FW012",
               NCC = "01FW017", NMI = "01FW005", NDR = "01FW013", NSL = "01FW016", OFL = "01FW007",
               PSL = "01FW021", RSC = "01NE004", SLS = "01FW010", SFL = "01FW004", SNR = "01FW015",
               TSL = "01FW011", TPL = "01FW020", WTL = "01NE002", WHC = "01NE003")
prior_far_ok <- "SFL"

cache_root <- file.path(tools::R_user_dir("wet", "cache"), "temp_loggers", series)

# ---- 1. the files -----------------------------------------------------------------------------
fetched <- FALSE
for (i in seq_len(nrow(files))) {
  dir <- file.path(cache_root, files$record[i])
  dest <- file.path(dir, files$file[i])
  if (!file.exists(dest)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    if (fetched) Sys.sleep(10)
    partial <- tempfile(".partial-", tmpdir = dir)
    curl::curl_download(files$url[i], partial, quiet = TRUE, handle = curl::new_handle(useragent = "wet"))
    fetched <- TRUE
    wet:::wet_bcenv_check(partial, files$bytes[i], files$md5[i])
    if (!file.rename(partial, dest)) stop("could not move ", files$file[i], " into ", dir, call. = FALSE)
    message("fetched ", files$record[i], "/", files$file[i])
  }
  wet:::wet_bcenv_check(dest, files$bytes[i], files$md5[i])
}
message("both records' files are in ", cache_root, " at Zenodo's md5s")

# ---- 2. the manifests -------------------------------------------------------------------------
ex <- tempfile("nhg_")
member_rows <- function(record, zip, want) {
  z <- file.path(cache_root, record, zip)
  inner <- utils::unzip(z, list = TRUE)$Name
  inner <- inner[grepl(want, inner)]
  utils::unzip(z, files = inner, exdir = file.path(ex, record, zip))
  p <- file.path(ex, record, zip, inner)
  data.frame(file = paste0(zip, "/", inner), bytes = file.size(p), md5 = unname(tools::md5sum(p)), url = NA_character_,
             fetch = NA)
}
out_dir <- file.path("inst", "extdata", "temp_loggers")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
members <- list(
  rbind(member_rows(version, "01_Data.zip", "^01_Data/.+[.]csv$"),
        member_rows(version, "02_SupplementaryMaterials.zip", "/Site_Metadata[.]txt$")),
  member_rows(prior, "Data.zip", "^Data/.+[.]csv$"))
names(members) <- c(version, prior)
for (r in c(version, prior)) {
  top <- files[files$record == r, ]
  man <- rbind(data.frame(file = top$file, bytes = top$bytes, md5 = top$md5, url = top$url, fetch = TRUE), members[[r]])
  man <- man[order(man$file, method = "radix"), ]
  path <- file.path(out_dir, sprintf("%s_%s.csv", series, r))
  utils::write.csv(man, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  invisible(wet_logger_manifest(series, r))
  message("wrote ", path, ": ", nrow(top), " files, ", nrow(members[[r]]), " members")
}

# ---- 3. the private backup --------------------------------------------------------------------
if (identical(Sys.getenv("WET_BACKUP"), "1")) {
  aws <- function(...) {
    out <- suppressWarnings(system2("aws", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(out, "status"))) stop("aws ", paste(c(...), collapse = " "), ": ", paste(out, collapse = "\n"),
                                            call. = FALSE)
    out
  }
  for (i in seq_len(nrow(files))) {
    key <- sprintf("temp_loggers/%s/%s/%s", series, files$record[i], files$file[i])
    src <- file.path(cache_root, files$record[i], files$file[i])
    md5_file <- tempfile(fileext = ".md5")
    writeLines(sprintf("%s  %s", files$md5[i], files$file[i]), md5_file)
    b64 <- jsonlite::base64_enc(as.raw(strtoi(substring(files$md5[i], seq(1, 31, 2), seq(2, 32, 2)), 16L)))
    aws("s3api", "put-object", "--bucket", "fresh-bc", "--key", key, "--body", src, "--content-md5", b64)
    aws("s3api", "put-object", "--bucket", "fresh-bc", "--key", paste0(key, ".md5"), "--body", md5_file)
    head <- jsonlite::fromJSON(paste(aws("s3api", "head-object", "--bucket", "fresh-bc", "--key", key),
                                     collapse = "\n"))
    if (!isTRUE(head$ContentLength == files$bytes[i]) || !identical(gsub('"', "", head$ETag), files$md5[i])) {
      stop("the backup of ", key, " does not hold its size and md5", call. = FALSE)
    }
  }
  message("backed up to s3://fresh-bc/temp_loggers/", series, "/")
}

# ---- 4. the site registry ---------------------------------------------------------------------
meta_path <- file.path(ex, version, "02_SupplementaryMaterials.zip", "02_SupplementaryMaterials", "Site_Metadata.txt")
meta <- utils::read.delim(meta_path, colClasses = "character", fileEncoding = "latin1", check.names = FALSE)
stopifnot(identical(names(meta), c("Station Code", "Site Name", "Latitude", "Longitude", "Elevation (m)",
                                   "Record Start", "Record End")))
# each name ends in a stray non-breaking space, and 01FW017's also in an asterisk neither the ReadMe nor
# its site PDF explains
meta$name <- trimws(gsub("[*\u00a0]", "", meta$`Site Name`))
s <- data.frame(code = meta$`Station Code`, name = meta$name, lon = as.numeric(meta$Longitude),
                lat = as.numeric(meta$Latitude), elevation_m = as.numeric(meta$`Elevation (m)`))
stopifnot(!anyNA(s), !anyDuplicated(s$code), grepl("^[0-9]{2}[A-Z]{2}[0-9]{3}$", s$code))
csv <- members[[version]]$file[grepl("^01_Data[.]zip/01_Data/", members[[version]]$file)]
s$member <- vapply(s$code, function(k) {
  m <- csv[startsWith(csv, paste0("01_Data.zip/01_Data/", k, "_"))]
  if (length(m) != 1L) stop("site ", k, " has ", length(m), " data files", call. = FALSE)
  m
}, "")
stopifnot(length(csv) == nrow(s))
s$station_number <- paste0(toupper(series), "_", s$code)

# the clock and the first and last day with a reading
reading_span <- function(p) {
  x <- utils::read.csv(p, colClasses = "character", check.names = FALSE)
  stopifnot(identical(names(x), c("station_code", "timestamp (UTC)", "wtmp (°C)", "wtmp_flag")))
  t <- as.POSIXct(x[[2]], format = "%Y-%m-%d %H:%M", tz = "UTC")
  stopifnot(!anyNA(t))
  ok <- !is.na(suppressWarnings(as.numeric(x[[3]])))
  as.Date(range(t[ok]), tz = "UTC")
}
span <- lapply(file.path(ex, version, s$member), reading_span)
s$first_reading <- as.Date(vapply(span, function(r) as.numeric(r[1]), 0), origin = "1970-01-01")
s$last_reading <- as.Date(vapply(span, function(r) as.numeric(r[2]), 0), origin = "1970-01-01")
s$clock_offset <- 0

# sub-drainage and day offset of the nearest HYDAT station
hy <- hydat_stations(wb_hydat(hydat_release))
nearest <- function(lon, lat, ref) {
  xr <- albers(ref$lon, ref$lat)
  xs <- albers(lon, lat)
  j <- vapply(seq_along(lon), function(i) which.min((xr[, 1] - xs[i, 1])^2 + (xr[, 2] - xs[i, 2])^2), 0L)
  list(id = ref$station_number[j], km = sqrt((xr[j, 1] - xs[, 1])^2 + (xr[j, 2] - xs[, 2])^2))
}
nh <- nearest(s$lon, s$lat, hy)
s$nearest_hydat <- nh$id
s$subdrainage <- substr(nh$id, 1, 3)
a <- tidyhydat::allstations
s$day_offset <- as.numeric(a$standard_offset[match(s$nearest_hydat, a$STATION_NUMBER)])
stopifnot(!anyNA(s$day_offset))

# the ECCC water temperature archive's stations
con <- DBI::dbConnect(duckdb::duckdb())
invisible(DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;"))
invisible(DBI::dbExecute(con, "CREATE SECRET wet_anon (TYPE s3, PROVIDER config, REGION 'us-west-2')"))
archive <- DBI::dbGetQuery(con, paste0("SELECT DISTINCT STATION_NUMBER s FROM read_parquet(",
                                       "'s3://water-temp-bc/data/canonical/Parameter=5/*.parquet') ORDER BY s"))$s
DBI::dbDisconnect(con, shutdown = TRUE)
message(length(archive), " stations in the ECCC water temperature archive")
bad <- s$station_number[grepl(wet_hydat_number, s$station_number) | s$station_number %in% archive]
if (length(bad)) stop("ids shaped like HYDAT's or held by the ECCC archive: ", paste(bad, collapse = ", "),
                      call. = FALSE)
eccc <- hy[hy$station_number %in% archive, ]
ne <- nearest(s$lon, s$lat, eccc)
s$nearest_eccc <- ne$id
s$eccc_km <- round(ne$km, 2)

# the earlier record's code and file for the same site
prior_csv <- members[[prior]]$file
dms <- function(d, m, sec) as.numeric(d) + as.numeric(m) / 60 + as.numeric(sec) / 3600
readme <- readLines(file.path(cache_root, prior, "NHG Data ReadMe.txt"), warn = FALSE, encoding = "UTF-8")
head_i <- grep("\\(([A-Z]{3})\\):\\s*$", readme)
pr <- data.frame(prior_name = sub("\\s*\\(([A-Z]{3})\\):\\s*$", "", readme[head_i]),
                 prior_code = sub(".*\\(([A-Z]{3})\\):\\s*$", "\\1", readme[head_i]))
coord <- regmatches(readme[head_i + 1], regexec(paste0("([0-9]+)\\D+([0-9]+)'\\s*([0-9.]+)\"\\s*N,\\s*",
                                                       "([0-9]+)\\D+([0-9]+)'\\s*([0-9.]+)\"\\s*W"),
                                                readme[head_i + 1]))
stopifnot(all(lengths(coord) == 7))
pr$lat <- vapply(coord, function(g) dms(g[2], g[3], g[4]), 0)
pr$lon <- -vapply(coord, function(g) dms(g[5], g[6], g[7]), 0)
stopifnot(setequal(pr$prior_code, names(prior_map)), nrow(pr) == length(prior_csv))
pr$code <- unname(prior_map[pr$prior_code])
pr$prior_member <- vapply(pr$prior_name, function(n) {
  m <- prior_csv[tolower(prior_csv) == tolower(paste0("Data.zip/Data/", n, ".csv"))]
  if (length(m) != 1L) stop("no single earlier file for ", n, call. = FALSE)
  m
}, "")
i <- match(pr$code, s$code)
stopifnot(!anyNA(i))
km <- sqrt(rowSums((albers(pr$lon, pr$lat) - albers(s$lon[i], s$lat[i]))^2))
far <- pr$prior_code[km > same_site_km]
if (!setequal(far, prior_far_ok)) {
  stop("earlier sites more than ", same_site_km, " km from their match: ",
       paste(sprintf("%s %.2f km", pr$prior_code[km > same_site_km], km[km > same_site_km]), collapse = ", "),
       call. = FALSE)
}
message(paste(sprintf("  %s (%s) = %s (%s), %.2f km", pr$prior_code, pr$prior_name, pr$code, s$name[i], km),
              collapse = "\n"))
s$prior_record <- ifelse(s$code %in% pr$code, prior, NA_character_)
s$prior_code <- pr$prior_code[match(s$code, pr$code)]
s$prior_member <- pr$prior_member[match(s$code, pr$code)]

reg <- data.frame(station_number = s$station_number, code = s$code, record = version, member = s$member,
                  name = s$name, lon = s$lon, lat = s$lat, elevation_m = s$elevation_m,
                  clock_offset = s$clock_offset, day_offset = s$day_offset, subdrainage = s$subdrainage,
                  nearest_hydat = s$nearest_hydat, nearest_eccc = s$nearest_eccc, eccc_km = s$eccc_km,
                  first_reading = s$first_reading, last_reading = s$last_reading, licence = licence,
                  credit = credit, prior_record = s$prior_record, prior_code = s$prior_code,
                  prior_member = s$prior_member)
reg <- reg[order(reg$station_number, method = "radix"), ]
reg_path <- file.path(out_dir, sprintf("%s_%s_sites.csv", series, version))
utils::write.csv(reg, reg_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
invisible(wet_logger_sites(series, version))
message("wrote ", reg_path, ": ", nrow(reg), " sites, ", sum(!is.na(reg$prior_code)), " also in record ", prior)
