# The manifest the wet_catalog() example reads, inst/extdata/discharge_manifest.json:
# the manifest of the made-up tree that tests/testthat/helper-discharge.R
# builds. Only the manifest ships; its parts' paths exceed the 100 bytes a
# portable tarball holds, so the tests build the tree in a temporary
# directory instead.
#
#   Rscript data-raw/discharge_fixture.R

pkgload::load_all(quiet = TRUE)
source("tests/testthat/helper-discharge.R")
root <- file.path(tempfile("discharge"), "discharge", "fwa", "v1")
dir.create(root, recursive = TRUE)
discharge_fixture_write(root)
stopifnot(file.copy(file.path(root, "manifest.json"), "inst/extdata/discharge_manifest.json", overwrite = TRUE))
