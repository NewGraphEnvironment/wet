# The BC Water Tool's third-party gauges: pin a snapshot, seed wet's cache, back it up,
# write the station registry (#144, #195)
#
# Usage, from the package root:
#   WET_BCWATERTOOL_RAW=<absolute path to the dir holding the station list and bcwatertool/> \
#     [WET_BACKUP=1] Rscript data-raw/station_sources_bcwatertool.R
#
# How the snapshot was fetched. The survey (scripts/station_sources_probe.R,
# #123, 2026-10-28) read the Tool's station list,
# https://nr-bcwat.bcwatertool.ca/api/streamflow/stations, into
# bcwatertool_streamflow_stations_20261028.geojson, kept the listings with a
# record outside Water Survey of Canada (one per `nid`, the lowest `id`), and
# read each one's daily values,
# https://nr-bcwat.bcwatertool.ca/api/streamflow/stations/<id>/csv, into
# bcwatertool/<id>.csv, or bcwatertool/<id>.csv.status where the API answered
# an HTTP error, under data/station_sources/raw/. The survey report
# (data/checks/station_sources_20260717.txt) records the list's md5 and the md5
# of the md5 list over the 391 entries. The Tool serves only its current
# values, so anyone can fetch a snapshot of their own the same way and tell it
# from the pinned one by the manifest's md5s; it is not the pinned one, and a
# new pin is a new snapshot date here.
#
# 1. Holds the station list and the 391 entries to the survey report's two md5s.
# 2. Writes the tracked manifest inst/extdata/station_sources/bcwatertool_<snapshot>.csv
#    (file, bytes, md5: the list and every entry), which wet_bcwatertool()
#    holds every cached copy to.
# 3. Seeds wet's cache, <cache>/station_sources/bcwatertool/<snapshot>/, with
#    every file, each copied to a partial file and renamed into place once its
#    md5 is the manifest's.
# 4. With WET_BACKUP=1, puts every file and its .md5 in the private backup
#    s3://fresh-bc/station_sources/bcwatertool/<snapshot>/ (aws CLI), each as one
#    PUT with its Content-MD5, and checks each object's size and ETag. The
#    owner chose to back up all 391 entries (#195, decision 4), the Tool's copy
#    of the provincial stations among them, which #190's comparison reads.
#    One file, Fisheries and Oceans' 19197.csv, states "personal and public
#    non-commercial use only"; the backup is private and nothing republishes it.
# 5. Writes the station registry,
#    inst/extdata/station_sources/bcwatertool_<snapshot>_hydat.csv: the
#    listings wet reads, by this rule, each step's count reported:
#    a. as the survey: a record (`yr` non-empty), not Water Survey of Canada,
#       one listing per `nid` (the lowest `id`);
#    b. not the Tool's copy of a provincial station: not the network
#       "BC ENV - Real-time Water Data Reporting", and no `nid` the provincial
#       registry (bcenv_<snapshot>_hydat.csv) holds;
#    c. a CSV holding a "Preliminary Discharge" series;
#    d. a listing at a provincial station's site (within 0.5 km and the same
#       stream name, the survey's rule) continues that station
#       (`continues`, the provincial number; #195, decision 1) rather than
#       being a station of its own: its days before `continues_before`, the
#       first day the provincial files hold any usable hour of that station
#       (complete or not), are read under the provincial number, and its
#       `first` and `last` are those days' (NA where it adds none).
#    Per listing: name, network and coordinates from the station list; the
#    WSC sub-drainage of the nearest HYDAT station, which picks its
#    plausibility bound (research/station_sources.md, registered 2026-11-23),
#    with that station and its distance; its first and last days under the
#    shipped rules (wet_bcwatertool_shape()); regulation as far as its name
#    says; the HYDAT station at the same site (scripts/station_sources_lib.R's
#    hydat_match(), the survey's rule, against HYDAT 20260717); and its credit,
#    the CSV header's licence line up to its liability disclaimer.
#    wet_station_daily() and wet_station_list() read it. It refuses a number
#    shaped like HYDAT's or held by the provincial registry.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")     # wb_hydat()
source("scripts/station_sources_lib.R")

