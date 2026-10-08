# Gauge side in the dry interior (#53): flag the shipped fit's calibration
# gauges whose basins hold licensed surface-water diversions or storage, and
# rescore the held-out predictions without them, under the rule pre-registered
# in the #53 findings before any licence was joined to a gauge.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/wb_gauge_diversion.R
#
# HYDAT's regulation flag cannot do this: wet_station_select() keeps only
# REGULATED = 0, so every calibration gauge is already "natural" to HYDAT.
# Stages, cached under data/gauge_div/ (gitignored):
#   1. raw snapshots of BC water rights licences (points of diversion) and BC
#      dams, downloaded once and kept (their md5 is in the report). Licensee
#      names and addresses are not requested;
#   2. each point placed in an FWA fundamental watershed, and upstream of each
#      calibration gauge (whse_basemapping.fwa_upstream(); points in the
#      gauge's own polygon by stream position);
#   3. per gauge: licensed consumptive depth and storage, the flags;
#   4. the rescore and the verdict.
# Report: data/checks/wb_gauge_diversion_<release>.txt (tracked, wb_report()). Connection from WET_PG*.

stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
out_dir <- file.path("data", "gauge_div")
raw_dir <- file.path(out_dir, "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# a cache is renamed into place only once complete, so a killed run leaves none
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".part")
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
}

# ---- 1. raw snapshots ----------------------------------------------------------------------
# The BC WFS caps an un-paged GetFeature at 10,000 features and still answers
# 200, so each layer is paged in a stable order and held to the server's own
# count, recorded when the snapshot was taken.
wfs <- "https://openmaps.gov.bc.ca/geo/pub/wfs?service=WFS&version=2.0.0&typeName=pub:WHSE_WATER_MANAGEMENT."
layers <- list(
  licences = list(name = "WLS_WATER_RIGHTS_LICENCES_SV", sort = "WLS_WRL_SYSID", geom = "SHAPE",
                  fields = c("WLS_WRL_SYSID", "POD_NUMBER", "POD_SUBTYPE", "POD_DIVERSION_TYPE", "POD_STATUS",
                             "LICENCE_NUMBER", "LICENCE_STATUS", "LICENCE_STATUS_DATE", "PRIORITY_DATE", "PURPOSE_USE_CODE",
                             "PURPOSE_USE", "SOURCE_NAME", "REDIVERSION_IND", "QUANTITY", "QUANTITY_UNITS",
                             "QUANTITY_FLAG", "QUANTITY_FLAG_DESCRIPTION", "HYDRAULIC_CONNECTIVITY")),
  dams = list(name = "WRIS_DAMS_PUBLIC_SVW", sort = "WRIS_DP_SYSID", geom = "GEOMETRY",
              fields = c("WRIS_DP_SYSID", "DAM_FILE_NUMBER", "DAM_NAME", "COMMISSIONED_YEAR", "DAM_FUNCTION",
                         "DAM_REGULATED_CODE", "DAM_OPERATION_CODE", "DAM_TYPE", "DAM_HEIGHT"))
)
page_size <- 10000
snapshot <- function(k) {
  l <- layers[[k]]
  f_hits <- file.path(raw_dir, paste0(k, "_hits.txt"))
  if (!file.exists(f_hits)) {
    tmp <- tempfile(fileext = ".xml")
    wet:::wet_download(paste0(wfs, l$name, "&request=GetFeature&resultType=hits"), tmp, 300)
    n <- as.integer(sub('.*numberMatched="([0-9]+)".*', "\\1", paste(readLines(tmp, warn = FALSE), collapse = "")))
    stopifnot(!is.na(n), n > 0)
    writeLines(as.character(n), paste0(f_hits, ".part"))
    file.rename(paste0(f_hits, ".part"), f_hits)
  }
  n <- as.integer(readLines(f_hits))
  pages <- seq(0, n - 1, by = page_size)
  f <- file.path(raw_dir, sprintf("%s_%02d.csv", k, seq_along(pages)))
  # Each page must start after the previous one ends (a malformed startIndex,
  # such as paste0()'s "1e+05", is answered with the first page); a page that
  # does not is fetched again.
  ids <- function(p) as.numeric(utils::read.csv(p, colClasses = "character")[[l$sort]])
  last <- -Inf
  for (i in seq_along(pages)) {
    for (try in 1:3) {
      if (!file.exists(f[i])) {
        stamp("downloading ", k, " page ", i, " of ", length(pages))
        wet:::wet_download(paste0(wfs, l$name, "&request=GetFeature&outputFormat=csv&srsName=EPSG:3005",
                                  "&sortBy=", l$sort, "&count=", page_size, "&startIndex=", sprintf("%d", as.integer(pages[i])),
                                  "&propertyName=", paste(c(l$fields, l$geom), collapse = ",")), f[i], 1800)
      }
      id <- ids(f[i])
      if (length(id) && !is.unsorted(id, strictly = TRUE) && id[1] > last) break
      stamp(k, " page ", i, " is out of sequence (first id ", id[1], " after ", last, "): fetching again")
      unlink(f[i])
    }
    if (!file.exists(f[i])) stop(k, " page ", i, " out of sequence 3 times", call. = FALSE)
    last <- id[length(id)]
  }
  f
}
raw <- lapply(stats::setNames(names(layers), names(layers)), snapshot)
read_layer <- function(k) {
  x <- do.call(rbind, lapply(raw[[k]], utils::read.csv, stringsAsFactors = FALSE, na.strings = "",
                             colClasses = "character"))
  n <- as.integer(readLines(file.path(raw_dir, paste0(k, "_hits.txt"))))
  id <- layers[[k]]$sort
  if (nrow(x) != n || anyDuplicated(x[[id]])) {
    stop(k, ": ", nrow(x), " rows (", sum(duplicated(x[[id]])), " duplicated ids) against the server's ", n,
         call. = FALSE)
  }
  x
}
lic <- read_layer("licences")
dams <- read_layer("dams")
raw_md5 <- vapply(unlist(raw), function(f) unname(tools::md5sum(f)), "")
stamp(nrow(lic), " licence points, ", nrow(dams), " dams")
