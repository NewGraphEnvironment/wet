# Hakai Institute's discharge package: pin a version, seed wet's cache, back it up,
# write the station registry (#192)
#
# Usage, from the package root:
#   [WET_HAKAI_RAW=<absolute path to a dir holding 2013-2019_Discharge_Hourly.csv>] \
#     [WET_BACKUP=1] Rscript data-raw/station_sources_hakai.R
#
# The package (Korver, Haughton, Floyd and Giesbrecht, DOI 10.21966/J99C-9C14,
# CC-BY 4.0) is the GitHub repository HakaiInstitute/essd2021-hydromet-datapackage;
# its data files are Git LFS objects, served at
# https://media.githubusercontent.com/media/HakaiInstitute/essd2021-hydromet-datapackage/<commit>/<file>
# (that host serves no robots.txt; github.com's own robots.txt disallows its
# /raw/ paths, which this does not use). Anyone can fetch the same file and tell
# it is the pinned one by its md5.
#
# 1. Takes the hourly discharge file from WET_HAKAI_RAW, or fetches it from the
#    pinned commit, and holds it to the LFS pointer's sha256 at that commit.
# 2. Writes the tracked manifest inst/extdata/station_sources/hakai_<version>.csv
#    (file, bytes, md5, url), which wet_hakai() holds every cached copy to.
# 3. Seeds wet's cache, <cache>/station_sources/hakai/<version>/.
# 4. With WET_BACKUP=1, puts the file and its .md5 in the private backup
#    s3://fresh-bc/station_sources/hakai/<version>/ (aws CLI), one PUT with its
#    Content-MD5, and checks the object's size and ETag.
# 5. Writes the station registry inst/extdata/station_sources/hakai_<version>_hydat.csv:
#    the package's watersheds 626, 703 and 844 (decision 6 in #210 leaves out
#    693, 708, 819 and 1015), each continuing the provincial station whose
#    number ends in its watershed number (H08KC0626, ...), refused unless the
#    provincial registry holds that number, its name names the watershed, and
#    the package's coordinates (README_Hakai_Discharge.pdf, Table 1, the stage
#    monitoring device) lie within the survey's same-site 0.5 km of the
#    provincial station's. `continues_before` is the first day the provincial
#    files hold any usable hour of the station, complete or not, as for the
#    Water Tool's continuing listings; `first` and `last` are the days the
#    package adds before it under the shipped rules (wet_hakai_shape()).
#    Refused: a number shaped like HYDAT's or held by the provincial or Water
#    Tool registry, and a provincial station the Water Tool already continues.
#    wet_station_daily() and wet_station_list() read the registry only beside
#    the provincial snapshot and reader it was built against (`bcenv_snapshot`,
#    `bcenv_days`): a new provincial pin or a bump of wet_bcenv_reader
#    rewrites it.

devtools::load_all(quiet = TRUE)
source("scripts/station_sources_lib.R")  # for albers

commit <- "8318556d2baf2b3216779c8abe424fbd6f00107d"
version <- substr(commit, 1, 12)
stopifnot(identical(version, wet_hakai_version))
file <- "2013-2019_Discharge_Hourly.csv"
lfs_sha256 <- "dbee8370c585ade4f42a66a274d1afb0c56ab6a1cb3a1f1bbad62aec84c998a1"
url <- sprintf("https://media.githubusercontent.com/media/HakaiInstitute/essd2021-hydromet-datapackage/%s/%s",
               commit, file)
watersheds <- data.frame(
  station_number = c("WTS626", "WTS703", "WTS844"), watershed = c("626", "703", "844"),
  # README_Hakai_Discharge.pdf, Table 1: the stage monitoring device (pressure transducer)
  lat = c(51.64111, 51.64661, 51.66083), lon = c(-128.12056, -128.02572, -128.00250))
licence <- "CC-BY 4.0"
credit <- paste("Hakai Institute, Maartje Korver, Emily Haughton, Bill Floyd and Ian Giesbrecht:",
                "High-resolution hydrometeorological data from seven small coastal watersheds, British Columbia,",
                "Canada, 2013-2019 (CC-BY 4.0), https://doi.org/10.21966/J99C-9C14")
same_site_km <- 0.5
snapshot <- wet_bcenv_snapshot

# ---- 1. the file ------------------------------------------------------------------------------
raw <- Sys.getenv("WET_HAKAI_RAW")
src <- if (nzchar(raw)) {
  if (!grepl("^/", raw)) stop("WET_HAKAI_RAW must be an absolute path", call. = FALSE)
  file.path(raw, file)
} else {
  f <- tempfile(fileext = ".csv")
  curl::curl_download(url, f, quiet = TRUE)
  f
}
sha <- strsplit(system2("shasum", c("-a", "256", shQuote(src)), stdout = TRUE), " ")[[1]][1]
if (!identical(sha, lfs_sha256)) stop(src, " is not the pinned package file (sha256 ", sha, ")", call. = FALSE)
message("the discharge file matches the LFS pointer's sha256 at commit ", version)

# ---- 2. the manifest --------------------------------------------------------------------------
out_dir <- file.path("inst", "extdata", "station_sources")
man <- data.frame(file = file, bytes = file.size(src), md5 = unname(tools::md5sum(src)), url = url)
man_path <- file.path(out_dir, sprintf("hakai_%s.csv", version))
utils::write.csv(man, man_path, row.names = FALSE)
message("wrote ", man_path)

