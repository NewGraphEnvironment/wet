# The province's non-integrated discharge files: pin a snapshot, seed wet's cache, back it up (#142)
#
# Usage, from the package root:
#   WET_STATION_SOURCES_RAW=<dir holding the Discharge*.csv files> \
#     [WET_BCENV_SNAPSHOT=20261028] [WET_BACKUP=1] Rscript data-raw/station_sources_snapshot.R
#
# WET_STATION_SOURCES_RAW defaults to data/station_sources/raw/bcenv, where
# scripts/station_sources_probe.R (#123) left the survey's copy on 2026-10-28.
#
# 1. Holds the raw files to the md5s the survey report recorded
#    (data/checks/station_sources_20260717.txt) when the snapshot is the survey's;
#    a new snapshot has no earlier record to meet.
# 2. Writes the tracked manifest inst/extdata/station_sources/bcenv_<snapshot>.csv
#    (file, bytes, md5), which wet_bcenv() holds every cached copy to.
# 3. Seeds wet's cache, <cache>/station_sources/bcenv/<snapshot>/, each file
#    copied to a partial file and renamed into place once its md5 is the
#    manifest's.
# 4. With WET_BACKUP=1, copies each file and its .md5 to the private backup
#    s3://fresh-bc/station_sources/bcenv/<snapshot>/ (aws CLI) and checks each
#    object's size and recorded md5; the province rewrites Discharge.csv in
#    place, so this backup is the only other copy of what was read.
# 5. Writes the snapshot's station registry,
#    inst/extdata/station_sources/bcenv_<snapshot>_hydat.csv: one row per
#    provincial station (its latest name, status and coordinates in the files),
#    its first and last complete day as wet_bcenv_daily() reads them, its
#    regulation as far as its name says, and the HYDAT station at the same site
#    (scripts/station_sources_lib.R's hydat_match(), the survey's rule, against
#    HYDAT 20260717). wet_station_daily() and wet_station_list() read it.
#
# A new snapshot: download every Discharge*.csv the province's directory lists
# into a fresh directory, name it here, and run with WET_BACKUP=1.

devtools::load_all(quiet = TRUE)

snapshot <- Sys.getenv("WET_BCENV_SNAPSHOT", wet_bcenv_snapshot)
raw <- Sys.getenv("WET_STATION_SOURCES_RAW", file.path("data", "station_sources", "raw", "bcenv"))
if (!grepl("^[0-9]{8}$", snapshot)) stop("WET_BCENV_SNAPSHOT must be YYYYMMDD", call. = FALSE)
files <- sort(list.files(raw, pattern = "^Discharge[A-Za-z0-9_]*[.]csv$"), method = "radix")
if (!length(files)) stop("no Discharge*.csv files in ", raw, call. = FALSE)
invisible(wet:::wet_bcenv_order(files))  # every name must give its period
md5 <- unname(tools::md5sum(file.path(raw, files)))
man <- data.frame(file = files, bytes = file.size(file.path(raw, files)), md5 = md5)

# ---- 1. the survey's record -------------------------------------------------------------------
if (snapshot == "20261028") {
  rep <- readLines(file.path("data", "checks", "station_sources_20260717.txt"))
  rec <- regmatches(rep, regexec("^  ([0-9a-f]{32})  bcenv/(Discharge[A-Za-z0-9_]*[.]csv)$", rep))
  rec <- do.call(rbind, lapply(rec[lengths(rec) == 3], function(m) data.frame(file = m[3], md5 = m[2])))
  if (!setequal(rec$file, man$file) || !identical(rec$md5[match(man$file, rec$file)], man$md5)) {
    stop("the raw files in ", raw, " are not the ones the survey report recorded", call. = FALSE)
  }
  message("the ", nrow(man), " raw files match the survey report's md5s")
}

# ---- 2. the manifest --------------------------------------------------------------------------
out_dir <- file.path("inst", "extdata", "station_sources")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
man_path <- file.path(out_dir, sprintf("bcenv_%s.csv", snapshot))
utils::write.csv(man, man_path, row.names = FALSE, quote = FALSE)
message("wrote ", man_path)

