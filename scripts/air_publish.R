# Publish daily air temperature on every Freshwater Atlas segment (#216, move 21) to
# s3://fresh-bc/air_temperature/fwa/v1/ (layout: research/air_temperature_segments.md).
#
#   Rscript scripts/air_publish.R                 # BUILD: the local tree, its manifest, the report
#   WET_PUBLISH=1 Rscript scripts/air_publish.R   # PUBLISH: upload the built tree, then verify it
#
# BUILD places every segment of whse_basemapping.fwa_stream_networks_sp on cd's daily ERA5-Land
# cube by cd's own call at its midpoint (wet:::wet_air_cells()), copies each used cell's days
# from the cube for every year it holds, conforms every part to its crate schema, checks the
# tree against the cube and the grid without the code that made it, and writes
#   <WET_DATA_ROOT>/publish/air_temperature/fwa/v1/segment_cell/scenario=/forcing=/source=/part-<GROUP>.parquet
#   <WET_DATA_ROOT>/publish/air_temperature/fwa/v1/cell_daily/scenario=/forcing=/source=/part-<YYYY>.parquet
#   <WET_DATA_ROOT>/publish/air_temperature/fwa/v1/receipt.json, manifest.json
# plus the tracked report data/checks/air_publish_<last year>.txt, which holds no time, host or
# path, so a rerun on the same inputs writes it byte for byte. WET_DATA_ROOT is the main
# checkout's data/ when the run is from a worktree (default data/).
#
# PUBLISH uploads that tree (each file a single PUT whose Content-MD5 S3 checks, skipping a part
# whose live ETag is already its md5), then the manifest, deletes keys under the prefix the
# manifest no longer names, reads the public manifest anonymously and verifies every file, and
# rewrites the report's live-build line for a commit. It refuses unless the report naming this
# tree is committed and the files the build reads (air_code_files) are unchanged since the
# build's commit. Anonymous reads under air_temperature/* need a bucket-policy change made
# outside this repo.
#
# Needs arrow, duckdb, terra, cd (0.6.13 or later), crate (the release carrying the air schemas),
# fwapg from WET_PG* with WET_FWAPG_COMMIT naming its build, and for PUBLISH the aws CLI with
# write access to the bucket.

