#' Published discharge: the parts a manifest lists
#'
#' Reads the `manifest.json` of a published discharge tree and returns one row
#' per parquet part, with where to fetch it and how to check it. The tree is
#' `s3://fresh-bc/discharge/fwa/v1/`, read anonymously over HTTPS. The bucket
#' allows no listing, so the manifest is how a reader finds the keys.
#'
#' @section Layout:
#' A dataset ID is `<variable>/<network>/<version>/<unit>_<timebase>`, e.g.
#' `discharge/fwa/v1/segment_monthly`. The same ID is the S3 prefix, the
#' crate schema key (`crate::crt_schema_conform(df, "nge", <ID>)`), and, with
#' the variable as the schema and the rest joined by `_`, the Postgres table
#' [wet_db_load()] writes (`discharge.fwa_v1_segment_monthly`). Under each
#' dataset, parts sit at
#' `scenario=<s>/forcing=<f>/source=<src>/part-<code>.parquet`:
#' \describe{
#'   \item{scenario}{The emissions pathway: `historical`, later `ssp245` and
#'     `ssp585`.}
#'   \item{forcing}{The climate data that drove the estimate: `PNWNAmet`
#'     (PCIC's historical run), a GCM as PCIC spells it, `climr` (the open
#'     water balance's 1981-2010 normals), or `ensemble`.}
#'   \item{source}{Who made the estimate and how, `<group>_<method>`:
#'     `pcic_routed` (PCIC's routed flow placed on the FWA) or `wet_balance`
#'     (wet's open water balance).}
#'   \item{code}{The FWA top-level drainage the part holds: the first field
#'     of `fwa_watershed_code`, e.g. `100` for the Fraser. `drainage` names
#'     it.}
#' }
#' The three keys are in the path, not in the files: duckdb's
#' `read_parquet(<hrefs>, hive_partitioning = true)` reads them back from
#' the hrefs. Files are overwritten in place when the data are rebuilt, so
#' `md5` identifies a build, and a read during a publish can find a part that
#' no longer matches its manifest entry: retry once the publish completes.
#' Each publish rewrites the whole manifest from one local tree.
#'
#' @param manifest Path or URL of a `manifest.json`. The default is option
#'   `wet.catalog_url`, or else the published discharge manifest.
#' @return `data.frame(dataset, scenario, forcing, source, code, drainage,
#'   key, href, rows, bytes, md5)`, one row per part. `key` is the part's
#'   path below the manifest, and `href` is where to fetch it. Attributes:
#'   `manifest` (where it was read from), `id` (e.g. `discharge/fwa/v1`),
#'   `built` (UTC), `provenance` (a named list: wet version and commit, and
#'   the code that built and published it), `sources` (a data frame
#'   describing each `source`, with its citation), and `source_provenance`
#'   (a list by source: what each source's rows were built from, e.g. the
#'   routed table's fingerprint or the balance's fit release).
#' @seealso [wet_db_load()] to load one scenario of a dataset into Postgres.
#' @examples
#' # the manifest of a tiny made-up tree, laid out as the published one
#' cat <- wet_catalog(system.file("extdata", "discharge_manifest.json",
#'                                package = "wet"))
#' cat[c("dataset", "scenario", "forcing", "source", "code", "rows")]
#' attr(cat, "sources")[c("source", "description")]
#' @export
wet_catalog <- function(manifest = getOption("wet.catalog_url", wet_catalog_url)) {
  if (!is.character(manifest) || length(manifest) != 1L || is.na(manifest)) {
    stop("`manifest` must be one path or URL", call. = FALSE)
  }
  is_url <- grepl("^https?://", manifest)
  txt <- if (is_url) {
    r <- curl::curl_fetch_memory(manifest)
    if (r$status_code != 200L) {
      stop("could not read ", manifest, ": HTTP ", r$status_code, call. = FALSE)
    }
    rawToChar(r$content)
  } else {
    if (!file.exists(manifest)) stop("no manifest at ", manifest, call. = FALSE)
    paste(readLines(manifest, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  }
  m <- tryCatch(jsonlite::parse_json(txt), error = function(e) {
    stop(manifest, " is not JSON: ", conditionMessage(e), call. = FALSE)
  })
  if (!identical(m$manifest_version, 1L)) {
    stop(manifest, ": manifest_version must be 1", call. = FALSE)
  }
  wet_id_check(m$id)
  parts <- m$parts
  if (!is.list(parts) || !length(parts)) stop(manifest, " lists no parts", call. = FALSE)
  field <- function(p, k, type) {
    v <- p[[k]]
    ok <- length(v) == 1L && switch(type, chr = is.character(v), num = is.numeric(v))
    if (!ok) stop(manifest, ": a part has no valid `", k, "`", call. = FALSE)
    v
  }
  out <- data.frame(
    key = vapply(parts, field, "", "key", "chr"),
    drainage = vapply(parts, field, "", "drainage", "chr"),
    rows = vapply(parts, field, 0, "rows", "num"),
    bytes = vapply(parts, field, 0, "bytes", "num"),
    md5 = vapply(parts, field, "", "md5", "chr"),
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(out$key)) stop(manifest, " lists a key twice", call. = FALSE)
  if (!all(grepl("^[0-9a-f]{32}$", out$md5))) stop(manifest, ": an md5 is malformed", call. = FALSE)
  # every field the path carries is read from the path, so the manifest cannot
  # say one thing in a field and another in the key it names
  parsed <- wet_part_parse(out$key, m$id)
  base <- if (is_url) sub("/[^/]*$", "", manifest) else dirname(normalizePath(manifest))
  out <- cbind(parsed, out[c("drainage", "key")],
               href = paste(base, out$key, sep = "/"),
               out[c("rows", "bytes", "md5")], stringsAsFactors = FALSE)

  src <- m$sources
  sources <- data.frame(
    source = vapply(src, function(s) as.character(s$source), ""),
    description = vapply(src, function(s) as.character(s$description), ""),
    citation = vapply(src, function(s) as.character(s$citation), ""),
    stringsAsFactors = FALSE
  )
  source_provenance <- stats::setNames(lapply(src, function(s) s$provenance), sources$source)
  missing_src <- setdiff(out$source, sources$source)
  if (length(missing_src)) {
    stop(manifest, " does not describe source ", paste(missing_src, collapse = ", "), call. = FALSE)
  }
  structure(out, manifest = manifest, id = m$id, built = m$built,
            provenance = m$provenance, sources = sources, source_provenance = source_provenance)
}

wet_catalog_url <- "https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json"

# `<variable>/<network>/<version>`, the tree a manifest describes
wet_id_check <- function(id) {
  if (!is.character(id) || length(id) != 1L || !grepl("^[a-z][a-z_]*/[a-z][a-z0-9]*/v[0-9]+$", id)) {
    stop("a tree ID is `<variable>/<network>/v<n>`, e.g. discharge/fwa/v1; got ",
         paste(format(id), collapse = " "), call. = FALSE)
  }
  invisible(id)
}

# A part's key, `<unit>_<timebase>/scenario=<s>/forcing=<f>/source=<src>/part-<code>.parquet`,
# into the fields it carries. The one parser for writer and reader.
wet_part_parse <- function(key, id) {
  value <- "[A-Za-z0-9][A-Za-z0-9._-]*"
  re <- paste0("^([a-z]+_[a-z]+)/scenario=(", value, ")/forcing=(", value, ")/source=([a-z]+_[a-z]+)",
               "/part-([A-Za-z0-9]+)\\.parquet$")
  bad <- !grepl(re, key)
  if (any(bad)) {
    stop("not a part key (<unit>_<timebase>/scenario=/forcing=/source=/part-<code>.parquet): ",
         key[bad][1], call. = FALSE)
  }
  data.frame(
    dataset = paste(id, sub(re, "\\1", key), sep = "/"),
    scenario = sub(re, "\\2", key),
    forcing = sub(re, "\\3", key),
    source = sub(re, "\\4", key),
    code = sub(re, "\\5", key),
    stringsAsFactors = FALSE
  )
}

# Write `manifest.json` for the tree under `root` (the local copy of `id`),
# from the parquet files found there: keys, rows, bytes and md5 come from the
# files themselves, and the Hive fields from their paths. The whole manifest
# is rewritten each time, so `root` must hold every scenario that is to stay
# published. `drainage` labels each code (named by code); `sources` is a list
# with one entry per source, list(source, description, citation, provenance),
# where provenance is what that source's rows were built from; `provenance`
# is a named list of scalars for the build as a whole; `crate_version` is the
# crate release whose schemas the parts were conformed to. Written to a
# temporary file and moved, so a reader never sees half of one.
wet_manifest_write <- function(root, id, drainage, sources, provenance, crate_version,
                               built = Sys.time()) {
  wet_id_check(id)
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("install duckdb to count the parts' rows", call. = FALSE)
  }
  keys <- sort(list.files(root, "\\.parquet$", recursive = TRUE))
  if (!length(keys)) stop("no parquet parts under ", root, call. = FALSE)
  parsed <- wet_part_parse(keys, id)
  if (is.null(names(drainage)) || !all(parsed$code %in% names(drainage))) {
    stop("no drainage label for code ",
         paste(setdiff(parsed$code, names(drainage)), collapse = ", "), call. = FALSE)
  }
  src_names <- vapply(sources, function(x) x$source, "")
  if (!setequal(unique(parsed$source), src_names) || anyDuplicated(src_names) ||
        !all(vapply(sources, function(x) all(c("description", "citation") %in% names(x)), TRUE))) {
    stop("`sources` must describe each source in the tree once: the tree has ",
         paste(unique(parsed$source), collapse = ", "), call. = FALSE)
  }
  files <- file.path(root, keys)
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  rows <- vapply(files, function(f) {
    DBI::dbGetQuery(con, "SELECT sum(num_rows)::DOUBLE AS n FROM parquet_file_metadata(?)",
                    params = list(f))$n
  }, numeric(1), USE.NAMES = FALSE)
  parts <- lapply(seq_along(keys), function(i) {
    list(key = keys[i], dataset = parsed$dataset[i], scenario = parsed$scenario[i],
         forcing = parsed$forcing[i], source = parsed$source[i], code = parsed$code[i],
         drainage = unname(drainage[[parsed$code[i]]]), rows = rows[i],
         bytes = as.numeric(file.size(files[i])), md5 = unname(tools::md5sum(files[i])))
  })
  m <- list(
    manifest_version = 1L,
    id = id,
    built = format(built, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    provenance = provenance,
    sources = sources,
    datasets = lapply(sort(unique(parsed$dataset)), function(d) {
      list(dataset = d, schema = list(
        package = "crate", version = crate_version, source = "nge", file_name = d,
        url = sprintf("https://github.com/NewGraphEnvironment/crate/blob/v%s/inst/extdata/schemas/nge/%s.yaml",
                      crate_version, d)
      ))
    }),
    parts = parts
  )
  path <- file.path(root, "manifest.json")
  tmp <- tempfile("manifest", tmpdir = root, fileext = ".json")
  jsonlite::write_json(m, tmp, auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null", na = "null")
  if (!file.rename(tmp, path)) stop("could not move ", tmp, " to ", path, call. = FALSE)
  invisible(path)
}

# Whether every part a catalog lists is what its manifest says: for a URL, an
# anonymous HEAD whose Content-Length is the part's bytes and whose ETag is
# its md5 (true of a single-part upload, which is how parts are published);
# for a local path, the file's size and md5. Returns data.frame(key, ok,
# reason), one row per part.
wet_catalog_verify <- function(catalog) {
  check <- function(i) {
    p <- catalog[i, ]
    if (!grepl("^https?://", p$href)) {
      if (!file.exists(p$href)) return("missing")
      if (file.size(p$href) != p$bytes) return("size differs")
      if (unname(tools::md5sum(p$href)) != p$md5) return("md5 differs")
      return("")
    }
    h <- curl::new_handle(nobody = TRUE)
    r <- tryCatch(curl::curl_fetch_memory(p$href, handle = h), error = function(e) e)
    if (inherits(r, "error")) return(paste("unreachable:", conditionMessage(r)))
    if (r$status_code != 200L) return(paste("HTTP", r$status_code))
    hd <- curl::parse_headers_list(r$headers)
    len <- suppressWarnings(as.numeric(hd[["content-length"]]))
    etag <- gsub('"', "", hd[["etag"]] %||% "")
    if (!identical(len, p$bytes)) return("size differs")
    if (!identical(etag, p$md5)) return(paste0("etag ", etag, " is not the md5"))
    ""
  }
  reason <- vapply(seq_len(nrow(catalog)), check, "")
  data.frame(key = catalog$key, ok = reason == "", reason = reason, stringsAsFactors = FALSE)
}
