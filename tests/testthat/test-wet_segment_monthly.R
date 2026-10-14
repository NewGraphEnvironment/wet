# The fixture tree (helper-discharge.R): segments 701001 and 701002 in SALR,
# both sources, months 0-12. Read from its parquet parts, from Postgres after
# wet_db_load() into a throwaway schema, and fwapg's routed table.

fixture_catalog <- function(env = parent.frame()) {
  root <- local_discharge_tree(env)
  wet_catalog(file.path(root, "manifest.json"))
}

fixture_values <- function() {
  parts <- discharge_fixture_parts()
  seg <- parts[grepl("^segment_monthly", names(parts))]
  src <- sub(".*source=([a-z_]+)/.*", "\\1", names(seg))
  out <- do.call(rbind, Map(function(d, s) data.frame(d[c("linear_feature_id", "month", "q_m3s")], source = s),
                            seg, src))
  rownames(out) <- NULL
  out
}

seg_ds <- "discharge/fwa/v1/segment_monthly"

test_that("the parquet parts give each source's months 0-12, in the station family's shape", {
  cat <- fixture_catalog()
  out <- wet_segment_monthly(NULL, c(701002, 701001), catalog = cat)
  expect_named(out, c("linear_feature_id", "month", "q_m3s", "source"))
  expect_type(out$linear_feature_id, "integer")
  expect_type(out$month, "integer")
  expect_identical(nrow(out), 52L)
  # ordered by source as asked, segment as given, month
  expect_identical(out$source, rep(c("pcic_routed", "wet_balance"), each = 26))
  expect_identical(out$linear_feature_id, rep(rep(c(701002L, 701001L), each = 13), 2))
  expect_identical(out$month, rep(0:12, 4))
  fx <- fixture_values()
  key <- function(d) paste(d$source, d$linear_feature_id, d$month)
  expect_equal(out$q_m3s, fx$q_m3s[match(key(out), key(fx))])
  one <- wet_segment_monthly(NULL, 701001, source = "wet_balance", catalog = cat)
  expect_identical(unique(one$source), "wet_balance")
  expect_identical(nrow(one), 13L)
})

test_that("a missing segment comes back as 13 NA rows, and duplicates once", {
  cat <- fixture_catalog()
  out <- wet_segment_monthly(NULL, c(701001, 999, 701001), source = "pcic_routed", catalog = cat)
  expect_identical(nrow(out), 26L)
  expect_identical(out$linear_feature_id, rep(c(701001L, 999L), each = 13))
  expect_true(all(is.na(out$q_m3s[out$linear_feature_id == 999L])))
  expect_false(anyNA(out$q_m3s[out$linear_feature_id == 701001L]))
  # a group that does not hold the segment reads as missing, not as an error
  g <- wet_segment_monthly(NULL, 701001, source = "pcic_routed", groups = "BULK", catalog = cat)
  expect_true(all(is.na(g$q_m3s)))
  g <- wet_segment_monthly(NULL, 701001, source = "pcic_routed", groups = c("BULK", "SALR"), catalog = cat)
  expect_false(anyNA(g$q_m3s))
})

test_that("bad arguments and absent sources stop with the name", {
  cat <- fixture_catalog()
  expect_error(wet_segment_monthly(NULL, c(701001, NA), catalog = cat), "segments")
  expect_error(wet_segment_monthly(NULL, 701001.5, catalog = cat), "segments")
  expect_error(wet_segment_monthly(NULL, "701001", catalog = cat), "segments")
  expect_error(wet_segment_monthly(NULL, 701001, source = "pcic_gridded", catalog = cat), "pcic_gridded")
  expect_error(wet_segment_monthly(NULL, 701001, scenario = "ssp585", catalog = cat), "ssp585")
  no_bal <- cat[cat$source != "wet_balance", ]
  expect_error(wet_segment_monthly(NULL, 701001, catalog = no_bal), "wet_balance")
  expect_error(wet_segment_monthly(NULL, 701001, groups = NA, catalog = cat), "groups")
  expect_error(wet_segment_monthly(NULL, 701001, from = "fwapg"), "conn")
})

test_that("zero segments give zero rows", {
  cat <- fixture_catalog()
  out <- wet_segment_monthly(NULL, integer(), catalog = cat)
  expect_identical(nrow(out), 0L)
  expect_named(out, c("linear_feature_id", "month", "q_m3s", "source"))
})

test_that("two rows for one segment, month and source are refused", {
  cat <- fixture_catalog()
  dup <- cat[rep(which(cat$source == "pcic_routed" & grepl("segment", cat$dataset)), 2), ]
  expect_error(wet_segment_monthly(NULL, 701001, source = "pcic_routed", catalog = dup), "more than one")
})

