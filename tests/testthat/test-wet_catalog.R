fixture_manifest <- function() {
  system.file("extdata", "discharge", "fwa", "v1", "manifest.json", package = "wet")
}

# a copy of the bundled tree to edit, and its manifest as a list
local_tree <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  file.copy(dirname(fixture_manifest()), dir, recursive = TRUE)
  file.path(dir, "v1")
}
edit_manifest <- function(root, f) {
  p <- file.path(root, "manifest.json")
  m <- jsonlite::read_json(p)
  jsonlite::write_json(f(m), p, auto_unbox = TRUE, pretty = TRUE, digits = NA)
  p
}

test_that("the bundled manifest reads as one row per part, fields from the path", {
  cat <- wet_catalog(fixture_manifest())
  expect_identical(names(cat), c("dataset", "scenario", "forcing", "source", "code", "drainage",
                                 "key", "href", "rows", "bytes", "md5"))
  expect_identical(nrow(cat), 3L)
  expect_setequal(cat$dataset, c("discharge/fwa/v1/segment_monthly", "discharge/fwa/v1/watershed_monthly"))
  r <- cat[cat$source == "pcic_routed", ]
  expect_identical(c(r$scenario, r$forcing, r$code, r$drainage), c("historical", "PNWNAmet", "100", "Fraser River"))
  expect_identical(r$rows, 26)
  expect_true(all(file.exists(cat$href)))
  expect_identical(unname(tools::md5sum(cat$href)), cat$md5)
  expect_identical(attr(cat, "id"), "discharge/fwa/v1")
  expect_setequal(attr(cat, "sources")$source, c("pcic_routed", "wet_balance"))
})

test_that("writing then reading a tree round-trips, with hrefs relative to the manifest", {
  skip_if_not_installed("duckdb")
  root <- local_tree()
  wet_manifest_write(root, "discharge/fwa/v1", drainage = c("100" = "Fraser"),
                     sources = attr(wet_catalog(fixture_manifest()), "sources"),
                     provenance = list(wet_commit = "abc1234"))
  cat <- wet_catalog(file.path(root, "manifest.json"))
  expect_identical(nrow(cat), 3L)
  expect_identical(cat$href, file.path(normalizePath(root), cat$key))
  expect_identical(attr(cat, "provenance")$wet_commit, "abc1234")
  expect_identical(cat$rows, as.numeric(c(26, 26, 13)))
})

test_that("a URL manifest resolves hrefs against the URL's directory", {
  local_mocked_bindings(curl_fetch_memory = function(url, ...) {
    list(status_code = 200L, content = readBin(fixture_manifest(), "raw", 1e6))
  }, .package = "curl")
  cat <- wet_catalog("https://example.org/discharge/fwa/v1/manifest.json")
  expect_true(all(startsWith(cat$href, "https://example.org/discharge/fwa/v1/")))
  expect_true(all(endsWith(cat$href, cat$key)))
})

test_that("an HTTP failure names its status", {
  local_mocked_bindings(curl_fetch_memory = function(url, ...) {
    list(status_code = 403L, content = charToRaw("<Error/>"))
  }, .package = "curl")
  expect_error(wet_catalog("https://example.org/m.json"), "HTTP 403")
})

test_that("a part field that disagrees with its key cannot arise: fields come from the key", {
  root <- local_tree()
  p <- edit_manifest(root, function(m) {
    m$parts[[1]]$scenario <- "ssp245"
    m
  })
  cat <- wet_catalog(p)
  expect_false("ssp245" %in% cat$scenario)
})

test_that("malformed manifests are refused", {
  root <- local_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts[[1]]$key <- "segment_monthly/historical/part-100.parquet"
    m
  })), "not a part key")
  root <- local_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts[[1]]$md5 <- "nope"
    m
  })), "md5")
  root <- local_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts <- list()
    m
  })), "no parts")
  root <- local_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$sources <- m$sources[1]
    m
  })), "does not describe source wet_balance")
  root <- local_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$manifest_version <- 2L
    m
  })), "manifest_version")
  root <- local_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts[[2]]$key <- m$parts[[1]]$key
    m
  })), "twice")
  expect_error(wet_catalog(file.path(tempdir(), "absent.json")), "no manifest")
})

test_that("the writer refuses a tree it cannot describe", {
  skip_if_not_installed("duckdb")
  root <- local_tree()
  srcs <- attr(wet_catalog(fixture_manifest()), "sources")
  expect_error(wet_manifest_write(root, "discharge/fwa/v1", drainage = c("200" = "x"), sources = srcs,
                                  provenance = list()), "no drainage label for code 100")
  expect_error(wet_manifest_write(root, "discharge/fwa/v1", drainage = c("100" = "x"), sources = srcs[1, ],
                                  provenance = list()), "describe each source")
  expect_error(wet_manifest_write(root, "discharge/fwa", drainage = c("100" = "x"), sources = srcs,
                                  provenance = list()), "tree ID")
  file.create(file.path(root, "segment_monthly", "stray.parquet"))
  expect_error(wet_manifest_write(root, "discharge/fwa/v1", drainage = c("100" = "x"), sources = srcs,
                                  provenance = list()), "not a part key")
})
