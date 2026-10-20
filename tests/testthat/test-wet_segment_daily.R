# The fixture tree's daily parts (helper-discharge.R): segments 701001 and
# 701002 in SALR, both sources, days 1-365, one part per source keyed by group.

daily_catalog <- function(env = parent.frame()) {
  root <- local_discharge_tree(env)
  wet_catalog(file.path(root, "manifest.json"))
}

daily_values <- function() {
  parts <- discharge_fixture_parts()
  d <- parts[grepl("^segment_daily", names(parts))]
  src <- sub(".*source=([a-z_]+)/.*", "\\1", names(d))
  out <- do.call(rbind, Map(function(x, s) data.frame(x[c("linear_feature_id", "doy", "q_m3s")], source = s), d, src))
  rownames(out) <- NULL
  out
}

test_that("the daily parts give each source's 365 days, in the monthly reader's shape", {
  cat <- daily_catalog()
  expect_setequal(cat$code[cat$dataset == "discharge/fwa/v1/segment_daily"], "SALR")
  out <- wet_segment_daily(NULL, c(701002, 701001), groups = "SALR", catalog = cat)
  expect_named(out, c("linear_feature_id", "doy", "q_m3s", "source"))
  expect_type(out$doy, "integer")
  expect_identical(nrow(out), 4L * 365L)
  expect_identical(out$source, rep(c("pcic_routed", "wet_balance"), each = 730))
  expect_identical(out$doy, rep(1:365, 4))
  fx <- daily_values()
  key <- function(d) paste(d$source, d$linear_feature_id, d$doy)
  expect_equal(out$q_m3s, fx$q_m3s[match(key(out), key(fx))])
  # what wet_flow_window() does with it
  w <- wet_flow_window(out, data.frame(window = "jan", start = "01-01", end = "01-31"))
  expect_identical(unique(w$basis), "daily")
})

test_that("a read of the daily parts needs groups, and opens only the named groups' parts", {
  cat <- daily_catalog()
  expect_error(wet_segment_daily(NULL, 701001, catalog = cat), "needs `groups`")
  # another group's part that cannot be read: a read of SALR never touches it
  other <- cat[cat$dataset == "discharge/fwa/v1/segment_daily" & cat$source == "pcic_routed", ]
  other$code <- "BULK"
  other$href <- file.path(tempdir(), "no-such-part.parquet")
  cat2 <- rbind(cat, other)
  out <- wet_segment_daily(NULL, 701001, source = "pcic_routed", groups = "SALR", catalog = cat2)
  expect_false(anyNA(out$q_m3s))
  expect_error(wet_segment_daily(NULL, 701001, source = "pcic_routed", groups = "BULK", catalog = cat2))
  # a group with no part reads as missing
  out <- wet_segment_daily(NULL, 701001, source = "pcic_routed", groups = "MORK", catalog = cat)
  expect_identical(nrow(out), 365L)
  expect_true(all(is.na(out$q_m3s)))
})

test_that("a missing segment is 365 NA rows", {
  cat <- daily_catalog()
  out <- wet_segment_daily(NULL, c(999, 701001), source = "wet_balance", groups = "SALR", catalog = cat)
  expect_identical(nrow(out), 730L)
  expect_true(all(is.na(out$q_m3s[out$linear_feature_id == 999L])))
  expect_false(anyNA(out$q_m3s[out$linear_feature_id == 701001L]))
})

test_that("the daily dataset loads into Postgres keyed by doy, for named groups, and reads as the parts", {
  conn <- local_fwapg()
  cat <- daily_catalog()
  digits <- as.integer(strsplit(as.character(Sys.getpid()), "")[[1]])
  schema <- paste0("wet_test_", paste(letters[digits + 1L], collapse = ""))
  cat$dataset <- sub("^discharge/", paste0(schema, "/"), cat$dataset)
  withr::defer(DBI::dbExecute(conn, sprintf("DROP SCHEMA IF EXISTS %s CASCADE", schema)))
  ds <- paste0(schema, "/fwa/v1/segment_daily")
  tbl <- paste0(schema, ".fwa_v1_segment_daily")
  # a group with no part is refused before anything is written
  expect_error(wet_db_load(conn, cat, ds, groups = "BULK", cache_dir = withr::local_tempdir()),
               "no .*segment_daily historical parts for groups BULK")
  out <- wet_db_load(conn, cat, ds, cache_dir = withr::local_tempdir())
  expect_identical(sum(out$rows), 4 * 365)
  sql_key <- "SELECT a.attname FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = '%s'::regclass AND i.indisprimary"
  expect_setequal(DBI::dbGetQuery(conn, sprintf(sql_key, tbl))$attname,
                  c("scenario", "forcing", "source", "linear_feature_id", "doy", "period"))
  idx <- DBI::dbGetQuery(conn, sprintf("SELECT indexdef FROM pg_indexes WHERE schemaname = '%s'", schema))$indexdef
  expect_false(any(grepl("WHERE", idx)))
  comment <- function() DBI::dbGetQuery(conn, sprintf("SELECT obj_description('%s'::regclass) AS d", tbl))$d
  expect_false(grepl("subset", comment()))
  from_pg <- wet:::wet_segment_read(conn, ds, c(701001, 701002), c("pcic_routed", "wet_balance"), "published",
                                    "historical", NULL, NULL)
  from_pq <- wet:::wet_segment_read(NULL, ds, c(701001, 701002), c("pcic_routed", "wet_balance"), "published",
                                    "historical", "SALR", cat)
  expect_equal(from_pg, from_pq)
  # a subset of days and groups is recorded
  wet_db_load(conn, cat, ds, doys = 1:31, groups = "SALR", cache_dir = withr::local_tempdir())
  expect_identical(DBI::dbGetQuery(conn, paste("SELECT count(*)::int AS n FROM", tbl))$n, 4L * 31L)
  expect_match(comment(), "subset doy IN \\(1, 2,.*31\\) AND watershed_group_code IN \\('SALR'\\)")
  expect_error(wet_db_load(conn, cat, ds, doys = 366), "doys")
  # groups with no routed part: loaded as a subset, routed reads as missing;
  # loaded whole, an absent source is an error
  no_rt <- cat[!(cat$dataset == ds & cat$source == "pcic_routed"), ]
  wet_db_load(conn, no_rt, ds, groups = "SALR", cache_dir = withr::local_tempdir())
  expect_warning(
    out <- wet:::wet_segment_read(conn, ds, 701001, c("pcic_routed", "wet_balance"), "published", "historical",
                                  "SALR", NULL),
    "subset")
  expect_true(all(is.na(out$q_m3s[out$source == "pcic_routed"])))
  expect_false(anyNA(out$q_m3s[out$source == "wet_balance"]))
  # a subset of days holds every source it was loaded with, so one absent is an error
  wet_db_load(conn, no_rt, ds, doys = 1:31, cache_dir = withr::local_tempdir())
  expect_error(suppressWarnings(wet:::wet_segment_read(conn, ds, 701001, c("pcic_routed", "wet_balance"), "published",
                                                       "historical", NULL, NULL)),
               "no rows for scenario historical, source pcic_routed")
  wet_db_load(conn, no_rt, ds, cache_dir = withr::local_tempdir())
  expect_error(wet:::wet_segment_read(conn, ds, 701001, c("pcic_routed", "wet_balance"), "published", "historical",
                                      NULL, NULL),
               "no rows for scenario historical, source pcic_routed")
})