publish <- identical(Sys.getenv("WET_PUBLISH"), "1")
message(if (publish) "PUBLISH run" else "BUILD run (no upload)")
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
root <- file.path(data_root, "publish", "air_temperature", "fwa", "v1")
# a BUILD that goes on to refuse must not leave the last tree publishable
if (!publish) {
  unlink(file.path(root, c("manifest.json", "receipt.json")))
  stopifnot(!file.exists(file.path(root, c("manifest.json", "receipt.json"))))
}
devtools::load_all(quiet = TRUE)
source("scripts/air_publish_lib.R")
stopifnot(identical(root, file.path(data_root, "publish", air_id)))
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
git <- function(...) {
  x <- suppressWarnings(system2("git", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data/checks", "DESCRIPTION", "inst/receipt")
if (length(dirty)) stop("commit these first, so the manifest's commit can rebuild the tree:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
wet_commit_full <- git("rev-parse", "HEAD")
last_year <- as.integer(substr(air_mask_day, 1, 4))
f_report <- file.path("data", "checks", sprintf("air_publish_%d.txt", last_year))
live_heading <- "## The live build"

live_line <- function(cat_local, cat_pub) {
  if (is.null(cat_pub)) return(sprintf("could not read %s", air_url))
  same <- sum(cat_local$md5 == cat_pub$md5[match(cat_local$key, cat_pub$key)], na.rm = TRUE)
  sprintf("parts identical to the published build %s: %d of %d here, %d published (%s); live parts md5 %s",
          attr(cat_pub, "provenance")$wet_commit, same, nrow(cat_local), nrow(cat_pub), air_url,
          wet:::wet_catalog_digest(cat_pub))
}
tree_line <- function(cat_local) sprintf("tree parts md5 %s", wet:::wet_catalog_digest(cat_local))

if (publish) {
  # ---- PUBLISH: the tree BUILD wrote, unchanged, from code unchanged since -----------------------
  cat_local <- wet_catalog(file.path(root, "manifest.json"))
  built_at <- attr(cat_local, "provenance")$wet_commit
  if (!is.character(built_at) || length(built_at) != 1L || !grepl("^[0-9a-f]{7,40}$", built_at)) {
    stop("the manifest names no build commit")
  }
  changed <- git("diff", "--name-only", built_at, "HEAD", "--", air_code_files)
  if (length(changed)) {
    stop("files the build reads changed since the tree was built at ", built_at, " (",
         paste(changed, collapse = ", "), "): rerun the build")
  }
  rep_head <- tryCatch(git("show", paste0("HEAD:", f_report)), error = function(e) character())
  if (!any(startsWith(rep_head, paste0("wet commit ", built_at, " "))) ||
        sum(rep_head == tree_line(cat_local)) != 1L || any(grepl("FAIL", rep_head))) {
    stop("commit the build's report ", f_report, " first; it must name build ", built_at, " and this tree's parts (",
         tree_line(cat_local), ") and fail no check")
  }
  files_local <- wet:::wet_catalog_files(cat_local)
  v <- wet:::wet_catalog_verify(files_local)
  if (!all(v$ok)) stop("the local tree no longer matches its manifest: ", paste(v$key[!v$ok], collapse = ", "))
  aws <- function(...) {
    x <- suppressWarnings(system2("aws", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(x, "status"))) stop("aws ", paste(c(...)[1:2], collapse = " "), " failed: ", paste(x, collapse = " "))
    x
  }
  md5_b64 <- function(hex) jsonlite::base64_enc(as.raw(strtoi(substring(hex, seq(1, 31, 2), seq(2, 32, 2)), 16L)))
  put <- function(file, key, type, md5, ...) {
    aws("s3api", "put-object", "--bucket", air_bucket, "--key", key, "--body", file,
        "--content-md5", md5_b64(md5), "--content-type", type, ...)
  }
  live <- files_local
  live$href <- paste(sub("/manifest.json$", "", air_url), live$key, sep = "/")
  same <- wet:::wet_catalog_verify(live)$ok
  stamp(sum(same), " of ", nrow(files_local), " files already live with these bytes")
  for (i in which(!same)) {
    type <- if (endsWith(files_local$key[i], ".json")) "application/json" else "application/vnd.apache.parquet"
    put(files_local$href[i], paste(air_id, files_local$key[i], sep = "/"), type, files_local$md5[i],
        if (files_local$key[i] == "receipt.json") c("--cache-control", "no-cache"))
    stamp("put ", files_local$key[i])
  }
  f_man <- file.path(root, "manifest.json")
  put(f_man, paste(air_id, "manifest.json", sep = "/"), "application/json", unname(tools::md5sum(f_man)),
      "--cache-control", "no-cache")
  keys <- aws("s3api", "list-objects-v2", "--bucket", air_bucket, "--prefix", paste0(air_id, "/"),
              "--query", "Contents[].Key", "--output", "text")
  keys <- setdiff(unlist(strsplit(keys, "\t")), c("None", ""))
  stale <- setdiff(keys, c(paste(air_id, files_local$key, sep = "/"), paste(air_id, "manifest.json", sep = "/")))
  stopifnot(all(startsWith(stale, paste0(air_id, "/"))))
  for (k in stale) {
    aws("s3api", "delete-object", "--bucket", air_bucket, "--key", k)
    stamp("deleted stale ", k)
  }
  cat_pub <- wet_catalog(air_url)
  files_pub <- wet:::wet_catalog_files(cat_pub)
  stopifnot(identical(files_pub$key, files_local$key), identical(files_pub$md5, files_local$md5))
  v <- wet:::wet_catalog_verify(files_pub)
  if (!all(v$ok)) stop("published files do not verify: ", paste(v$key[!v$ok], v$reason[!v$ok], collapse = "; "))
  if (wet:::wet_catalog_digest(cat_pub) != wet:::wet_catalog_digest(cat_local)) stop("the published parts are not the local ones")
  lines <- readLines(f_report)
  h <- which(lines == live_heading)
  stopifnot(length(h) == 1L, h < length(lines))
  out <- lines
  out[h + 1L] <- live_line(cat_local, cat_pub)
  writeLines(out, f_report)
  stamp("published ", nrow(files_pub), " files (", sum(!same), " uploaded), ", length(stale),
        " stale keys deleted; all verify at ", air_url)
  message("commit ", f_report, ": its live-build line now names this upload")
  quit(save = "no")
}

# ---- BUILD --------------------------------------------------------------------------------------
fwapg_commit <- Sys.getenv("WET_FWAPG_COMMIT")
if (!grepl("^[0-9a-f]{7,40}$", fwapg_commit)) stop("set WET_FWAPG_COMMIT to the fwapg commit the database was built at")
if (!requireNamespace("crate", quietly = TRUE)) stop("install crate (the release carrying the air schemas)")
crate_version <- as.character(utils::packageVersion("crate"))
units <- c("segment_cell", "cell_daily")
# the manifest names each schema at the installed crate's release tag, so that tag must hold it
for (u in units) {
  ds <- paste(air_id, u, sep = "/")
  url <- sprintf("https://raw.githubusercontent.com/NewGraphEnvironment/crate/v%s/inst/extdata/schemas/nge/%s.yaml",
                 crate_version, ds)
  r <- curl::curl_fetch_memory(url)
  if (r$status_code != 200L) stop("crate v", crate_version, " has no released schema for ", ds, " (HTTP ",
                                  r$status_code, "): install the crate release that carries it")
  f <- tempfile()
  writeBin(r$content, f)
  installed <- system.file("extdata", "schemas", "nge", paste0(ds, ".yaml"), package = "crate")
  if (!identical(unname(tools::md5sum(installed)), unname(tools::md5sum(f)))) {
    stop("the installed crate's schema for ", ds, " differs from crate v", crate_version, "'s: install that release")
  }
}
if (utils::packageVersion("cd") < "0.6.13") stop("install cd 0.6.13 or later")

# the cube: its manifest, the years it holds, the mask file, and its grid against air_grid
man_path <- cd::cd_cache_fetch(paste0(air_cube_url, "/manifest.json"), refresh = TRUE)
cube_md5 <- unname(tools::md5sum(man_path))
cube_files <- jsonlite::read_json(man_path)$files
years <- sort(as.integer(sub("^tmean_daily_([0-9]{4})\\.tif$", "\\1",
                             grep("^tmean_daily_[0-9]{4}\\.tif$", names(cube_files), value = TRUE))))
for (v in air_vars) {
  have <- sort(as.integer(sub(paste0("^", v, "_daily_([0-9]{4})\\.tif$"), "\\1",
                              grep(paste0("^", v, "_daily_[0-9]{4}\\.tif$"), names(cube_files), value = TRUE))))
  if (!identical(have, years)) stop("the cube's ", v, " years are not its tmean years")
}
if (max(years) != last_year || !identical(years, seq(min(years), max(years)))) {
  stop("the cube holds years ", min(years), "-", max(years), " with gaps or ends after ", last_year,
       ": move air_mask_day (R/wet_air_daily.R) to 1 January of its last year")
}
cube_file <- function(v, yr) cd::cd_cache_fetch(sprintf("%s/%s_daily_%d.tif", air_cube_url, v, yr))
mask_name <- sprintf("tmean_daily_%d.tif", last_year)
mask_r <- terra::rast(cube_file("tmean", last_year))
template <- air_template()
if (!isTRUE(terra::compareGeom(mask_r, template, stopOnError = FALSE)) || names(mask_r)[1] != air_mask_day) {
  stop("the cube's grid or first day is not air_grid's and air_mask_day's")
}
mask <- !is.na(terra::values(mask_r[[1]], mat = FALSE))
stamp("cube: ", length(years), " years ", min(years), "-", max(years), ", ", sum(mask), " cells with data on ",
      air_mask_day)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("WET_PGHOST", "localhost"), port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
  dbname = Sys.getenv("WET_PGDATABASE", "fwapg"), user = Sys.getenv("WET_PGUSER", "postgres"),
  password = Sys.getenv("WET_PGPASSWORD", "postgres"), connect_timeout = 10
)
n_table <- DBI::dbGetQuery(conn, "SELECT count(*)::double precision AS n FROM whse_basemapping.fwa_stream_networks_sp")$n
grp <- DBI::dbGetQuery(conn, "SELECT watershed_group_code AS code, watershed_group_name AS name
                              FROM whse_basemapping.fwa_watershed_groups_poly ORDER BY watershed_group_code")
stopifnot(!anyDuplicated(grp$code))

# ---- the lookup, one watershed group at a time --------------------------------------------------
unlink(file.path(root, c("segment_cell", "cell_daily")), recursive = TRUE)
stopifnot(!dir.exists(file.path(root, "segment_cell")), !dir.exists(file.path(root, "cell_daily")))
lookup <- vector("list", nrow(grp))
for (i in seq_len(nrow(grp))) {
  g <- grp$code[i]
  # midpoint along the line in BC Albers, then to degrees; ordered by the key's index, with no
  # other sort or aggregate in the database (its temporary space has run out on one before)
  p <- DBI::dbGetQuery(conn, "
    SELECT linear_feature_id::double precision AS linear_feature_id, watershed_group_code,
           geom IS NULL OR ST_IsEmpty(geom) AS empty,
           ST_X(ST_Transform(ST_LineInterpolatePoint(ST_Force2D(geom), 0.5), 4326)) AS lon,
           ST_Y(ST_Transform(ST_LineInterpolatePoint(ST_Force2D(geom), 0.5), 4326)) AS lat,
           ST_Z(ST_LineInterpolatePoint(geom, 0.5)) AS elev
    FROM whse_basemapping.fwa_stream_networks_sp WHERE watershed_group_code = $1
    ORDER BY linear_feature_id", params = list(g))
  if (!nrow(p)) next
  if (any(p$empty) || anyNA(p[c("lon", "lat")])) stop(g, ": a segment has no geometry")
  # cd's two expected warnings are muffled inside; any other (a cached file of another build) stops
  cells <- withCallingHandlers(
    wet:::wet_air_cells(p[c("linear_feature_id", "lon", "lat")], source = air_cube_url),
    warning = function(w) stop(g, ": cd warned while placing segments: ", conditionMessage(w), call. = FALSE)
  )
  x <- air_conform(air_lookup_frame(p, cells), "segment_cell")
  air_part_write(x, root, "segment_cell", g)
  lookup[[i]] <- x
  if (i %% 25L == 0L) stamp("lookup: ", i, " of ", nrow(grp), " groups")
}
lookup <- do.call(rbind, lookup)
# every check from here reads the parts as written, not the frames handed to the writer
lk_files <- file.path(root, vapply(unique(lookup$watershed_group_code), function(g) air_part_key("segment_cell", g), ""))
back <- do.call(rbind, lapply(lk_files, function(f) as.data.frame(arrow::read_parquet(f))))
back$linear_feature_id <- as.integer(back$linear_feature_id)
back$cell_id <- as.integer(back$cell_id)
if (!isTRUE(all.equal(back, lookup, check.attributes = FALSE))) stop("the segment_cell parts do not read back as written")
lookup <- back
rm(back)
if (nrow(lookup) != n_table || anyDuplicated(lookup$linear_feature_id)) {
  stop("read ", nrow(lookup), " segments, the table holds ", n_table)
}
stamp("lookup: ", nrow(lookup), " segments in ", length(unique(lookup$watershed_group_code)), " groups")

# the main-flow tree: every one of its segments has a row (#216), streamed and matched in R
tree <- DBI::dbGetQuery(conn, "SELECT linear_feature_id::double precision AS id
                               FROM whse_basemapping.fwa_stream_networks_mainflow_tree")$id
n_tree_table <- length(tree)
tree_status <- lookup$cell_status[match(tree, lookup$linear_feature_id)]
DBI::dbDisconnect(conn)

# ---- the series, one year at a time -------------------------------------------------------------
used <- sort(unique(lookup$cell_id[!is.na(lookup$cell_id)]))
ctr <- air_cell_centre(used)
pts <- data.frame(id = used, lon = ctr$x, lat = ctr$y)
year_files <- vector("list", length(years))
checks <- list(complete = c(0, 0), values = c(0, 0, 0))
for (k in seq_along(years)) {
  yr <- years[k]
  x <- withCallingHandlers(
    cd::cd_extract_daily(pts, sprintf("%d-01-01", yr), sprintf("%d-12-31", yr), air_vars, source = air_cube_url),
    warning = function(w) stop("cd warned for ", yr, ": ", conditionMessage(w), call. = FALSE)
  )
  files <- unique(data.frame(variable = x$variable, checksum = x$checksum, cd_sha = x$cd_sha))
  if (nrow(files) != length(air_vars)) stop(yr, ": more than one build of a cube file")
  year_files[[k]] <- list(year = yr, files = lapply(seq_len(nrow(files)), function(j) {
    list(name = sprintf("%s_daily_%d.tif", files$variable[j], yr), checksum = files$checksum[j],
         cd_sha = files$cd_sha[j])
  }))
  y <- air_conform(air_daily_frame(x, used), "cell_daily")
  rm(x)
  f_year <- air_part_write(y, root, "cell_daily", yr)
  y <- as.data.frame(arrow::read_parquet(f_year))
  y$tmean_c <- as.numeric(y$tmean_c)
  y$tmax_c <- as.numeric(y$tmax_c)
  y$tmin_c <- as.numeric(y$tmin_c)
  cc <- air_check_complete(y, used, yr)
  yr_files <- stats::setNames(lapply(air_vars, cube_file, yr = yr), air_vars)
  # every file of every year on the published grid, not only the mask's
  for (v in air_vars) {
    if (!isTRUE(terra::compareGeom(terra::rast(yr_files[[v]]), template, stopOnError = FALSE))) {
      stop("the cube's ", v, " file for ", yr, " is not on air_grid")
    }
  }
  vv <- air_check_values(y, yr_files)
  checks$complete <- checks$complete + c(cc$compared, cc$differing)
  checks$values <- c(checks$values[1] + vv$compared, checks$values[2] + vv$differing, max(checks$values[3], vv$largest))
  stamp("series: ", yr, ", ", nrow(y), " cell-days")
}
cd_shas <- sort(unique(unlist(lapply(year_files, function(e) vapply(e$files, `[[`, "", "cd_sha")))), method = "radix")
mask_entry <- cube_files[[mask_name]]
# the cube the tree was read from is the one the manifest names: cd re-reads its manifest and files
# on every call of a long build, so a republish during it would leave the recorded md5 and the
# mask's checksum describing another build
if (!identical(unname(tools::md5sum(man_path)), cube_md5)) stop("cd's daily manifest changed during the build: rerun it")
last_files <- year_files[[length(year_files)]]$files
mask_read <- vapply(last_files, `[[`, "", "checksum")[vapply(last_files, `[[`, "", "name") == mask_name]
if (!identical(unname(mask_read), mask_entry[["file:checksum"]])) {
  stop("the mask file cd read (", mask_read, ") is not the manifest's ", mask_name, " (", mask_entry[["file:checksum"]], ")")
}

# ---- the checks on the lookup -------------------------------------------------------------------
cell_lines <- air_check_cells(lookup, template, mask)

# ---- receipt and manifest -----------------------------------------------------------------------
part_keys <- sort(list.files(root, "\\.parquet$", recursive = TRUE), method = "radix")
built_time <- Sys.time()
receipt <- wet:::wet_receipt_write(
  root, air_id, wet_commit_full, as.character(utils::packageVersion("wet")),
  inputs = list(cube_manifest = cube_md5, cd_commits = paste(cd_shas, collapse = ","),
                fwapg = sprintf("%s (fwa_stream_networks_sp %d rows)", fwapg_commit, as.integer(n_table))),
  settings = list(crate_version = crate_version, point = "midpoint", mask_day = air_mask_day),
  files = part_keys, built = built_time
)
labels <- c(stats::setNames(grp$name, grp$code), stats::setNames(as.character(years), years))
cd_cite <- format(utils::citation("cd"), style = "text")[1]
wet:::wet_manifest_write(
  root, air_id, drainage = labels[unique(c(unique(lookup$watershed_group_code), as.character(years)))],
  sources = list(list(
    source = air_source, description = air_source_description,
    citation = sprintf(air_source_citation, cd_cite),
    provenance = list(cube_url = air_cube_url, cube_manifest_md5 = cube_md5, grid = air_grid,
                      mask = list(day = air_mask_day, file = mask_name,
                                  checksum = mask_entry[["file:checksum"]] %||% NA_character_),
                      point = "midpoint", years = year_files)
  )),
  provenance = list(wet_version = as.character(utils::packageVersion("wet")), wet_commit = wet_commit,
                    fwapg_commit = fwapg_commit, code = "scripts/air_publish.R"),
  crate_version = crate_version, built = built_time, receipt = receipt
)
cat_local <- wet_catalog(file.path(root, "manifest.json"))
v <- wet:::wet_catalog_verify(wet:::wet_catalog_files(cat_local))
if (!all(v$ok)) stop("the written tree does not verify against its manifest")
cat_pub <- tryCatch(wet_catalog(air_url), error = function(e) NULL)

# ---- the report ---------------------------------------------------------------------------------
st <- factor(lookup$cell_status, air_statuses)
by_group <- table(lookup$watershed_group_code, st)
tree_st <- factor(tree_status, air_statuses)
bytes <- tapply(cat_local$bytes, cat_local$dataset, sum)
rows <- tapply(cat_local$rows, cat_local$dataset, sum)
cnt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
rep <- c(
  sprintf("# Daily air temperature on Freshwater Atlas segments (%s), built by scripts/air_publish.R", air_id),
  "",
  sprintf("wet commit %s (%s); crate %s; cd %s; fwapg %s", wet_commit, wet_commit_full, crate_version,
          as.character(utils::packageVersion("cd")), fwapg_commit),
  "",
  "## Segments",
  sprintf("segments read: %s; whse_basemapping.fwa_stream_networks_sp count(*): %s -> %s", cnt(nrow(lookup)),
          cnt(n_table), if (nrow(lookup) == n_table) "pass" else "FAIL"),
  sprintf("main-flow tree segments with a lookup row: %s of %s in fwa_stream_networks_mainflow_tree -> %s",
          cnt(sum(!is.na(tree_status))), cnt(n_tree_table), if (!anyNA(tree_status)) "pass" else "FAIL"),
  sprintf("point: the segment's midpoint along its line; mask day %s (%s, checksum %s)", air_mask_day, mask_name,
          mask_entry[["file:checksum"]] %||% "none"),
  "",
  "status       all segments   main-flow tree",
  sprintf("%-12s %12s %16s", air_statuses, cnt(as.vector(table(st))), cnt(as.vector(table(tree_st)))),
  "",
  "## Segments by watershed group (own, moved, no_data, outside)",
  sprintf("%s %s", rownames(by_group), apply(by_group, 1, function(r) paste(cnt(r), collapse = " "))),
  "",
  "## Cells and series",
  sprintf("cells used: %s of %s with data on the mask day; cube grid %d x %d at %s degrees, %s to %s E, %s to %s N",
          cnt(length(used)), cnt(sum(mask)), air_grid$nrow, air_grid$ncol, air_grid$res, air_grid$xmin, air_grid$xmax,
          air_grid$ymin, air_grid$ymax),
  sprintf("cube manifest md5 %s; years %d-%d; cd commits %s", cube_md5, min(years), max(years),
          paste(cd_shas, collapse = ", ")),
  sprintf("%s: %s parts, %s rows, %s bytes", names(rows), cnt(as.vector(table(cat_local$dataset)[names(rows)])),
          cnt(as.vector(rows)), cnt(as.vector(bytes[names(rows)]))),
  "",
  "## Cube files per year part",
  vapply(year_files, function(e) paste(e$year, paste(vapply(e$files, function(f) {
    sprintf("%s %s %s", f$name, f$checksum, f$cd_sha)
  }, ""), collapse = "; ")), ""),
  "",
  "## Checks (none passes through the code that made the tree)",
  cell_lines,
  air_check_line("cell_daily completeness: every used cell on every day of every year, no other cell",
                 checks$complete[1], checks$complete[2]),
  air_check_line("cell_daily values against the cube read with terra, every year and variable",
                 checks$values[1], checks$values[2], checks$values[3]),
  "",
  tree_line(cat_local),
  "",
  live_heading,
  live_line(cat_local, cat_pub)
)
writeLines(rep, f_report)
stamp("wrote ", f_report, "; ", sum(grepl("FAIL", rep)), " failed lines")
if (any(grepl("FAIL", rep))) stop("a check failed: see ", f_report)
