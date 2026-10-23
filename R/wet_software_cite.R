#' The "Software and citation" lines of an article
#'
#' One markdown bullet per package: its name in code font, the installed
#' version, the concept DOI where its citation carries one, the commit where
#' the install recorded a full git hash, and its text citation. The articles
#' call it in their closing section, so the citations are computed at render
#' and never drift from what ran.
#'
#' Each package's citation record (its `inst/CITATION`, or its DESCRIPTION) is
#' written as BibTeX with `knitr::write_bib()` first, so a package whose
#' record cannot be written stops the render rather than printing a line
#' without it.
#'
#' @param pkgs Character. Installed package names, in the order to print.
#' @return Character, one markdown bullet per package.
#' @noRd
wet_software_cite <- function(pkgs) {
  stopifnot(is.character(pkgs), length(pkgs) > 0, !anyNA(pkgs))
  if (!requireNamespace("knitr", quietly = TRUE)) {
    stop("wet_software_cite() needs the knitr package", call. = FALSE)
  }
  have <- vapply(pkgs, requireNamespace, NA, quietly = TRUE)
  if (!all(have)) {
    stop("not installed: ", paste(pkgs[!have], collapse = ", "), call. = FALSE)
  }
  bib <- tempfile(fileext = ".bib")
  on.exit(unlink(bib), add = TRUE)
  knitr::write_bib(pkgs, file = bib)
  if (!file.exists(bib) || length(readLines(bib, warn = FALSE)) == 0) {
    stop("knitr::write_bib() wrote no citation for ", paste(pkgs, collapse = ", "), call. = FALSE)
  }
  vapply(pkgs, function(p) {
    d <- utils::packageDescription(p)
    ct <- utils::citation(p)
    doi <- unlist(lapply(seq_along(ct), function(i) ct[[i]]$doi))
    wet_software_line(p, d$Version, doi, d$RemoteSha, paste(format(ct[[1]], style = "text"), collapse = " "))
  }, "", USE.NAMES = FALSE)
}

#' One package's citation line
#'
#' @param pkg,version Character scalars.
#' @param doi Character, the package's DOIs; the first is printed, none when empty.
#' @param sha The install's `RemoteSha`, printed as a commit only when it is a
#'   40-character hex hash (a CRAN install records its version there).
#' @param text Character scalar, the text citation.
#' @return Character scalar, a markdown bullet.
#' @noRd
wet_software_line <- function(pkg, version, doi, sha, text) {
  doi_text <- if (length(doi)) sprintf(", [doi:%s](https://doi.org/%s)", doi[1], doi[1]) else ""
  commit <- if (is.character(sha) && length(sha) == 1 && grepl("^[0-9a-f]{40}$", sha)) {
    sprintf(", commit `%s`", substr(sha, 1, 7))
  } else {
    ""
  }
  sprintf("- `%s` %s%s%s. %s", pkg, version, doi_text, commit, text)
}
