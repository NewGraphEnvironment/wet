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
# other copy; the VERSION check below is what makes such a copy safe to use.
# Internal, because that backup is not reachable outside NGE.
wet_hydat <- function(release, cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!is.character(release) || length(release) != 1L || is.na(release) || !grepl("^[0-9]{8}$", release)) {
    stop("`release` must be one HYDAT release as YYYYMMDD", call. = FALSE)
  }
  root <- file.path(cache_dir, "hydat")
  dir <- file.path(root, release)
  f <- file.path(dir, "Hydat.sqlite3")
  if (!file.exists(f)) {
    backup <- sprintf("copy Hydat.sqlite3 from the backup at s3://fresh-bc/hydat/%s/ (check its md5) to %s",
                      release, f)
    current <- tryCatch(wet_hydat_remote(), error = function(e) {
      wet_hydat_unavailable("HYDAT ", release, " is not in the cache and wet could not ask ECCC for its ",
                            "current release (", conditionMessage(e), "); ", backup)
    })
    if (!identical(current, release)) {
      wet_hydat_unavailable("HYDAT ", release, " is not in the cache and ECCC serves only HYDAT ", current,
                            "; ", backup)
    }
    wet_hydat_fetch(release, root)
  }
  got <- wet_hydat_release(f)
  if (!identical(got, release)) stop(f, " holds HYDAT ", got, ", not ", release, call. = FALSE)
  f
}

# Download ECCC's current release into a partial directory beside the cache
# entry and move it into place only once its VERSION says it is `release`, so
# an interrupted download or a release ECCC replaced in the meantime never
# lands under a release's name.
wet_hydat_fetch <- function(release, root) {
  partial <- file.path(root, paste0(".", release, ".partial"))
  unlink(partial, recursive = TRUE)
  dir.create(partial, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(partial, recursive = TRUE), add = TRUE)
  wet_hydat_download(partial)
  got <- wet_hydat_release(file.path(partial, "Hydat.sqlite3"))
  if (!identical(got, release)) {
    stop("the download holds HYDAT ", got, ", not ", release, "; ECCC may have just replaced it", call. = FALSE)
  }
  # same directory, so a rename, never a copy
  if (!file.rename(partial, file.path(root, release))) {
    stop("could not move the download into ", file.path(root, release), call. = FALSE)
  }
  invisible(file.path(root, release, "Hydat.sqlite3"))
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