snapshot <- wet_bcwatertool_snapshot
raw <- Sys.getenv("WET_BCWATERTOOL_RAW")
if (!nzchar(raw) || !grepl("^/", raw)) {
  stop("WET_BCWATERTOOL_RAW must name, as an absolute path, the dir holding the survey's station list and ",
       "bcwatertool/", call. = FALSE)
}
list_file <- wet_bcwatertool_list_file(snapshot)
entries <- sort(list.files(file.path(raw, "bcwatertool"), pattern = "^[0-9]+[.]csv([.]status)?$"), method = "radix")
if (!length(entries)) stop("no Water Tool entries in ", file.path(raw, "bcwatertool"), call. = FALSE)
src <- c(file.path(raw, list_file), file.path(raw, "bcwatertool", entries))
man <- data.frame(file = c(list_file, entries), bytes = file.size(src), md5 = unname(tools::md5sum(src)))
man <- man[order(man$file, method = "radix"), ]
src <- src[match(man$file, c(list_file, entries))]

# ---- 1. the survey's record -------------------------------------------------------------------
rep <- readLines(file.path("data", "checks", "station_sources_20260717.txt"))
rec_list <- sub("^  ([0-9a-f]{32})  .*$", "\\1", grep(paste0("^  [0-9a-f]{32}  ", list_file, "$"), rep, value = TRUE))
rec_md5s <- sub("^.*md5 of their md5 list ([0-9a-f]{32})$", "\\1",
                grep("^  bcwatertool/: md5 of their md5 list [0-9a-f]{32}$", rep, value = TRUE))
if (length(rec_list) != 1 || length(rec_md5s) != 1) stop("the survey report lacks its Water Tool md5s", call. = FALSE)
if (!identical(man$md5[man$file == list_file], rec_list)) {
  stop("the station list in ", raw, " is not the one the survey report recorded", call. = FALSE)
}
tf <- tempfile()
e <- man[man$file != list_file, ]
writeLines(paste(e$md5, paste0("bcwatertool/", e$file)), tf)
if (!identical(unname(tools::md5sum(tf)), rec_md5s)) {
  stop("the entries in ", file.path(raw, "bcwatertool"), " are not the ones the survey report recorded", call. = FALSE)
}
unlink(tf)
message("the station list and ", nrow(e), " entries match the survey report's md5s")

# ---- 2. the manifest --------------------------------------------------------------------------
out_dir <- file.path("inst", "extdata", "station_sources")
man_path <- file.path(out_dir, sprintf("bcwatertool_%s.csv", snapshot))
utils::write.csv(man, man_path, row.names = FALSE, quote = FALSE)
message("wrote ", man_path)

# ---- 3. the cache -----------------------------------------------------------------------------
cache <- file.path(tools::R_user_dir("wet", "cache"), "station_sources", "bcwatertool", snapshot)
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
for (i in seq_len(nrow(man))) {
  dest <- file.path(cache, man$file[i])
  if (file.exists(dest) && identical(unname(tools::md5sum(dest)), man$md5[i])) next
  partial <- tempfile(paste0(".", man$file[i], ".partial-"), tmpdir = cache)
  if (!file.copy(src[i], partial)) stop("could not copy ", man$file[i], call. = FALSE)
  if (!identical(unname(tools::md5sum(partial)), man$md5[i])) {
    unlink(partial)
    stop("the copy of ", man$file[i], " does not match its md5", call. = FALSE)
  }
  if (!file.rename(partial, dest)) stop("could not move ", man$file[i], " into ", cache, call. = FALSE)
}
# read back through the reader's own check
ids <- sub("[.]csv([.]status)?$", "", e$file)
stopifnot(length(wet:::wet_bcwatertool(ids, snapshot)) == length(ids))
message("cache ", cache, " holds the snapshot")

