# Helpers for scripts/scenario_basis.R (#169). Copies of the channel-scale pilot's
# (scripts/channel_scale_pilot.R), which is left as it is because its tracked report
# names its script's commit. Differences from the pilot's: the user agent; listing()
# waits on a 429 or 503 and stops after five refusals in a row; the log is passed in.

# PCIC's domain of a sub-basin outlet, from its subid's prefix (the pilot's)
domain_of <- function(subid) {
  p <- subid %/% 1e6
  ifelse(p >= 200, "Peace", ifelse(p <= 4, "Fraser", ifelse(p <= 6, "Columbia", "Coast")))
}

md5_text <- function(x) {
  f <- tempfile()
  on.exit(unlink(f))
  writeLines(x, f)
  unname(tools::md5sum(f))
}

# the pilot's name for a bulk batch's files: its domain prefix and the md5 of its sorted ids
batch_name <- function(ids) {
  paste0("b", ids[1] %/% 1e6, "_", substr(md5_text(paste(sort(ids), collapse = ",")), 1, 12))
}

# the rule block of a script's lines, between its two marker lines
rule_block <- function(lines) {
  a <- grep("^# ---- rules registered before any flow value was read", lines)
  b <- grep("^# ---- end of registered rules", lines)
  stopifnot(length(a) == 1L, length(b) == 1L, b > a)
  lines[a:b]
}

# the first commit of `path` whose rule block is the one in the working copy
rule_registration <- function(path, git) {
  want <- md5_text(rule_block(readLines(path)))
  for (h in git("log", "--reverse", "--format=%H %ct", "--", path)) {
    sha <- strsplit(h, " ")[[1]]
    if (identical(md5_text(rule_block(git("show", paste0(sha[1], ":", path)))), want)) {
      return(list(sha = substr(sha[1], 1, 7),
                  utc = as.POSIXct(as.numeric(sha[2]), origin = "1970-01-01", tz = "UTC")))
    }
  }
  stop("the rule block as run is in no commit of ", path, call. = FALSE)
}

h_curl <- function(url, file, body = NULL, timeout = 1800) {
  h <- curl::new_handle(timeout = timeout, connecttimeout = 60, useragent = "wet-scenario-basis",
                        followlocation = TRUE)
  if (!is.null(body)) {
    curl::handle_setheaders(h, `Content-Type` = "application/json")
    curl::handle_setopt(h, customrequest = "POST", postfields = body)
  }
  t0 <- Sys.time()
  r <- tryCatch(curl::curl_fetch_disk(url, file, handle = h), error = function(e) NULL)
  ra <- if (is.null(r)) NA_real_ else {
    v <- suppressWarnings(as.numeric(curl::parse_headers_list(r$headers)[["retry-after"]]))
    if (length(v) == 1L && is.finite(v) && v >= 0) v else NA_real_
  }
  list(code = if (is.null(r)) 0L else r$status_code, secs = as.numeric(Sys.time() - t0, units = "secs"),
       bytes = if (file.exists(file)) file.size(file) else 0, retry_after = ra)
}

fetch_log <- function(f_log, host, what, n, code, bytes, secs, file) {
  row <- data.frame(utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), host = host, what = what,
                    n = n, code = code, bytes = bytes, secs = round(secs, 2), file = file)
  dir.create(dirname(f_log), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(row, f_log, sep = "\t", quote = FALSE, row.names = FALSE,
                     col.names = !file.exists(f_log), append = file.exists(f_log))
}

read_fetch_log <- function(f_log) {
  if (!file.exists(f_log)) return(NULL)
  utils::read.delim(f_log, quote = "", na.strings = character(), comment.char = "",
                    colClasses = "character")
}

