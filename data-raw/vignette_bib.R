# Write an article's references (data-raw/vignette_bib.R)
# ---------------------------------------------------------------------------
# An article's references, written from the Zotero group library and the
# packages' own citations, so the article builds where Zotero is not (pkgdown
# in CI, R CMD check). #145; #148 and #152 run it on the other articles.
#
#   Rscript data-raw/vignette_bib.R vignettes/flow-departure-normal.Rmd
#
# Writes the .bib beside the article, under the article's name.
#
# WHY / DESIGN NOTES:
#   - THE KEYS ARE THE ARTICLE'S. rbbt reads the citation keys out of the Rmd
#     (code chunks and inline R skipped). A key that names an installed package
#     (`base` for R itself: rbbt does not detect a one-letter key) is that package's own first citation() entry: the one
#     its authors ask for (ggplot2's book, wet's concept DOI), not knitr's
#     write_bib(), which writes the DESCRIPTION entry and drops wet's DOI.
#     Every other key is exported by Better BibTeX from the group library
#     (Zotero's local library 9, group 4733734). A key neither returns stops
#     the script, so the article cannot build with a reference missing.
#   - NO VERSION IN THE FILE. A package entry's `version` and `note` go, so the
#     committed file does not change with every install; the article prints
#     our packages' version and commit at render.
#   - TITLES ARE BRACED where the style would re-case them: a package entry's
#     name ("{sf}: Simple Features for R"), so pandoc does not print "Sf".
#   - ONLY WHAT A READER NEEDS. Better BibTeX writes each attachment's local
#     path (`file`), and the abstract, keywords and access dates; none is kept.
#     A timestamp date is cut to its day. An organisation is braced, so it
#     prints as one name.
#
# INPUT:  the article; Zotero running with Better BibTeX and synced with the
#         group library (probe it with curl -A curl/8: a browser user agent,
#         which ~/.curlrc may set, gets an empty reply)
# OUTPUT: <article>.bib beside the article
# RUN:    from the repo root, after any change to the article's citations
# ---------------------------------------------------------------------------
library_id <- 9   # Zotero's local id of the NewGraphEnvironment group library (group 4733734)

bib_package <- function(key) {
  e <- utils::toBibtex(utils::citation(key)[[1]])
  e[1] <- sub("\\{.*$", paste0("{", key, ","), e[1])
  e <- e[!grepl("^\\s*(version|note) = ", e)]
  # brace the title so the style keeps the package's case: the name, or the whole title
  # where it does not start with the name (R's, a book's)
  at <- grep("^\\s*title = \\{", e)
  if (length(at) != 1) stop(key, ": expected one title line", call. = FALSE)
  e[at] <- sub("^(\\s*title = \\{)(.*)(\\},?)$", "\\1{\\2}\\3", e[at])
  paste(e, collapse = "\n")
}

bib_write <- function(rmd) {
  keys <- sort(unique(rbbt::bbt_detect_citations(rmd)))
  if (!length(keys)) stop("no citation in ", rmd, call. = FALSE)
  is_pkg <- vapply(keys, function(k) nzchar(system.file(package = k)), TRUE)
  pkg <- vapply(keys[is_pkg], bib_package, "")
  lit <- character()
  if (any(!is_pkg)) {
    bib <- paste(rbbt::bbt_bib(keys[!is_pkg], translator = "biblatex", library_id = library_id), collapse = "\n")
    lit <- unique(regmatches(bib, gregexpr("(?s)@[a-zA-Z]+\\{[^,]+,.*?\\n\\}", bib, perl = TRUE))[[1]])
    names(lit) <- sub("^@[a-zA-Z]+\\{([^,]+),.*$", "\\1", sub("\n.*", "", lit))
    if (anyDuplicated(names(lit))) stop("Zotero returned two entries for ", names(lit)[duplicated(names(lit))])
    lit <- gsub("\n  (file|abstract|keywords|urldate|origdate) = \\{[^\n]*\\},?(?=\n)", "", lit, perl = TRUE)
    lit <- gsub("(\n  date = \\{[0-9-]{4,10})T[^}]*\\}", "\\1}", lit, perl = TRUE)
    lit <- gsub("\n  organization = \\{([^{}\n]*)\\}(,?)(?=\n)", "\n  organization = {{\\1}}\\2", lit, perl = TRUE)
    # software held in Zotero as a repository: pandoc prints @software's full date ("Released
    # January 1") and re-cases its title ("Smnorris/Fwapg"), so it becomes @misc dated by year,
    # titled by the repository's own name, braced
    sw <- grepl("^@software\\{", lit)
    repo <- sub("^.*\n  url = \\{https://github\\.com/[^/]+/([^/}]+)/?\\},?\n.*$", "\\1", lit[sw])
    no_repo <- repo == lit[sw]
    if (any(no_repo)) stop("software without a GitHub url: ", paste(names(lit)[sw][no_repo], collapse = ", "))
    lit[sw] <- sub("^@software\\{", "@misc{", lit[sw])
    lit[sw] <- sub("\n  date = \\{([0-9]{4})[^}]*\\}", "\n  date = {\\1}", lit[sw])
    lit[sw] <- mapply(function(e, r) {
      at <- regexpr("\\n  title = \\{[^\\n]*\\},(?=\\n)", e, perl = TRUE)
      if (at < 0) stop("no title line in a software entry", call. = FALSE)
      paste0(substr(e, 1, at - 1), "\n  title = {{", r, "}},", substr(e, at + attr(at, "match.length"), nchar(e)))
    }, lit[sw], repo, USE.NAMES = FALSE)
  }
  entries <- c(pkg, lit)
  got <- c(keys[is_pkg], names(lit))
  if (!setequal(got, keys)) {
    stop(rmd, ": no entry for ", paste(setdiff(keys, got), collapse = ", "),
         if (length(setdiff(got, keys))) paste0("; unasked ", paste(setdiff(got, keys), collapse = ", ")),
         call. = FALSE)
  }
  names(entries) <- got
  # any field whose value starts with / is a local path (urls and dois are https)
  if (any(grepl("file = |= \\{/", entries))) stop("a local path is left in an entry", call. = FALSE)
  out <- sub("\\.Rmd$", ".bib", rmd)
  writeLines(c(paste0("% written by data-raw/vignette_bib.R for ", basename(rmd),
                      " from the packages' citation() and Zotero (group library); do not edit"),
               "", paste0(entries[sort(names(entries))], "\n")), out)
  message(sprintf("%s: %d entries (%s)", out, length(entries), paste(sort(names(entries)), collapse = ", ")))
  invisible(out)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1 || !file.exists(args[1])) {
  stop("usage: Rscript data-raw/vignette_bib.R <article.Rmd>", call. = FALSE)
}
bib_write(args[1])
