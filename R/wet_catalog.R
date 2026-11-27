#' Published discharge and air temperature: the parts a manifest lists
#'
#' Reads the `manifest.json` of a published tree and returns one row per
#' parquet part, with where to fetch it and how to check it. wet publishes two
#' trees, read anonymously over HTTPS: discharge,
#' `s3://fresh-bc/discharge/fwa/v1/` (the default), and daily air temperature,
#' `s3://fresh-bc/air_temperature/fwa/v1/` ([wet_air_daily()] reads it). The
#' bucket allows no listing, so the manifest is how a reader finds the keys.
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
#'   \item{code}{What the part holds. A monthly dataset's part holds one FWA
#'     top-level drainage, the first field of `fwa_watershed_code` (`100` for
#'     the Fraser); a daily dataset's holds one watershed group (`BULK`).
#'     `drainage` names it.}
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
#'   describing each `source`, with its citation), `source_provenance`
#'   (a list by source: what each source's rows were built from, e.g. the
#'   routed table's fingerprint or the balance's fit release), `receipt` (the
#'   build's `receipt.json`, written by crate: its `key`, `href`, `bytes`,
#'   `md5` and `recipe_id`) and `fit` (the shipped fit published beside the
#'   product: `release`, `province_run`, `score_code_md5`, `description`,
#'   `citation` and `files`, a data
#'   frame of `key`, `role`, `bytes`, `md5` and `href`). `receipt` and `fit`
#'   are `NULL` for a build published without them.
#' @section Receipt and fit:
#' Beside the parts, a build lists `receipt.json`, its provenance record in
#' crate's shared shape (what was built, from which code and inputs, and each
#' file's SHA-256; see `crate::crt_receipt_read()`), and under `fit/` the
#' shipped water-balance fit (`fit/fits.rds`) and each watershed group's
#' sample of the province's layers (`fit/sample/part-<GROUP>.parquet`), so
#' one group's balance rows can be rebuilt away from the machine that made
#' them (`scripts/segment_group.R` with `WET_GROUP_FROM=published`).
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
  receipt <- wet_manifest_files(m$receipt, manifest, base, "receipt")
  if (!is.null(receipt)) {
    if (!is.character(m$receipt$recipe_id) || !grepl("^[0-9a-f]{64}$", m$receipt$recipe_id)) {
      stop(manifest, ": the receipt has no valid `recipe_id`", call. = FALSE)
    }
    receipt <- c(as.list(receipt), recipe_id = m$receipt$recipe_id)
  }
  fit <- NULL
  if (!is.null(m$fit)) {
    fit <- m$fit[c("release", "province_run", "score_code_md5", "description", "citation")]
    if (!all(vapply(fit, function(v) is.character(v) && length(v) == 1L, TRUE))) {
      stop(manifest, ": the fit needs `release`, `province_run`, `score_code_md5`, `description` and `citation`",
           call. = FALSE)
    }
    # names a reader may build a path from
    if (!grepl("^[A-Za-z0-9_-]+$", fit$release) || !grepl("^[A-Za-z0-9_-]+$", fit$province_run) ||
          !grepl("^[0-9a-f]{32}$", fit$score_code_md5)) {
      stop(manifest, ": the fit's `release`, `province_run` or `score_code_md5` is malformed", call. = FALSE)
    }
    fit$files <- wet_manifest_files(m$fit$files, manifest, base, "fit")
  }
  extra <- c(fit$files$key, receipt$key)
  if (anyDuplicated(c(out$key, extra))) stop(manifest, " lists a key twice", call. = FALSE)
  structure(out, manifest = manifest, id = m$id, built = m$built,
            provenance = m$provenance, sources = sources, source_provenance = source_provenance,
            receipt = receipt, fit = fit)
}

# The files a manifest lists beside its parts (#160, #161): the receipt, one
# entry, and the fit's files, each with a `role`. NULL where the manifest has
# none, as a build published before them does not.
wet_manifest_files <- function(x, manifest, base, what) {
  if (is.null(x)) return(NULL)
  one <- what == "receipt"
  if (one) x <- list(x)
  if (!is.list(x) || !length(x)) stop(manifest, ": `", what, "` lists no files", call. = FALSE)
  field <- function(e, k, type) {
    v <- e[[k]]
    ok <- length(v) == 1L && switch(type, chr = is.character(v), num = is.numeric(v))
    if (!ok) stop(manifest, ": a `", what, "` file has no valid `", k, "`", call. = FALSE)
    v
  }
  f <- data.frame(
    key = vapply(x, field, "", "key", "chr"),
    role = if (one) "receipt" else vapply(x, field, "", "role", "chr"),
    bytes = vapply(x, field, 0, "bytes", "num"),
    md5 = vapply(x, field, "", "md5", "chr"),
    stringsAsFactors = FALSE
  )
  re <- if (one) "^receipt\\.json$" else "^fit/[A-Za-z0-9][A-Za-z0-9._/-]*$"
  bad <- !grepl(re, f$key) | grepl("(^|/)\\.\\.(/|$)", f$key)
  if (any(bad)) stop(manifest, ": not a ", what, " key: ", f$key[bad][1], call. = FALSE)
  if (!all(grepl("^[0-9a-f]{32}$", f$md5))) stop(manifest, ": an md5 is malformed", call. = FALSE)
  f$href <- paste(base, f$key, sep = "/")
  f
}

