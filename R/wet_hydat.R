# The path to a pinned HYDAT release (#46): `<cache_dir>/hydat/<release>/Hydat.sqlite3`.
#
# tidyhydat's own directory holds whatever release download_hydat() last
# fetched, the user's "latest HYDAT", and wet never writes there. A script that
# must give the same numbers on every machine names its release instead and
# reads it from this per-user cache, one copy shared by every checkout.
#
# A release missing from the cache is downloaded only while ECCC still serves
# it: ECCC keeps only its current release. A superseded one has to be copied in
# by hand, from the private backup at s3://fresh-bc/hydat/<release>/ or any
# other copy; the checks below are what make such a copy safe to use.
# Internal, because that backup is not reachable outside NGE.
wet_hydat <- function(release, cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!is.character(release) || length(release) != 1L || is.na(release) || !grepl("^[0-9]{8}$", release)) {
    stop("`release` must be one HYDAT release as YYYYMMDD", call. = FALSE)
  }
  root <- file.path(cache_dir, "hydat")
  f <- file.path(root, release, "Hydat.sqlite3")
  if (!file.exists(f)) {
    backup <- sprintf("copy Hydat.sqlite3 from the backup at s3://fresh-bc/hydat/%s/ (check its md5) to %s",
                      release, f)
    current <- tryCatch(wet_hydat_remote(), error = function(e) {
      wet_hydat_unavailable("HYDAT ", release, " is not in the cache and wet could not ask ECCC for its ",
                            "current release (", conditionMessage(e), "); ", backup)
    })
    # an answer that is not a release means ECCC's page changed: an error to
    # fix, not a release that cannot be had
    if (!is.character(current) || length(current) != 1L || !grepl("^[0-9]{8}$", current)) {
      stop("ECCC's current HYDAT release read as ", deparse(current), ", not YYYYMMDD", call. = FALSE)
    }
    if (!identical(current, release)) {
      wet_hydat_unavailable("HYDAT ", release, " is not in the cache and ECCC serves only HYDAT ", current,
                            "; ", backup)
    }
    wet_hydat_fetch(release, root)
  }
  wet_hydat_check(f, release)
  f
}

# A cached file must be whole and hold `release`. SQLite refuses most
# truncated files itself, as "malformed"; the size check covers one it reads.
wet_hydat_check <- function(f, release, integrity = FALSE) {
  got <- tryCatch({
    con <- suppressWarnings(wet_hydat_connect(f))
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    # as doubles: both come back as integers, whose product overflows past 2 GiB
    bytes <- as.numeric(DBI::dbGetQuery(con, "PRAGMA page_count")[[1]]) *
      as.numeric(DBI::dbGetQuery(con, "PRAGMA page_size")[[1]])
    if (!isTRUE(bytes == file.size(f))) stop("its pages make ", bytes, " bytes, the file ", file.size(f))
    if (integrity) {
      qc <- DBI::dbGetQuery(con, "PRAGMA quick_check")[[1]]
      if (!identical(qc, "ok")) stop("quick_check: ", paste(utils::head(qc, 3), collapse = "; "))
    }
    wet_hydat_release(f)
  }, error = function(e) {
    stop(f, " is not a whole HYDAT (", conditionMessage(e), "); copy it again", call. = FALSE)
  })
  if (!identical(got, release)) stop(f, " holds HYDAT ", got, ", not ", release, call. = FALSE)
  invisible(f)
}

# Download ECCC's current release into a partial directory of this call's own
# beside the cache entry, and move it into place only once it is whole and its
# VERSION says it is `release`, so an interrupted download or a release ECCC
# replaced in the meantime never lands under a release's name. Two callers
# fetching at once each download; the first rename wins and the second uses it.
wet_hydat_fetch <- function(release, root) {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  stale <- list.files(root, pattern = paste0("^[.]", release, "[.]partial-"), all.files = TRUE, full.names = TRUE)
  unlink(stale[difftime(Sys.time(), file.mtime(stale), units = "days") > 1], recursive = TRUE)
  partial <- tempfile(paste0(".", release, ".partial-"), tmpdir = root)
  dir.create(partial)
  on.exit(unlink(partial, recursive = TRUE), add = TRUE)
  wet_hydat_download(partial)
  tryCatch(wet_hydat_check(file.path(partial, "Hydat.sqlite3"), release, integrity = TRUE),
           error = function(e) stop("the download failed its check: ", conditionMessage(e), call. = FALSE))
  target <- file.path(root, release)
  # a rename onto a directory another run has just filled fails, and that run's copy is used
  if (!suppressWarnings(file.rename(partial, target)) && !file.exists(file.path(target, "Hydat.sqlite3"))) {
    stop("could not move the download into ", target, call. = FALSE)
  }
  invisible(file.path(target, "Hydat.sqlite3"))
}

# The release cannot be had here, as opposed to a cache holding the wrong file:
# a classed error, so a live test can skip on this and on nothing else.
wet_hydat_unavailable <- function(...) {
  stop(structure(class = c("wet_hydat_unavailable", "error", "condition"),
                 list(message = paste0(...), call = NULL)))
}

# The two calls that reach ECCC, kept apart so tests can stand them in.
wet_hydat_remote <- function() {
  if (!requireNamespace("tidyhydat", quietly = TRUE)) stop("install tidyhydat to download HYDAT", call. = FALSE)
  tidyhydat::hy_remote()
}

wet_hydat_download <- function(dir) {
  if (!requireNamespace("tidyhydat", quietly = TRUE)) stop("install tidyhydat to download HYDAT", call. = FALSE)
  tidyhydat::download_hydat(dl_hydat_here = dir, ask = FALSE)
}
