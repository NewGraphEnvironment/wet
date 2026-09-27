# A connection to the local fwapg (WET_PG* env vars, defaulting to the
# fresh-db container), or a skip. Never on CI: these tests need the database.
local_fwapg <- function(env = parent.frame()) {
  skip_on_ci()
  skip_on_cran()
  skip_if_not_installed("RPostgres")
  conn <- tryCatch(DBI::dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("WET_PGHOST", "localhost"),
    port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
    dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
    user = Sys.getenv("WET_PGUSER", "postgres"),
    password = Sys.getenv("WET_PGPASSWORD", "postgres")
  ), error = function(e) NULL)
  if (is.null(conn)) skip("no fwapg database")
  withr::defer(DBI::dbDisconnect(conn), envir = env)
  conn
}

# The local HYDAT, or a skip.
local_hydat_real <- function() {
  skip_if_not_installed("tidyhydat")
  p <- file.path(tidyhydat::hy_dir(), "Hydat.sqlite3")
  if (!file.exists(p)) skip("no local HYDAT")
  p
}
