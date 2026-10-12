shipped_manifest <- function() system.file("extdata", "discharge_manifest.json", package = "wet")

edit_manifest <- function(root, f) {
  p <- file.path(root, "manifest.json")
  m <- jsonlite::read_json(p)
  jsonlite::write_json(f(m), p, auto_unbox = TRUE, pretty = TRUE, digits = NA)
  p
}

test_that("the shipped manifest reads without its parts present", {
  cat <- wet_catalog(shipped_manifest())
  expect_identical(nrow(cat), 3L)
  expect_identical(attr(cat, "id"), "discharge/fwa/v1")
})

test_that("a manifest reads as one row per part, fields from the path", {
  root <- local_discharge_tree()
  cat <- wet_catalog(file.path(root, "manifest.json"))
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
  expect_identical(attr(cat, "source_provenance")$pcic_routed$routed_table, "fixture")
  expect_identical(cat$href, file.path(normalizePath(root), cat$key))
})

test_that("the manifest names each dataset's crate schema at its release", {
  root <- local_discharge_tree()
  m <- jsonlite::read_json(file.path(root, "manifest.json"))
  sch <- m$datasets[[1]]$schema
  expect_identical(sch$file_name, m$datasets[[1]]$dataset)
  expect_identical(sch$url, paste0("https://github.com/NewGraphEnvironment/crate/blob/v0.0.0/inst/extdata/schemas/nge/",
                                   m$datasets[[1]]$dataset, ".yaml"))
})

test_that("a URL manifest resolves hrefs against the URL's directory", {
  local_mocked_bindings(curl_fetch_memory = function(url, ...) {
    list(status_code = 200L, content = readBin(shipped_manifest(), "raw", 1e6))
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
  root <- local_discharge_tree()
  p <- edit_manifest(root, function(m) {
    m$parts[[1]]$scenario <- "ssp245"
    m
  })
  cat <- wet_catalog(p)
  expect_false("ssp245" %in% cat$scenario)
})

test_that("malformed manifests are refused", {
  root <- local_discharge_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts[[1]]$key <- "segment_monthly/historical/part-100.parquet"
    m
  })), "not a part key")
  root <- local_discharge_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts[[1]]$md5 <- "nope"
    m
  })), "md5")
  root <- local_discharge_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts <- list()
    m
  })), "no parts")
  root <- local_discharge_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$sources <- m$sources[1]
    m
  })), "does not describe source wet_balance")
  root <- local_discharge_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$manifest_version <- 2L
    m
  })), "manifest_version")
  root <- local_discharge_tree()
  expect_error(wet_catalog(edit_manifest(root, function(m) {
    m$parts[[2]]$key <- m$parts[[1]]$key
    m
  })), "twice")
  expect_error(wet_catalog(file.path(tempdir(), "absent.json")), "no manifest")
})

test_that("the writer refuses a tree it cannot describe", {
  root <- local_discharge_tree()
  srcs <- discharge_fixture_sources()
  w <- function(...) {
    # replaced, not merged: modifyList() would merge a shorter `sources` into the default
    args <- list(root = root, id = "discharge/fwa/v1", drainage = c("100" = "x"),
                 sources = srcs, provenance = list(), crate_version = "0.0.0")
    args[names(list(...))] <- list(...)
    do.call(wet_manifest_write, args)
  }
  expect_error(w(drainage = c("200" = "x")), "no drainage label for code 100")
  expect_error(w(sources = srcs[1]), "describe each source")
  expect_error(w(id = "discharge/fwa"), "tree ID")
  file.create(file.path(root, "segment_monthly", "stray.parquet"))
  expect_error(w(), "not a part key")
})

test_that("verify passes a matching tree and names what differs", {
  root <- local_discharge_tree()
  cat <- wet_catalog(file.path(root, "manifest.json"))
  expect_true(all(wet_catalog_verify(cat)$ok))
  cat$md5[1] <- strrep("0", 32)
  cat$bytes[2] <- 1
  unlink(cat$href[3])
  expect_identical(wet_catalog_verify(cat)$reason, c("md5 differs", "size differs", "missing"))
})

test_that("verify reads a URL part's size and ETag from an anonymous HEAD", {
  cat <- wet_catalog(shipped_manifest())[1:2, ]
  cat$href <- paste0("https://example.org/", cat$key)
  heads <- list(
    sprintf('HTTP/1.1 200 OK\r\nContent-Length: %.0f\r\nETag: "%s"\r\n\r\n', cat$bytes[1], cat$md5[1]),
    sprintf('HTTP/1.1 200 OK\r\nContent-Length: %.0f\r\nETag: "%s-3"\r\n\r\n', cat$bytes[2], cat$md5[2])
  )
  i <- 0L
  local_mocked_bindings(curl_fetch_memory = function(url, handle, ...) {
    i <<- i + 1L
    list(status_code = 200L, headers = charToRaw(heads[[i]]))
  }, .package = "curl")
  v <- wet_catalog_verify(cat)
  expect_identical(v$ok, c(TRUE, FALSE))
  expect_match(v$reason[2], "is not the md5")
})