# Each outlet's listing: the series hydromosaic holds there. Kept gzipped under `dir`
# once read; a cached one is read without a request. With `fetch = FALSE` a listing not
# in the cache stops the script instead of asking for it.
listing <- function(subid, dir, f_log, fetch, host = "https://services.pacificclimate.org",
                    wait = Sys.sleep) {
  f <- file.path(dir, paste0(subid, ".json.gz"))
  if (!file.exists(f)) {
    if (!fetch) stop("listing of outlet ", subid, " is not in ", dir, " and fetching is off", call. = FALSE)
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    tmp <- tempfile(fileext = ".json", tmpdir = dir)
    on.exit(unlink(tmp), add = TRUE)
    for (k in 1:5) {
      r <- h_curl(sprintf("%s/hydromosaic/outlets/%d/timeseries", host, subid), tmp, timeout = 120)
      fetch_log(f_log, "services", "listing", 1L, r$code, r$bytes, r$secs, basename(f))
      if (!r$code %in% c(429L, 503L)) break
      if (k == 5L) stop("listing of outlet ", subid, " refused five times in a row (", r$code, ")", call. = FALSE)
      wait(if (is.na(r$retry_after)) 60 * 2^(k - 1L) else r$retry_after)
    }
    if (r$code == 404L) {
      writeLines("[]", tmp)
    } else if (r$code != 200L) {
      stop("listing of outlet ", subid, " answered ", r$code, call. = FALSE)
    }
    # a 200 that is not a listing (an HTML page, a cut body) is refused, not cached
    body <- tryCatch(jsonlite::fromJSON(tmp), error = function(e) NULL)
    if (!(is.list(body) && length(body) == 0L) &&
          !(is.data.frame(body) && all(c("model", "scenario", "variable", "start_time", "end_time",
                                          "num_times") %in% names(body)))) {
      stop("listing of outlet ", subid, " answered 200 with no listing in it; not cached", call. = FALSE)
    }
    con <- gzfile(paste0(f, ".tmp"), "w")
    writeLines(readLines(tmp, warn = FALSE), con)
    close(con)
    if (!file.rename(paste0(f, ".tmp"), f)) stop("could not move ", f, " into place", call. = FALSE)
  }
  con <- gzfile(f, "r")
  txt <- readLines(con, warn = FALSE)
  close(con)
  x <- jsonlite::fromJSON(paste(txt, collapse = "\n"))
  cols <- c("model", "scenario", "variable", "start_time", "end_time", "num_times")
  if (!length(x)) {
    return(data.frame(model = character(), scenario = character(), variable = character(),
                      start_time = character(), end_time = character(), num_times = integer()))
  }
  x[cols]
}

# Refuses a run whose fetch log holds a request made before the rules were registered.
# Returns the first logged request's time, or NULL when nothing was logged.
fetch_guard <- function(log, reg_utc) {
  if (is.null(log) || !nrow(log)) return(NULL)
  t <- as.POSIXct(log$utc, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  if (anyNA(t)) stop("the fetch log holds an unreadable time", call. = FALSE)
  if (any(t < reg_utc)) {
    stop("the fetch log holds ", sum(t < reg_utc), " request(s) made before the rules were registered (",
         format(reg_utc, "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"), ")", call. = FALSE)
  }
  min(t)
}

# The channel-scale pilot report's sites table: site id and its "wet acc" column, as printed.
pilot_wet_acc <- function(lines) {
  h <- grep("^site +HYDAT +PCIC raw +routed pub +balance pub +wet acc", lines)
  stopifnot(length(h) == 1L)
  rows <- lines[(h + 1L):(h + 6L)]
  f <- strsplit(trimws(rows), " +")
  stats::setNames(vapply(f, `[`, "", 6L), vapply(f, `[`, "", 1L))
}

# Parity: each site's annual flow, printed at two decimals, must equal the pilot's.
parity_lines <- function(q, lines) {
  want <- pilot_wet_acc(lines)
  if (!all(names(q) %in% names(want))) stop("a parity site is not in the pilot's sites table", call. = FALSE)
  got <- sprintf("%.2f", q)
  bad <- got != want[names(q)]
  if (any(bad)) {
    stop("PNWNAmet's accumulated annual flow is not the pilot's at ",
         paste0(names(q)[bad], " (", got[bad], " against ", want[names(q)][bad], ")", collapse = ", "),
         call. = FALSE)
  }
  sprintf("  %-10s %10s m3/s  pilot's wet acc %10s  equal", names(q), got, want[names(q)])
}

# The pilot report's count of scored gauges with an outlet in a domain (its Domains table).
pilot_with_outlet <- function(lines, domain) {
  h <- grep("^## Domains", lines)
  stopifnot(length(h) == 1L)
  row <- grep(paste0("^", domain, " "), lines[(h + 1L):(h + 6L)], value = TRUE)
  stopifnot(length(row) == 1L)
  as.integer(strsplit(trimws(row), " +")[[1]][3])
}

# Outlet ids and days of a pilot bulk NetCDF (its nc_read(), ids only)
nc_ids <- function(f) {
  nc <- ncdf4::nc_open(f)
  on.exit(ncdf4::nc_close(nc))
  as.integer(trimws(ncdf4::ncvar_get(nc, "basin_name")))
}
