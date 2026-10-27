# Apply a database migration inside a transaction that is rolled back when
# `env` exits (#127), so its effect can be measured, or tests run against it,
# without migrating a database other people use. Internal, and shipped only
# because the scripts and the live tests both use it: a tool for checking a
# pending fwapg migration, not part of the package's data path.
#
# fwapg's migrations carry their own `BEGIN;` and `COMMIT;`. Left in, that
# COMMIT; would commit the outer transaction, so the pair is stripped and any
# other transaction control refused before anything runs. The backstop is
# that the session still holds the transaction it opened, with the same id;
# a migration that commits and begins again would hold another.
wet_pg_trial <- function(conn, file, env = parent.frame()) {
  body <- wet_pg_trial_sql(paste(readLines(file, warn = FALSE), collapse = "\n"))
  DBI::dbBegin(conn)
  withr::defer(DBI::dbRollback(conn), envir = env)
  xid <- DBI::dbGetQuery(conn, "SELECT pg_current_xact_id()::text AS x")$x
  DBI::dbExecute(conn, body, immediate = TRUE)
  now <- DBI::dbGetQuery(conn, "SELECT pg_current_xact_id_if_assigned()::text AS x")$x
  if (!identical(now, xid)) {
    stop("after applying ", basename(file), " the session no longer holds transaction ", xid,
         ", so the migration may have been committed: check the database", call. = FALSE)
  }
  invisible(conn)
}

# The migration's statements with its own leading `BEGIN;` and trailing
# `COMMIT;` lines blanked (as a pair, and kept as empty lines so a server error
# still names the file's line), refusing any transaction control left after that.
# A plpgsql body's `BEGIN` and `END` lines carry no semicolon and `END IF;`
# names no transaction, so neither is refused; a bare `END;` is, on purpose.
# Whitespace, line breaks and comments may sit around and between the words,
# and the last statement may end the input with no semicolon, as the server
# allows.
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
  ws <- "(\\s|--[^\\n]*|/\\*[\\s\\S]*?\\*/)*"
  s <- "(\\s|--[^\\n]*|/\\*[\\s\\S]*?\\*/)+"
  opt <- paste0("(", s, "(WORK|TRANSACTION|AND", s, "(NO", s, ")?CHAIN|PREPARED", s, "'[^']*'|'[^']*'|",
                "ISOLATION", s, "LEVEL", s, "[A-Z \\t]+|READ", s, "(ONLY|WRITE)|(NOT", s, ")?DEFERRABLE))*")
  # `\\z`, not `$`: under (?m) `$` would also end a plpgsql body's bare BEGIN line
  pat <- paste0("(?im)(^|;)", ws, "(?<kw>BEGIN|START", s, "TRANSACTION|COMMIT|END|ROLLBACK|ABORT|PREPARE", s,
                "TRANSACTION)", opt, ws, "(;|\\z)")
  hit <- gregexpr(pat, body, perl = TRUE)[[1]]
  if (hit[1] > 0) {
    kw <- attr(hit, "capture.start")[, "kw"]
    at <- vapply(kw, function(i) sum(gregexpr("\n", substr(body, 1, i), fixed = TRUE)[[1]] > 0) + 1L, 1L)
    stop("the migration controls its own transaction at line ", paste(unique(at), collapse = ", "),
         ", which would end the trial's: refusing to run it", call. = FALSE)
  }
  body
}
