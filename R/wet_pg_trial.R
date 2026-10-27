# Apply a database migration inside a transaction the caller rolls back (#127),
# so its effect can be measured, or tests run against it, without migrating a
# database other people use. Internal: a tool for checking a pending fwapg
# migration, not part of the package's data path.
#
# fwapg's migrations carry their own `BEGIN;` and `COMMIT;`. Left in, that
# COMMIT; would commit the outer transaction, so the pair is stripped and any
# other transaction control refused before anything runs. The check after the
# run, that the session still holds its transaction, is the backstop.
wet_pg_trial <- function(conn, file) {
  body <- wet_pg_trial_sql(paste(readLines(file, warn = FALSE), collapse = "\n"))
  DBI::dbBegin(conn)
  ok <- FALSE
  on.exit(if (!ok) DBI::dbRollback(conn), add = TRUE)
  DBI::dbExecute(conn, body, immediate = TRUE)
  x <- DBI::dbGetQuery(conn, "SELECT pg_current_xact_id_if_assigned()::text AS x")$x
  if (is.na(x)) {
    stop("after applying ", basename(file), " the session holds no open transaction, ",
         "so the migration may have been committed: check the database", call. = FALSE)
  }
  ok <- TRUE
  invisible(conn)
}

# The migration's statements with its own leading `BEGIN;` and trailing
# `COMMIT;` lines blanked (as a pair, and kept as empty lines so a server error
# still names the file's line), refusing any transaction control left after that.
# A plpgsql body's `BEGIN` and `END` lines carry no semicolon and `END IF;`
# names no transaction, so neither is refused; a bare `END;` is, on purpose.
wet_pg_trial_sql <- function(sql) {
  lines <- strsplit(sql, "\n", fixed = TRUE)[[1]]
  code <- which(!grepl("^\\s*(--.*)?$", lines))
  first <- code[1]
  last <- code[length(code)]
  own <- length(code) > 1 && grepl("^\\s*BEGIN\\s*;\\s*$", lines[first], ignore.case = TRUE) &&
    grepl("^\\s*COMMIT\\s*;\\s*$", lines[last], ignore.case = TRUE)
  if (own) {
    lines[c(first, last)] <- ""
  }
  body <- paste(lines, collapse = "\n")
  s <- "[ \\t]+"
  opt <- paste0("(", s, "(WORK|TRANSACTION|AND", s, "(NO", s, ")?CHAIN|PREPARED", s, "'[^']*'|'[^']*'|",
                "ISOLATION", s, "LEVEL", s, "[A-Z \\t]+|READ", s, "(ONLY|WRITE)|(NOT", s, ")?DEFERRABLE))*")
  pat <- paste0("(?im)(^|;)[ \\t]*(BEGIN|START", s, "TRANSACTION|COMMIT|END|ROLLBACK|ABORT|PREPARE", s,
                "TRANSACTION)", opt, "[ \\t]*;")
  hit <- gregexpr(pat, body, perl = TRUE)[[1]]
  if (hit[1] > 0) {
    at <- vapply(hit, function(i) sum(gregexpr("\n", substr(body, 1, i), fixed = TRUE)[[1]] > 0) + 1L, 1L)
    stop("the migration controls its own transaction at line ", paste(unique(at), collapse = ", "),
         ", which would end the trial's: refusing to run it", call. = FALSE)
  }
  body
}
