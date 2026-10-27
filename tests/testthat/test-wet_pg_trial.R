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
  # a COMMIT; with no BEGIN; before it is not the migration's own pair
  refuse("SELECT 1;\nCOMMIT;")
  expect_error(wet:::wet_pg_trial_sql("BEGIN;\nSELECT 1;\nCOMMIT;\nSELECT 2;\nCOMMIT;"), "at line 3\\b")
})
