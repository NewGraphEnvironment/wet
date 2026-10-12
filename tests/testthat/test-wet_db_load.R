# The bundled fixture tree, loaded into a throwaway schema in the local fwapg.
# The dataset ID is rewritten so the table lands in `wet_test_<n>`, never in
# the real `discharge` schema.

local_load_catalog <- function(conn, env = parent.frame()) {
  root <- local_discharge_tree(env)
  cat <- wet_catalog(file.path(root, "manifest.json"))
  # letters only: a dataset ID's variable admits no digits
  digits <- as.integer(strsplit(as.character(Sys.getpid()), "")[[1]])
  schema <- paste0("wet_test_", paste(letters[digits + 1L], collapse = ""))
  cat$dataset <- sub("^discharge/", paste0(schema, "/"), cat$dataset)
  withr::defer(DBI::dbExecute(conn, sprintf("DROP SCHEMA IF EXISTS %s CASCADE", schema)), envir = env)
  cat
}

test_that("a scenario loads, with the Hive keys as columns, and fresh's subquery gets one row per segment", {
  conn <- local_fwapg()
  cat <- local_load_catalog(conn)
  ds <- grep("segment_monthly$", unique(cat$dataset), value = TRUE)
  out <- wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir())
  expect_identical(sum(out$rows), 52)
  tbl <- paste0(sub("/.*", "", ds), ".fwa_v1_segment_monthly")
  x <- DBI::dbGetQuery(conn, paste("SELECT * FROM", tbl))
  expect_identical(nrow(x), 52L)
  expect_setequal(paste(x$forcing, x$source), c("PNWNAmet pcic_routed", "climr wet_balance"))
  expect_type(x$pick, "logical")
  sql_fresh <- "select linear_feature_id, q_m3s as mad_m3s from %s where scenario = 'historical' and month = 0 and pick"
  fresh <- DBI::dbGetQuery(conn, sprintf(sql_fresh, tbl))
  expect_identical(sort(fresh$linear_feature_id), c(701001L, 701002L))
  expect_identical(fresh$mad_m3s[order(fresh$linear_feature_id)], c(2.4, 0.6))
  sql_key <- "SELECT a.attname FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = '%s'::regclass AND i.indisprimary"
  key <- DBI::dbGetQuery(conn, sprintf(sql_key, tbl))$attname
  expect_setequal(key, c("scenario", "forcing", "source", "linear_feature_id", "month", "period"))
  idx <- DBI::dbGetQuery(conn, sprintf("SELECT indexdef FROM pg_indexes WHERE schemaname = '%s'", sub("/.*", "", ds)))$indexdef
  expect_true(any(grepl("(scenario, linear_feature_id) WHERE ((month = 0) AND pick)", idx, fixed = TRUE)))
  expect_match(DBI::dbGetQuery(conn, sprintf("SELECT obj_description('%s'::regclass) AS d", tbl))$d,
               "scenario historical last loaded from")
})

test_that("a reload replaces the scenario rather than adding to it, and subsets apply", {
  conn <- local_fwapg()
  cat <- local_load_catalog(conn)
  ds <- grep("segment_monthly$", unique(cat$dataset), value = TRUE)
  tbl <- paste0(sub("/.*", "", ds), ".fwa_v1_segment_monthly")
  cache <- withr::local_tempdir()
  wet_db_load(conn, cat, ds, cache_dir = cache)
  wet_db_load(conn, cat, ds, cache_dir = cache)
  expect_identical(DBI::dbGetQuery(conn, paste("SELECT count(*)::int AS n FROM", tbl))$n, 52L)
  wet_db_load(conn, cat, ds, months = 0, pick_only = TRUE, cache_dir = cache)
  x <- DBI::dbGetQuery(conn, paste("SELECT * FROM", tbl))
  expect_identical(nrow(x), 2L)
  expect_true(all(x$pick & x$month == 0L))
})

test_that("a part whose bytes differ from the manifest is refused and nothing is written", {
  conn <- local_fwapg()
  cat <- local_load_catalog(conn)
  ds <- grep("segment_monthly$", unique(cat$dataset), value = TRUE)
  tbl <- paste0(sub("/.*", "", ds), ".fwa_v1_segment_monthly")
  wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir())
  bad <- cat
  bad$md5[bad$source == "wet_balance" & bad$dataset == ds] <- strrep("0", 32)
  expect_error(wet_db_load(conn, bad, ds, months = 0, cache_dir = withr::local_tempdir()),
               "does not match the manifest")
  expect_identical(DBI::dbGetQuery(conn, paste("SELECT count(*)::int AS n FROM", tbl))$n, 52L)
})