# Every file a catalog's manifest lists, parts, fit and receipt, as
# data.frame(key, href, bytes, md5), for wet_catalog_verify() of a whole
# build. wet_catalog_verify() itself checks only the rows it is given, so a
# subset of parts verifies those parts alone, though row subsets keep the
# attributes that hold the fit and the receipt.
wet_catalog_files <- function(catalog) {
  cols <- c("key", "href", "bytes", "md5")
  fit <- attr(catalog, "fit")$files
  rc <- attr(catalog, "receipt")
  rbind(as.data.frame(catalog)[cols],
        if (!is.null(fit)) fit[cols],
        if (!is.null(rc)) as.data.frame(rc[cols], stringsAsFactors = FALSE))
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
# temporary file and moved to `path`, so a reader never sees half of one; a
# caller with checks still to run writes it under another name and moves it
# to manifest.json only once they pass. `fit` (#160), where given, is a list
# of the fit's release, province_run, score_code_md5, description, citation
# and files, `description` saying what the files are and the data they derive from, and
# `citation` how to cite them, `files` the fit's files
# as keys below `root` named by role; `receipt` (#161) is the receipt's key
# below `root` and its recipe_id, from wet_receipt_write(). Their sizes and
# md5s are read from the files, as the parts' are. Parquet files under `fit/`
# are fit files, not parts.
wet_manifest_write <- function(root, id, drainage, sources, provenance, crate_version,
                               built = Sys.time(), path = file.path(root, "manifest.json"),
                               fit = NULL, receipt = NULL) {
  wet_id_check(id)
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("install duckdb to count the parts' rows", call. = FALSE)
  }
  keys <- sort(list.files(root, "\\.parquet$", recursive = TRUE))
  keys <- keys[!startsWith(keys, "fit/")]
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
  file_entry <- function(key) {
    f <- file.path(root, key)
    if (!file.exists(f)) stop("no file ", key, " under ", root, call. = FALSE)
    list(key = key, bytes = as.numeric(file.size(f)), md5 = unname(tools::md5sum(f)))
  }
  if (!is.null(receipt)) {
    m$receipt <- c(file_entry(receipt$key), recipe_id = receipt$recipe_id)
  }
  if (!is.null(fit)) {
    files <- fit$files
    if (is.null(names(files)) || any(!nzchar(names(files))) || !all(startsWith(files, "fit/"))) {
      stop("`fit$files` must be keys under fit/, each named by its role", call. = FALSE)
    }
    m$fit <- list(release = fit$release, province_run = fit$province_run, score_code_md5 = fit$score_code_md5,
                  description = fit$description, citation = fit$citation,
                  files = unname(Map(function(role, key) c(list(role = role), file_entry(key)),
                                     names(files), unname(files))))
  }
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

# One md5 for the parts a catalog lists, which names them and their bytes
# together: md5 of the lines `<key> <md5>`, sorted bytewise (radix, so no
# locale), each ending in a newline. The publish report records it for the
# live build (#94), so a report that names the live commit and part count
# but other parts is refused.
wet_catalog_digest <- function(catalog) {
  lines <- sort(paste(catalog$key, catalog$md5), method = "radix")
  f <- tempfile()
  on.exit(unlink(f), add = TRUE)
  writeBin(charToRaw(paste0(lines, "\n", collapse = "")), f)
  unname(tools::md5sum(f))
}

# Write receipt.json beside the manifest under `root` through crate's writer
# (#161, crate#43), for a published build: `commit` the full 40-character wet
# commit the tree was built at, `inputs` a named list of version ids and
# `settings` the run settings the declaration names (inst/receipt/<id with / as _>.yaml,
# discharge_fwa_v1.yaml or air_temperature_fwa_v1.yaml), `files` every part and fit file below
# `root`, each hashed by crate. `built` is the receipt's time, the manifest's.
# Returns list(key, recipe_id) for wet_manifest_write(receipt =).
wet_receipt_write <- function(root, id, commit, version, inputs, settings, files, built = Sys.time(),
                              keys = system.file("receipt", paste0(gsub("/", "_", id), ".yaml"),
                                                 package = "wet")) {
  if (!requireNamespace("crate", quietly = TRUE)) {
    stop("install crate (0.16.0 or later) to write a receipt", call. = FALSE)
  }
  wet_id_check(id)
  k <- crate::crt_receipt_keys(keys)
  if (!identical(k$output, id)) stop(keys, " declares the receipt of ", k$output, ", not ", id, call. = FALSE)
  parts <- files[!startsWith(files, "fit/")]
  ds <- wet_part_parse(parts, id)$dataset
  rows <- function(unit) {
    f <- file.path(root, parts[ds == paste(id, unit, sep = "/")])
    if (!length(f)) return(0)
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    sum(vapply(f, function(x) {
      DBI::dbGetQuery(con, "SELECT sum(num_rows)::DOUBLE AS n FROM parquet_file_metadata(?)", params = list(x))$n
    }, 0))
  }
  # the summary the declaration names: `parts`, and `rows_<unit>` for datasets of the tree
  unknown <- k$summary[k$summary != "parts" & !grepl("^rows_[a-z]+_[a-z]+$", k$summary)]
  if (length(unknown)) stop(keys, " declares a summary wet does not compute: ", paste(unknown, collapse = ", "),
                            call. = FALSE)
  summary <- stats::setNames(lapply(k$summary, function(nm) {
    if (nm == "parts") length(parts) else rows(sub("^rows_", "", nm))
  }), k$summary)
  crate::crt_receipt_write(
    root,
    output = list(name = id),
    recipe = list(
      code = list(wet = list(commit = commit, version = version, dirty = FALSE)),
      config = list(settings = settings),
      inputs = lapply(inputs, function(v) list(version_id = v))
    ),
    result = list(
      parts = sort(files, method = "radix"),
      summary = summary
    ),
    context = list(time = format(built, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    keys = k, lockfile = NULL, publish = TRUE
  )
  # read back rather than taken from the writer, whose return value has moved
  # between crate commits
  list(key = "receipt.json", recipe_id = crate::crt_receipt_read(file.path(root, "receipt.json"))$recipe$recipe_id)
}