# ---- 4. the backup ----------------------------------------------------------------------------
if (identical(Sys.getenv("WET_BACKUP"), "1")) {
  bucket <- sprintf("s3://fresh-bc/station_sources/bcwatertool/%s/", snapshot)
  aws <- function(...) {
    out <- suppressWarnings(system2("aws", c(...), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(out, "status"))) stop("aws ", paste(c(...), collapse = " "), ": ", paste(out, collapse = "\n"),
                                            call. = FALSE)
    out
  }
  for (i in seq_len(nrow(man))) {
    f <- file.path(cache, man$file[i])
    md5_file <- tempfile(fileext = ".md5")
    writeLines(sprintf("%s  %s", man$md5[i], man$file[i]), md5_file)
    key <- sprintf("station_sources/bcwatertool/%s/%s", snapshot, man$file[i])
    b64 <- jsonlite::base64_enc(as.raw(strtoi(substring(man$md5[i], seq(1, 31, 2), seq(2, 32, 2)), 16L)))
    aws("s3api", "put-object", "--bucket", "fresh-bc", "--key", key, "--body", f, "--content-md5", b64)
    aws("s3", "cp", "--only-show-errors", md5_file, paste0(bucket, man$file[i], ".md5"))
    unlink(md5_file)
    head <- jsonlite::fromJSON(paste(aws("s3api", "head-object", "--bucket", "fresh-bc", "--key", key),
                                     collapse = "\n"))
    if (!isTRUE(head$ContentLength == man$bytes[i]) || !identical(gsub('"', "", head$ETag), man$md5[i])) {
      stop("the backup of ", man$file[i], " does not hold its size and md5", call. = FALSE)
    }
  }
  message("backed up ", nrow(man), " files to ", bucket)
}

# ---- 5. the station registry ------------------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a)) b else a
feat <- jsonlite::fromJSON(file.path(cache, list_file), simplifyVector = FALSE)$features
wt <- do.call(rbind, lapply(feat, function(f) {
  p <- f$properties
  data.frame(id = as.character(p$id), nid = p$nid %||% NA_character_, name = p$name, net = p$net,
             n_yr = length(p$yr), lon = f$geometry$coordinates[[1]], lat = f$geometry$coordinates[[2]])
}))
count <- function(step, x) message(sprintf("  %-72s %4d", step, nrow(x)))
message("Water Tool listings, step by step:")
count("in the station list", wt)
wt <- wt[wt$n_yr > 0 & wt$net != "Water Survey of Canada", ]
count("a. with a record, not Water Survey of Canada", wt)
wt <- wt[order(wt$nid, as.integer(wt$id), method = "radix"), ]
dup <- wt[duplicated(wt$nid), ]
wt <- wt[!duplicated(wt$nid), ]
count("a. one per nid", wt)
for (i in seq_len(nrow(dup))) message(sprintf("     left out behind its nid's first listing: %s (id %s, %s)",
                                              dup$nid[i], dup$id[i], dup$net[i]))
prov <- wet_bcenv_stations(wet_bcenv_snapshot)
benv <- wt$net == "BC ENV - Real-time Water Data Reporting"
copy <- !benv & wt$nid %in% prov$station_number
wt <- wt[!benv & !copy, ]
message(sprintf("     left out: %d BC ENV listings, %d provincial stations under another network",
                sum(benv), sum(copy)))
count("b. third-party", wt)
read <- lapply(wt$id, function(id) {
  p <- wet:::wet_bcwatertool(id, snapshot)
  if (is.na(p)) NULL else wet:::wet_bcwatertool_read(p, id)
})
has_q <- vapply(read, function(r) !is.null(r) && nrow(r$q) > 0, FALSE)
stage <- wt[!has_q, ]
wt <- wt[has_q, ]
read <- read[has_q]
count("c. with a discharge series", wt)
message(sprintf("     left out without discharge: %d (%s)", nrow(stage),
                paste(sprintf("%s %d", names(table(stage$net)), table(stage$net)), collapse = "; ")))

# d. at a provincial station's site: within 0.5 km on the same stream, the survey's same-site rule
same_site_km <- 0.5
xy_t <- albers(wt$lon, wt$lat)
xy_p <- albers(prov$lon, prov$lat)
s_t <- stream_of(wt$name)
s_p <- stream_of(prov$name)
wt$continues <- vapply(seq_len(nrow(wt)), function(i) {
  d <- sqrt((xy_p[, 1] - xy_t[i, 1])^2 + (xy_p[, 2] - xy_t[i, 2])^2)
  j <- which(d <= same_site_km & s_p == s_t[i])
  if (length(j) > 1) stop("Water Tool listing ", wt$nid[i], " sits at two provincial sites", call. = FALSE)
  if (length(j)) prov$station_number[j] else NA_character_
}, "")
if (anyDuplicated(stats::na.omit(wt$continues))) stop("two Water Tool listings continue one provincial station",
                                                      call. = FALSE)