test_that("the watershed dataset loads, and pick_only is refused there", {
  conn <- local_fwapg()
  cat <- local_load_catalog(conn)
  ds <- grep("watershed_monthly$", unique(cat$dataset), value = TRUE)
  out <- wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir())
  expect_identical(sum(out$rows), 13)
  expect_error(wet_db_load(conn, cat, ds, pick_only = TRUE, cache_dir = withr::local_tempdir()), "no `pick`")
})

test_that("arguments are checked before anything is written", {
  expect_error(wet_dataset_table("discharge/fwa/segment_monthly"), "dataset ID")
  expect_identical(wet_dataset_table("discharge/fwa/v1/segment_monthly"),
                   c(schema = "discharge", table = "fwa_v1_segment_monthly"))
  cat <- wet_catalog(system.file("extdata", "discharge_manifest.json", package = "wet"))
  expect_error(wet_db_load(NULL, cat, scenario = "ssp245"), "no parts for discharge/fwa/v1/segment_monthly ssp245")
  expect_error(wet_db_load(NULL, cat, months = 13))
})

test_that("a URL part is fetched into the cache, checked, and reused while it matches", {
  root <- local_discharge_tree()
  cat <- wet_catalog(file.path(root, "manifest.json"))
  part <- cat[1, ]
  src <- part$href
  part$href <- paste0("https://example.org/discharge/fwa/v1/", part$key)
  calls <- 0L
  local_mocked_bindings(curl_fetch_disk = function(url, path, ...) {
    calls <<- calls + 1L
    file.copy(src, path, overwrite = TRUE)
    list(status_code = 200L)
  }, .package = "curl")
  cache <- withr::local_tempdir()
  f <- wet_part_fetch(part, cache)
  expect_identical(unname(tools::md5sum(f)), part$md5)
  expect_true(startsWith(f, file.path(cache, "discharge/fwa/v1")))
  wet_part_fetch(part, cache)
  expect_identical(calls, 1L)
  local_mocked_bindings(curl_fetch_disk = function(url, path, ...) list(status_code = 404L), .package = "curl")
  expect_error(wet_part_fetch(part, withr::local_tempdir()), "HTTP 404")
})

test_that("a failure partway through a load leaves the previous rows", {
  conn <- local_fwapg()
  cat <- local_load_catalog(conn)
  ds <- grep("segment_monthly$", unique(cat$dataset), value = TRUE)
  tbl <- paste0(sub("/.*", "", ds), ".fwa_v1_segment_monthly")
  wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir())
  appended <- 0L
  real_append <- DBI::dbAppendTable
  local_mocked_bindings(dbAppendTable = function(conn, name, value, ...) {
    appended <<- appended + 1L
    if (appended == 2L) stop("connection lost")
    real_append(conn, name, value, ...)
  }, .package = "DBI")
  expect_error(wet_db_load(conn, cat, ds, months = 0, cache_dir = withr::local_tempdir()), "connection lost")
  expect_identical(appended, 2L)
  expect_identical(DBI::dbGetQuery(conn, paste("SELECT count(*)::int AS n FROM", tbl))$n, 52L)
})

test_that("two picked rows for one segment and month are refused, and the load rolled back", {
  conn <- local_fwapg()
  cat <- local_load_catalog(conn)
  ds <- grep("segment_monthly$", unique(cat$dataset), value = TRUE)
  tbl <- paste0(sub("/.*", "", ds), ".fwa_v1_segment_monthly")
  wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir())
  # the balance part, rewritten with every row picked
  i <- which(cat$dataset == ds & cat$source == "wet_balance")
  con <- DBI::dbConnect(duckdb::duckdb())
  x <- DBI::dbGetQuery(con, "SELECT * FROM read_parquet(?, hive_partitioning = false)", params = list(cat$href[i]))
  x$pick <- TRUE
  duckdb::duckdb_register(con, "x", x)
  DBI::dbExecute(con, sprintf("COPY x TO '%s' (FORMAT parquet)", cat$href[i]))
  DBI::dbDisconnect(con, shutdown = TRUE)
  cat$bytes[i] <- file.size(cat$href[i])
  cat$md5[i] <- unname(tools::md5sum(cat$href[i]))
  expect_error(wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir()), "more than one picked row")
  expect_identical(DBI::dbGetQuery(conn, paste("SELECT count(*)::int AS n FROM", tbl, "WHERE NOT pick"))$n, 26L)
})
