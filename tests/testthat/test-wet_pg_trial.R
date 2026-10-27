test_that("a migration's own BEGIN; and COMMIT; are stripped and its plpgsql kept", {
  migration <- c(
    "BEGIN;", "", "-- a comment", "DROP FUNCTION f(integer);",
    "CREATE FUNCTION f(x integer) RETURNS integer LANGUAGE plpgsql AS $$",
    "BEGIN", "  IF x > 0 THEN", "    RETURN x;", "  END IF;", "  RETURN 0;", "END", "$$;",
    "", "COMMIT;", ""
  )
  sql <- paste(migration, collapse = "\n")
  body <- wet:::wet_pg_trial_sql(sql)
  lines <- strsplit(body, "\n", fixed = TRUE)[[1]]
  expect_false(any(grepl("^(BEGIN|COMMIT);", lines)))
  expect_true(all(c("BEGIN", "END", "  END IF;", "DROP FUNCTION f(integer);") %in% lines))
  # line numbers survive the strip, so a server error names the file's line
  expect_identical(which(lines == "DROP FUNCTION f(integer);"), 4L)
})

test_that("a migration with no transaction of its own passes through", {
  expect_identical(wet:::wet_pg_trial_sql("SELECT 1;\nSELECT 2;"), "SELECT 1;\nSELECT 2;")
})

test_that("transaction control left inside the migration is refused, with its line", {
  refuse <- function(x) expect_error(wet:::wet_pg_trial_sql(x), "controls its own transaction")
  refuse("BEGIN;\nSELECT 1;\nCOMMIT;\nSELECT 2;\nCOMMIT;")
  refuse("BEGIN;\nSELECT 1;\ncommit ;\nSELECT 2;\nCOMMIT;")
  refuse("SELECT 1;\nROLLBACK;\nSELECT 2;")
  refuse("SELECT 1;\nEND;\nSELECT 2;")
  refuse("SELECT 1; COMMIT;\nSELECT 2;")
  refuse("SELECT 1;\nCOMMIT AND CHAIN;")
  refuse("SELECT 1;\nSTART TRANSACTION ISOLATION LEVEL SERIALIZABLE;")
  refuse("SELECT 1;\nBEGIN WORK;\nSELECT 2;")
  refuse("SELECT 1;\nPREPARE TRANSACTION 'x';")
  # the server allows a line break or a comment around the keyword
  refuse("SELECT 1;\nCOMMIT\n;")
  refuse("SELECT 1;\nCOMMIT -- c\n;")
  refuse("SELECT 1;\n/* c */ COMMIT;")
  refuse("SELECT 1;\nCOMMIT/* c */;")
  refuse("SELECT 1; /* a\nb */\nROLLBACK;")
  # and between a command's words, and a last statement needs no semicolon
  refuse("SELECT 1;\nCOMMIT\nAND CHAIN;")
  refuse("SELECT 1;\nEND\nTRANSACTION;")
  refuse("SELECT 1;\nROLLBACK /* x */ WORK;")
  refuse("SELECT 1;\nCOMMIT -- c\nWORK;")
  refuse("SELECT 1;\nCOMMIT")
  refuse("SELECT 1;\nCOMMIT\n\n")
  # a long run of comments before one cannot hide it by exhausting the regex
  refuse(paste0("SELECT 1;\n-- ", strrep("-", 40), "\nSELECT 2;\nCOMMIT;"))
  refuse(paste0("SELECT 1;\n", strrep("-", 400), "\nSELECT 2;\nCOMMIT;"))
  refuse(paste0("SELECT 1;\n", strrep("/* x */\n", 20), "COMMIT;"))
  refuse("SELECT 1;\nCOMMIT /* a /* b */ c */;")
  # a COMMIT; with no BEGIN; before it is not the migration's own pair
  refuse("SELECT 1;\nCOMMIT;")
  expect_error(wet:::wet_pg_trial_sql("BEGIN;\nSELECT 1;\nCOMMIT;\nSELECT 2;\nCOMMIT;"), "at line 3\\b")
  expect_error(wet:::wet_pg_trial_sql("SELECT 1; /* a\nb */\nROLLBACK;"), "at line 3\\b")
})

test_that("a trial migrates its own session only, and its rollback undoes it", {
  conn <- local_fwapg()
  other <- local_fwapg()
  tbl <- paste0("wet_trial_", paste(sample(letters, 12, TRUE), collapse = ""))
  f <- withr::local_tempfile(fileext = ".sql")
  writeLines(c("BEGIN;", sprintf("CREATE TABLE public.%s (x integer);", tbl),
               sprintf("INSERT INTO public.%s VALUES (1);", tbl), "COMMIT;"), f)
  exists_in <- function(con) !is.na(DBI::dbGetQuery(con, sprintf("SELECT to_regclass('public.%s')::text AS r", tbl))$r)
  local({
    wet:::wet_pg_trial(conn, f)
    expect_true(exists_in(conn))
    expect_false(exists_in(other))
  })
  expect_false(exists_in(conn))
  expect_false(exists_in(other))
})

test_that("a migration that commits midway is refused before anything runs", {
  conn <- local_fwapg()
  tbl <- paste0("wet_trial_", paste(sample(letters, 12, TRUE), collapse = ""))
  f <- withr::local_tempfile(fileext = ".sql")
  writeLines(c("BEGIN;", sprintf("CREATE TABLE public.%s (x integer);", tbl), "COMMIT;",
               "SELECT 1;", "COMMIT;"), f)
  expect_error(wet:::wet_pg_trial(conn, f), "controls its own transaction")
  expect_true(is.na(DBI::dbGetQuery(conn, sprintf("SELECT to_regclass('public.%s')::text AS r", tbl))$r))
})
