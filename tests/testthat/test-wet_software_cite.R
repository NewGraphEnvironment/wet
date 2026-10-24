test_that("a line prints the DOI only when there is one", {
  x <- wet_software_line("pkg", "1.2.3", "10.1/abc", NULL, "Cite me.")
  expect_identical(x, "- `pkg` 1.2.3, [doi:10.1/abc](https://doi.org/10.1/abc). Cite me.")
  expect_identical(wet_software_line("pkg", "1.2.3", character(0), NULL, "Cite me."), "- `pkg` 1.2.3. Cite me.")
  expect_identical(wet_software_line("pkg", "1.2.3", NULL, NULL, "Cite me."), "- `pkg` 1.2.3. Cite me.")
  # the first of several
  expect_match(wet_software_line("pkg", "1", c("10.1/a", "10.1/b"), NULL, "t"), "doi:10.1/a]", fixed = TRUE)
  expect_no_match(wet_software_line("pkg", "1", c("10.1/a", "10.1/b"), NULL, "t"), "10.1/b", fixed = TRUE)
})

test_that("a commit is printed only for a full git hash", {
  sha <- "14b9c337cdea8c98da98aa5bf76bd189b62640a1"
  expect_identical(wet_software_line("pkg", "1", NULL, sha, "t"), "- `pkg` 1, commit `14b9c33`. t")
  # a CRAN install records its version as RemoteSha; that is no commit
  expect_identical(wet_software_line("duckdb", "1.5.2", NULL, "1.5.2", "t"), "- `duckdb` 1.5.2. t")
  expect_identical(wet_software_line("pkg", "1", NULL, substr(sha, 1, 7), "t"), "- `pkg` 1. t")
  expect_identical(wet_software_line("pkg", "1", NULL, toupper(sha), "t"), "- `pkg` 1. t")
  expect_identical(wet_software_line("pkg", "1", NULL, NA_character_, "t"), "- `pkg` 1. t")
})

test_that("wet is cited by its concept DOI", {
  skip_if_not_installed("knitr")
  x <- wet_software_cite("wet")
  expect_length(x, 1)
  expect_match(x, "^- `wet` ")
  expect_match(x, "[doi:10.5281/zenodo.23305781](https://doi.org/10.5281/zenodo.23305781)", fixed = TRUE)
})

test_that("a package that is not installed stops the citation", {
  skip_if_not_installed("knitr")
  expect_error(wet_software_cite(c("wet", "notapackage.wet110")), "not installed: notapackage.wet110")
  expect_error(wet_software_cite(character(0)))
})