# ---- Postgres --------------------------------------------------------------------------------------

local_pg_dataset <- function(conn, env = parent.frame(), ...) {
  cat <- fixture_catalog(env)
  digits <- as.integer(strsplit(as.character(Sys.getpid()), "")[[1]])
  schema <- paste0("wet_test_", paste(letters[digits + 1L], collapse = ""))
  cat$dataset <- sub("^discharge/", paste0(schema, "/"), cat$dataset)
  withr::defer(DBI::dbExecute(conn, sprintf("DROP SCHEMA IF EXISTS %s CASCADE", schema)), envir = env)
  ds <- paste0(schema, "/fwa/v1/segment_monthly")
  wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir(.local_envir = env), ...)
  list(catalog = cat, dataset = ds)
}

test_that("the Postgres table after wet_db_load() reads the same as the parts", {
  conn <- local_fwapg()
  pg <- local_pg_dataset(conn)
  ids <- c(701002, 999, 701001)
  from_pg <- wet:::wet_segment_read(conn, pg$dataset, ids, c("wet_balance", "pcic_routed"), "published",
                                    "historical", NULL, NULL)
  from_pq <- wet:::wet_segment_read(NULL, pg$dataset, ids, c("wet_balance", "pcic_routed"), "published",
                                    "historical", NULL, pg$catalog)
  expect_identical(nrow(from_pg), 78L)
  expect_equal(from_pg, from_pq)
  expect_identical(sum(is.na(from_pg$q_m3s)), 26L)
  g <- wet:::wet_segment_read(conn, pg$dataset, 701001, "pcic_routed", "published", "historical", "BULK", NULL)
  expect_true(all(is.na(g$q_m3s)))
})

test_that("a table loaded as a subset warns, and a missing table names wet_db_load()", {
  conn <- local_fwapg()
  pg <- local_pg_dataset(conn, pick_only = TRUE)
  expect_warning(
    out <- wet:::wet_segment_read(conn, pg$dataset, 701001, "pcic_routed", "published", "historical", NULL, NULL),
    "subset"
  )
  expect_false(anyNA(out$q_m3s))
  expect_error(wet:::wet_segment_read(conn, "wet_test_nothere/fwa/v1/segment_monthly", 701001, "pcic_routed",
                                      "published", "historical", NULL, NULL),
               "wet_test_nothere.fwa_v1_segment_monthly.*wet_db_load")
})

test_that("fwapg's routed table gives its months, and month 0 as their plain mean", {
  conn <- local_fwapg()
  ref <- DBI::dbGetQuery(conn, "SELECT month, q_m3s FROM whse_basemapping.fwa_stream_networks_discharge_monthly
                                WHERE linear_feature_id = 17094080 ORDER BY month")
  skip_if(nrow(ref) != 12, "no routed months for 17094080")
  out <- wet_segment_monthly(conn, c(17094080, 1), source = "pcic_routed", from = "fwapg")
  expect_identical(nrow(out), 26L)
  b <- out[out$linear_feature_id == 17094080L, ]
  expect_identical(b$month, 0:12)
  expect_equal(b$q_m3s[-1], ref$q_m3s)
  expect_equal(b$q_m3s[1], mean(ref$q_m3s))
  expect_true(all(is.na(out$q_m3s[out$linear_feature_id == 1L])))
  expect_error(wet_segment_monthly(conn, 17094080, source = "wet_balance", from = "fwapg"), "wet_balance")
  expect_error(wet_segment_monthly(conn, 17094080, source = "pcic_routed", from = "fwapg", scenario = "ssp585"),
               "historical")
})

test_that("fwapg's month 0 is NA unless all twelve months have flow", {
  d <- data.frame(linear_feature_id = c(rep(1L, 12), rep(2L, 11), rep(3L, 12)),
                  month = c(1:12, 1:11, 1:12), q_m3s = c(1:12, 1:11, c(1:11, NA)))
  expect_identical(wet:::wet_segment_annual(d)$q_m3s, c(6.5, NA, NA))
})

test_that("a missing fwapg table names the fork that loads it", {
  conn <- local_fwapg()
  local_mocked_bindings(wet_segment_sources = function(dataset) {
    data.frame(from = "fwapg", source = "pcic_routed", location = "whse_basemapping.no_such_table",
               origin = "the NewGraphEnvironment fork of fwapg")
  })
  expect_error(wet_segment_monthly(conn, 17094080, source = "pcic_routed", from = "fwapg"),
               "no_such_table.*NewGraphEnvironment fork")
})