# ---- 3. the cache -----------------------------------------------------------------------------
cache <- file.path(tools::R_user_dir("wet", "cache"), "station_sources", "bcenv", snapshot)
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
for (i in seq_len(nrow(man))) {
  dest <- file.path(cache, man$file[i])
  if (file.exists(dest) && identical(unname(tools::md5sum(dest)), man$md5[i])) next
  partial <- tempfile(paste0(".", man$file[i], ".partial-"), tmpdir = cache)
  if (!file.copy(file.path(raw, man$file[i]), partial)) stop("could not copy ", man$file[i], call. = FALSE)
  if (!identical(unname(tools::md5sum(partial)), man$md5[i])) {
    unlink(partial)
    stop("the copy of ", man$file[i], " does not match its md5", call. = FALSE)
  }
  if (!file.rename(partial, dest)) stop("could not move ", man$file[i], " into ", cache, call. = FALSE)
}
# read back through the reader's own check, from the installed manifest's twin in the source tree
stopifnot(length(wet:::wet_bcenv(snapshot)) == nrow(man))
message("cache ", cache, " holds the snapshot")

# ---- 4. the backup ----------------------------------------------------------------------------
if (identical(Sys.getenv("WET_BACKUP"), "1")) {
  bucket <- sprintf("s3://fresh-bc/station_sources/bcenv/%s/", snapshot)
  aws <- function(...) {
    out <- suppressWarnings(system2("aws", c(...), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(out, "status"))) stop("aws ", paste(c(...), collapse = " "), ": ", paste(out, collapse = "\n"),
                                            call. = FALSE)
    out
  }
  for (i in seq_len(nrow(man))) {
    src <- file.path(cache, man$file[i])
    md5_file <- tempfile(fileext = ".md5")
    writeLines(sprintf("%s  %s", man$md5[i], man$file[i]), md5_file)
    aws("s3", "cp", "--only-show-errors", src, paste0(bucket, man$file[i]), "--metadata", paste0("md5=", man$md5[i]))
    aws("s3", "cp", "--only-show-errors", md5_file, paste0(bucket, man$file[i], ".md5"))
    head <- jsonlite::fromJSON(paste(aws("s3api", "head-object", "--bucket", "fresh-bc", "--key",
                                         sprintf("station_sources/bcenv/%s/%s", snapshot, man$file[i])),
                                     collapse = "\n"))
    if (!isTRUE(head$ContentLength == man$bytes[i]) || !identical(head$Metadata$md5, man$md5[i])) {
      stop("the backup of ", man$file[i], " does not hold its size and md5", call. = FALSE)
    }
  }
  message("backed up to ", bucket)
}

# ---- 5. the station registry ------------------------------------------------------------------
source("scripts/wb_fit_lib.R")     # wb_hydat()
source("scripts/station_sources_lib.R")
hy <- hydat_stations(wb_hydat("20260717"))
duck <- DBI::dbConnect(duckdb::duckdb())
wet:::wet_bcenv_hours(duck, wet:::wet_bcenv(snapshot))
st <- DBI::dbGetQuery(duck, "
  SELECT id AS station_number, arg_max(name, t) AS name, arg_max(status, t) AS status,
         arg_max(lon, t) AS lon, arg_max(lat, t) AS lat
  FROM h GROUP BY 1 ORDER BY 1")
DBI::dbDisconnect(duck, shutdown = TRUE)
st <- st[order(st$station_number, method = "radix"), ]
q <- wet:::wet_bcenv_daily(NULL, snapshot)
rng <- lapply(split(q$date, q$station_number), range)
st$first <- as.Date(vapply(st$station_number, function(s) if (is.null(rng[[s]])) NA_real_ else as.numeric(rng[[s]][1]),
                           0), origin = "1970-01-01")
st$last <- as.Date(vapply(st$station_number, function(s) if (is.null(rng[[s]])) NA_real_ else as.numeric(rng[[s]][2]),
                          0), origin = "1970-01-01")
st$regulation <- ifelse(regulation_of(st$name) == "unknown", "unknown", "regulated by name")
m <- hydat_match(data.frame(station_id = st$station_number, name = st$name, lon = st$lon, lat = st$lat,
                            first = as.integer(format(st$first, "%Y")), last = as.integer(format(st$last, "%Y"))), hy)
stopifnot(identical(m$station_id, st$station_number))
st$hydat_site <- m$hydat
st$hydat_km <- m$hydat_km
st$hydat_class <- m$class
reg_path <- file.path(out_dir, sprintf("bcenv_%s_hydat.csv", snapshot))
utils::write.csv(st, reg_path, row.names = FALSE, na = "")
message("wrote ", reg_path, ": ", nrow(st), " stations, ", sum(!is.na(st$first)), " with a complete day, ",
        sum(!is.na(st$hydat_site)), " at a HYDAT site")