count("d. stations of their own", wt[is.na(wt$continues), ])
count("d. continuing a provincial station's record", wt[!is.na(wt$continues), ])
for (i in which(!is.na(wt$continues))) {
  message(sprintf("     %s (%s) continues %s (%s)", wt$nid[i], wt$name[i], wt$continues[i],
                  prov$name[prov$station_number == wt$continues[i]]))
}

# sub-drainage, from the nearest HYDAT station
hy <- hydat_stations(wb_hydat("20260717"))
xy_h <- albers(hy$lon, hy$lat)
xy_t <- albers(wt$lon, wt$lat)
near <- vapply(seq_len(nrow(wt)), function(i) {
  d <- sqrt((xy_h[, 1] - xy_t[i, 1])^2 + (xy_h[, 2] - xy_t[i, 2])^2)
  j <- which.min(d)
  c(hy$station_number[j], sprintf("%.2f", d[j]))
}, c("", ""))
wt$nearest_hydat <- near[1, ]
wt$nearest_km <- as.numeric(near[2, ])
wt$subdrainage <- substr(wt$nearest_hydat, 1, 3)

# the chain's cut: the first day the provincial files hold any usable hour of the continued station,
# a complete day or not, so a listing that is the same gauge adds none of the province's own partial days
pdays <- wet:::wet_bcenv_days_read(wet:::wet_bcenv_days(wet_bcenv_snapshot, tools::R_user_dir("wet", "cache")),
                                   stats::na.omit(wt$continues))
pstart <- vapply(split(as.numeric(pdays$date), pdays$station_number), min, 0)
wt$continues_before <- as.Date(unname(pstart[wt$continues]), origin = "1970-01-01")

# days under the shipped rules, for first and last; a continuing listing's are the days the chain adds
q <- do.call(rbind, lapply(read, function(r) r$q))
q$station_number <- wt$nid[match(q$id, wt$id)]
shipped <- wet:::wet_bcwatertool_shape(q, stats::setNames(wt$subdrainage, wt$nid), wet_bcenv_bound)
cut <- wt$continues_before[match(shipped$station_number, wt$nid)]
shipped <- shipped[is.na(wt$continues[match(shipped$station_number, wt$nid)]) | is.na(cut) | shipped$date < cut, ]
rng <- lapply(split(shipped$date, shipped$station_number), range)
day <- function(k) as.Date(vapply(wt$nid, function(s) if (is.null(rng[[s]])) NA_real_ else as.numeric(rng[[s]][k]), 0),
                           origin = "1970-01-01")
wt$first <- day(1)
wt$last <- day(2)

m <- hydat_match(data.frame(station_id = wt$nid, name = wt$name, lon = wt$lon, lat = wt$lat,
                            first = as.integer(format(wt$first, "%Y")), last = as.integer(format(wt$last, "%Y"))), hy)
stopifnot(identical(m$station_id, wt$nid))
reg <- data.frame(station_number = wt$nid, id = wt$id, name = wt$name, network = wt$net, lon = wt$lon, lat = wt$lat,
                  subdrainage = wt$subdrainage, nearest_hydat = wt$nearest_hydat, nearest_km = wt$nearest_km,
                  first = wt$first, last = wt$last,
                  regulation = ifelse(regulation_of(wt$name) == "unknown", "unknown", "regulated by name"),
                  hydat_site = m$hydat, hydat_km = m$hydat_km,
                  credit = vapply(read, function(r) wet:::wet_bcwatertool_credit(r$meta), ""),
                  continues = wt$continues, continues_before = wt$continues_before)
reg <- reg[order(reg$station_number, method = "radix"), ]
bad <- reg$station_number[grepl(wet:::wet_hydat_number, reg$station_number) |
                            reg$station_number %in% prov$station_number]
if (length(bad)) stop("registry numbers shaped like HYDAT's or held by the provincial registry: ",
                      paste(bad, collapse = ", "), call. = FALSE)
if (anyNA(reg$credit)) stop("a Water Tool listing states no licence line: ",
                            paste(reg$station_number[is.na(reg$credit)], collapse = ", "), call. = FALSE)
reg_path <- file.path(out_dir, sprintf("bcwatertool_%s_hydat.csv", snapshot))
utils::write.csv(reg, reg_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
message("wrote ", reg_path, ": ", nrow(reg), " listings, ", sum(is.na(reg$continues)), " stations of their own, ",
        sum(!is.na(reg$continues)), " continuing a provincial station; ", sum(!is.na(reg$hydat_site)),
        " at a HYDAT site")
