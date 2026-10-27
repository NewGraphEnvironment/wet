# A connection to the local fwapg (WET_PG* env vars, defaulting to the
# fresh-db container), or a skip. Never on CI: these tests need the database.
local_fwapg <- function(env = parent.frame()) {
  skip_on_ci()
  skip_on_cran()
  skip_if_not_installed("RPostgres")
  conn <- tryCatch(fwapg_connect(), error = function(e) NULL)
  if (is.null(conn)) skip("no fwapg database")
  withr::defer(DBI::dbDisconnect(conn), envir = env)
  conn
}

fwapg_connect <- function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("WET_PGHOST", "localhost"),
    port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
    dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
    user = Sys.getenv("WET_PGUSER", "postgres"),
    password = Sys.getenv("WET_PGPASSWORD", "postgres")
  )
}

# A connection whose fwa_indexpoint() has fwapg#41's rework (#127), or a skip
# naming the missing migration. WET_FWAPG_TRIAL names a migration file to apply
# inside a transaction rolled back when the test ends (wet_pg_trial()), so the
# tests can run against a migration not yet applied to the database.
# WET_FWAPG_CURRENT=true (or 1) says the database should already have it: then
# a stale one does not skip, the assertions run and fail, and so does the gate
# test in test-wet_station_snap.R, which reads the committed state on its own
# connection, never a trial, and fails rather than skips when it cannot connect.
local_fwapg_indexpoint <- function(env = parent.frame()) {
  conn <- local_fwapg(env)
  trial <- Sys.getenv("WET_FWAPG_TRIAL")
  if (nzchar(trial)) {
    # tests run from tests/testthat, so a relative path names the wrong file
    if (!file.exists(trial)) stop("WET_FWAPG_TRIAL names no file: ", trial, " (give an absolute path)")
    # rolled back when the test ends, before the disconnect local_fwapg() deferred
    wet:::wet_pg_trial(conn, trial, env = env)
  }
  if (!fwapg_indexpoint_current(conn) && !fwapg_current_wanted()) {
    skip(paste("fwapg's fwa_indexpoint() predates migration 202610240132__indexpoint_tiebreak",
               "(NewGraphEnvironment/fwapg#41)"))
  }
  conn
}

# fwapg#41's fwa_indexpoint() is the one with the include_disconnected filter
fwapg_indexpoint_current <- function(conn) {
  grepl("include_disconnected", DBI::dbGetQuery(conn,
    "SELECT pg_get_function_arguments('whse_basemapping.fwa_indexpoint'::regproc) AS a")$a)
}

fwapg_current_wanted <- function() tolower(Sys.getenv("WET_FWAPG_CURRENT")) %in% c("true", "1")
