# Two province runs' contents, file by file (#24).
#
#   Rscript scripts/wb_run_compare.R data/wb/_pre163/92b893c4da data/wb/<new key>
#
# Compares what scripts/wb_province.R writes into a run, and nothing else:
# sample/ and upstream/ (every file), layers.tif, in_bc.tif, lc_ratios.csv
# and ex_filled_cells.txt. A run's fits (fit_*), set-asides (_pre*) and
# sample_times.txt (wall-clock timings) are not compared. Every rds must be
# identical() after readRDS, every raster's names, grid and values identical,
# and every other file's lines identical. It reports every difference, file
# sets included, without stopping at the first, and exits 1 on any, 0 when
# the runs hold the same values.
#
# scripts/wb_upstream_order.R is the other check on two runs: it replays
# their stored row orders through the current sums, where this compares what
# they hold. #24 also asked for tracked reports compared as line sets; a
# rescore under unchanged scoring code does that more strictly, since each
# report must then equal the committed one byte for byte apart from its
# "province run:" line (#21, #163).
# Needs whole runs (the machine with the full runs, not a reduced bundle).
# Prints its result and writes nothing.

runs <- commandArgs(trailingOnly = TRUE)
if (length(runs) != 2L || !all(dir.exists(runs))) stop("name two province run directories")
parts <- c("sample", "upstream", "layers.tif", "in_bc.tif", "lc_ratios.csv", "ex_filled_cells.txt")
files_of <- function(run) {
  f <- unlist(lapply(parts, function(p) {
    path <- file.path(run, p)
    if (dir.exists(path)) file.path(p, list.files(path, recursive = TRUE, all.files = TRUE))
    else if (file.exists(path)) p
  }))
  sort(f, method = "radix")
}
# a part neither run holds is not "the same": two reduced bundles holding
# upstream/ alone would otherwise compare as identical
absent <- parts[!file.exists(file.path(runs[1], parts)) & !file.exists(file.path(runs[2], parts))]
if (length(absent)) stop("neither run holds ", paste(absent, collapse = ", "), ": not two province runs")
fa <- files_of(runs[1])
fb <- files_of(runs[2])
problems <- character()
note <- function(...) problems <<- c(problems, paste0(...))
for (f in setdiff(fa, fb)) note("only in the first run: ", f)
for (f in setdiff(fb, fa)) note("only in the second run: ", f)

# what differs between two values read from one rds, in a few words
describe <- function(a, b) {
  if (!identical(class(a), class(b))) return(sprintf("class %s against %s", class(a)[1], class(b)[1]))
  if (!is.data.frame(a)) return("values differ")
  out <- character()
  na <- setdiff(names(a), names(b))
  nb <- setdiff(names(b), names(a))
  if (length(na)) out <- c(out, paste("columns only in the first:", paste(na, collapse = ", ")))
  if (length(nb)) out <- c(out, paste("columns only in the second:", paste(nb, collapse = ", ")))
  if (nrow(a) != nrow(b)) {
    out <- c(out, sprintf("rows %d against %d", nrow(a), nrow(b)))
  } else {
    both <- intersect(names(a), names(b))
    d <- both[!vapply(both, function(k) identical(a[[k]], b[[k]]), TRUE)]
    if (length(d)) out <- c(out, paste("columns differing:", paste(d, collapse = ", ")))
    if (!length(out) && !identical(names(a), names(b))) out <- "column order differs"
  }
  if (!length(out)) out <- "attributes differ"
  paste(out, collapse = "; ")
}

n <- c(rds = 0L, tif = 0L, text = 0L)
same <- c(rds = 0L, tif = 0L, text = 0L)
bytes_same <- 0L
n_ws <- 0
for (f in intersect(fa, fb)) {
  a <- file.path(runs[1], f)
  b <- file.path(runs[2], f)
  if (identical(unname(tools::md5sum(a)), unname(tools::md5sum(b)))) bytes_same <- bytes_same + 1L
  if (grepl("[.]rds$", f)) {
    n[["rds"]] <- n[["rds"]] + 1L
    xa <- readRDS(a)
    xb <- readRDS(b)
    if (startsWith(f, "upstream/") && is.data.frame(xa)) n_ws <- n_ws + nrow(xa)
    if (identical(xa, xb)) same[["rds"]] <- same[["rds"]] + 1L else note(f, ": ", describe(xa, xb))
  } else if (grepl("[.]tif$", f)) {
    n[["tif"]] <- n[["tif"]] + 1L
    ra <- terra::rast(a)
    rb <- terra::rast(b)
    why <- character()
    if (!identical(names(ra), names(rb))) {
      why <- c(why, sprintf("layers only in the first: %s; only in the second: %s",
                            paste(setdiff(names(ra), names(rb)), collapse = ", "),
                            paste(setdiff(names(rb), names(ra)), collapse = ", ")))
    }
    if (!terra::compareGeom(ra, rb, lyrs = FALSE, stopOnError = FALSE)) {
      why <- c(why, "grids differ")
    } else {
      both <- intersect(names(ra), names(rb))
      d <- both[!vapply(both, function(k) identical(terra::values(ra[[k]]), terra::values(rb[[k]])), TRUE)]
      if (length(d)) why <- c(why, paste("values differ in", paste(d, collapse = ", ")))
    }
    if (length(why)) note(f, ": ", paste(why, collapse = "; ")) else same[["tif"]] <- same[["tif"]] + 1L
  } else {
    n[["text"]] <- n[["text"]] + 1L
    if (identical(readLines(a, warn = FALSE), readLines(b, warn = FALSE))) {
      same[["text"]] <- same[["text"]] + 1L
    } else {
      note(f, ": lines differ")
    }
  }
}

cat(sprintf("first:  %s\nsecond: %s\n", runs[1], runs[2]))
cat(sprintf("files compared: %d of %d and %d (%d byte-identical)\n",
            length(intersect(fa, fb)), length(fa), length(fb), bytes_same))
cat(sprintf("rds identical(): %d of %d (upstream watersheds in the first run: %d)\n",
            same[["rds"]], n[["rds"]], n_ws))
cat(sprintf("rasters identical: %d of %d\n", same[["tif"]], n[["tif"]]))
cat(sprintf("text identical: %d of %d\n", same[["text"]], n[["text"]]))
if (length(problems)) {
  cat(sprintf("DIFFER (%d):\n", length(problems)), paste0("  ", problems, "\n"), sep = "")
  quit(status = 1)
}
cat("IDENTICAL\n")
