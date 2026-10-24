# The upstream sums in two province runs' row orders (#76).
#
#   Rscript scripts/wb_upstream_order.R data/wb/_pre16/962a9cc2c4 data/wb/e675918817
#
# Runs made before #76 stored each basin's polygons in whatever order
# PostgreSQL returned them, and two of them agree only to rounding
# (scripts/wb_upstream_identity.R). This takes each basin's polygons in the
# order each run stored them (watershed_feature_id, wscode, localcode and
# area_m2 from upstream/<CODE>.rds), sums area and a signed value per polygon
# upstream with the current wet_upstream_sums(), and requires the two results
# to be identical(): the orders that differed, replayed without a province run.
# Needs whole basins (the machine with the full runs, not a reduced bundle) and
# fwapg for the irregular pairs. Prints its result and writes nothing.

devtools::load_all(quiet = TRUE)
runs <- commandArgs(trailingOnly = TRUE)
if (length(runs) != 2L || !all(file.exists(file.path(runs, "upstream", "_complete")))) {
  stop("name two province runs (directories with upstream/_complete)")
}
codes <- readLines(file.path(runs[1], "upstream", "_complete"))
if (!identical(codes, readLines(file.path(runs[2], "upstream", "_complete")))) {
  stop("the two runs accumulated different basins")
}
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
cols <- c("area_m2", "s")
polys <- function(run, code) {
  x <- readRDS(file.path(run, "upstream", paste0(code, ".rds")))
  x <- x[, c("watershed_feature_id", "wscode", "localcode", "area_m2")]
  # signed, so the sums cancel as a layer near zero does
  x$s <- x$area_m2 * sin(x$watershed_feature_id)
  x
}
n_other <- 0L
n_rows <- 0
for (code in codes) {
  a <- polys(runs[1], code)
  b <- polys(runs[2], code)
  if (nrow(a) != nrow(b) || !setequal(a$watershed_feature_id, b$watershed_feature_id)) {
    stop(code, ": the two runs hold different watersheds")
  }
  irr <- wet_upstream_irregular(conn, code)
  x <- wet_upstream_sums(a, cols, irregular_pairs = irr)
  y <- wet_upstream_sums(b, cols, irregular_pairs = irr)
  y <- y[match(x$watershed_feature_id, y$watershed_feature_id), cols]
  if (!identical(unname(as.matrix(x[, cols])), unname(as.matrix(y)))) {
    stop(code, ": the sums differ between the two runs' row orders")
  }
  n_other <- n_other + !identical(a$watershed_feature_id, b$watershed_feature_id)
  n_rows <- n_rows + nrow(a)
}
DBI::dbDisconnect(conn)
message("identical: ", length(codes), " basins (", n_other, " stored in another order), ",
        n_rows, " watersheds")