# ---- 3. the cache -----------------------------------------------------------------------------
cache <- file.path(tools::R_user_dir("wet", "cache"), "station_sources", "hakai", version)
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
dest <- file.path(cache, file)
if (!file.exists(dest) || !identical(unname(tools::md5sum(dest)), man$md5)) {
  partial <- tempfile(paste0(".", file, ".partial-"), tmpdir = cache)
  if (!file.copy(src, partial)) stop("could not copy ", src, " into ", cache, call. = FALSE)
  if (!identical(unname(tools::md5sum(partial)), man$md5)) stop("the copy does not match its md5", call. = FALSE)
  if (!file.rename(partial, dest)) stop("could not move the copy into ", cache, call. = FALSE)
}
message("seeded ", cache)

# ---- 4. the private backup --------------------------------------------------------------------
if (identical(Sys.getenv("WET_BACKUP"), "1")) {
  bucket <- sprintf("s3://fresh-bc/station_sources/hakai/%s/", version)
  aws <- function(...) {
    out <- suppressWarnings(system2("aws", c(...), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(out, "status"))) stop("aws ", paste(c(...), collapse = " "), ": ", paste(out, collapse = "\n"),
                                            call. = FALSE)
    out
  }
  key <- sprintf("station_sources/hakai/%s/%s", version, file)
  md5_file <- tempfile(fileext = ".md5")
  writeLines(sprintf("%s  %s", man$md5, file), md5_file)
  b64 <- jsonlite::base64_enc(as.raw(strtoi(substring(man$md5, seq(1, 31, 2), seq(2, 32, 2)), 16L)))
  aws("s3api", "put-object", "--bucket", "fresh-bc", "--key", key, "--body", dest, "--content-md5", b64)
  aws("s3", "cp", "--only-show-errors", md5_file, paste0(bucket, file, ".md5"))
  head <- jsonlite::fromJSON(paste(aws("s3api", "head-object", "--bucket", "fresh-bc", "--key", key),
                                   collapse = "\n"))
  if (!isTRUE(head$ContentLength == man$bytes) || !identical(gsub('"', "", head$ETag), man$md5)) {
    stop("the backup of ", file, " does not hold its size and md5", call. = FALSE)
  }
  message("backed up to ", bucket)
}

# ---- 5. the station registry ------------------------------------------------------------------
prov <- wet_bcenv_stations(snapshot)
tool <- wet_bcwatertool_stations()
watersheds$continues <- sprintf("H08KC%04d", as.integer(watersheds$watershed))
i <- match(watersheds$continues, prov$station_number)
if (anyNA(i)) stop("the provincial registry lacks ", paste(watersheds$continues[is.na(i)], collapse = ", "),
                   call. = FALSE)
named <- mapply(function(n, w) grepl(paste0("Watershed ", w, "$"), n), prov$name[i], watersheds$watershed)
if (!all(named)) stop("a provincial name does not name its watershed: ", paste(prov$name[i][!named], collapse = "; "),
                      call. = FALSE)
xy_h <- albers(watersheds$lon, watersheds$lat)
xy_p <- albers(prov$lon[i], prov$lat[i])
km <- sqrt(rowSums((xy_h - xy_p)^2))
if (any(km > same_site_km)) {
  stop("a package watershed lies more than ", same_site_km, " km from its provincial station: ",
       paste(sprintf("%s %.3f km", watersheds$station_number[km > same_site_km], km[km > same_site_km]),
             collapse = ", "), call. = FALSE)
}
message(paste(sprintf("  %s continues %s (%s), %.3f km apart", watersheds$station_number, watersheds$continues,
                      prov$name[i], km), collapse = "\n"))
watersheds$name <- prov$name[i]
taken <- intersect(watersheds$continues, stats::na.omit(tool$continues))
if (length(taken)) stop("the Water Tool already continues ", paste(taken, collapse = ", "), call. = FALSE)
bad <- watersheds$station_number[grepl(wet_hydat_number, watersheds$station_number) |
                                   watersheds$station_number %in% c(prov$station_number, tool$station_number)]
if (length(bad)) stop("registry numbers shaped like HYDAT's or held by another registry: ",
                      paste(bad, collapse = ", "), call. = FALSE)

# the cut: the first day the provincial files hold any usable hour of the station
pdays <- wet_bcenv_days_read(wet_bcenv_days(snapshot, tools::R_user_dir("wet", "cache")), watersheds$continues)
pstart <- vapply(split(as.numeric(pdays$date), pdays$station_number), min, 0)
watersheds$continues_before <- as.Date(unname(pstart[watersheds$continues]), origin = "1970-01-01")

# the days the package adds, under the shipped rules
shipped <- wet_hakai_shape(wet_hakai_days(wet_hakai_hours(dest, watersheds$station_number)))
cut <- watersheds$continues_before[match(shipped$station_number, watersheds$station_number)]
shipped <- shipped[is.na(cut) | shipped$date < cut, ]
rng <- lapply(split(shipped$date, shipped$station_number), range)
day <- function(k) as.Date(vapply(watersheds$station_number, function(s) {
  if (is.null(rng[[s]])) NA_real_ else as.numeric(rng[[s]][k])
}, 0), origin = "1970-01-01")
watersheds$first <- day(1)
watersheds$last <- day(2)

reg <- data.frame(station_number = watersheds$station_number, watershed = watersheds$watershed,
                  name = watersheds$name, lon = watersheds$lon, lat = watersheds$lat,
                  continues = watersheds$continues, continues_before = watersheds$continues_before,
                  first = watersheds$first, last = watersheds$last, licence = licence, credit = credit,
                  bcenv_snapshot = snapshot, bcenv_days = wet_bcenv_days_key(snapshot))
reg <- reg[order(reg$station_number, method = "radix"), ]
reg_path <- file.path(out_dir, sprintf("hakai_%s_hydat.csv", version))
utils::write.csv(reg, reg_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
message("wrote ", reg_path, ": ", nrow(reg), " watersheds, each continuing a provincial station")
