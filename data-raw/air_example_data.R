# The bundled air temperature tree, inst/extdata/air_example/ (#216): a manifest and a few
# kilobytes of parquet laid out as the published air_temperature/fwa/v1, for
# wet_air_daily()'s example and tests. Made from cd's example daily cube (2002, 5 x 5 cells)
# with cells set to no-data (tests/testthat/helper-air.R) and seven made-up segments in two
# made-up watershed groups, one segment of each cell status and one `moved` from each kind
# of empty cell. Written by the same code the build uses (scripts/air_publish_lib.R).
#
# Run from the package root: Rscript data-raw/air_example_data.R
# Needs cd and the crate release carrying the air schemas (R_LIBS may name a library holding
# it). Byte-identical on a rerun with the same packages: the manifest's time is fixed.

pkgload::load_all(".", quiet = TRUE)
source("scripts/air_publish_lib.R")
source("tests/testthat/helper-air.R")

root <- file.path("inst", "extdata", "air_example")
unlink(root, recursive = TRUE)
dir.create(root, recursive = TRUE)
cube <- air_masked_cube(file.path(tempdir(), "air_cube"))

pts <- air_fixture_points()
cells <- wet:::wet_air_cells(pts[c("linear_feature_id", "lon", "lat")], day = "2002-01-01", source = cube)
for (g in unique(pts$watershed_group_code)) {
  w <- pts$watershed_group_code == g
  x <- air_lookup_frame(pts[w, ], cells[w, ])
  air_part_write(air_conform(x, "segment_cell"), root, "segment_cell", g)
}
stopifnot(setequal(cells$cell_status, air_statuses))

used <- sort(unique(stats::na.omit(cells$cell_id)))
ctr <- unique(cells[!is.na(cells$cell_id), c("cell_id", "cell_x", "cell_y")])
ctr <- ctr[order(ctr$cell_id), ]
d <- cd::cd_extract_daily(data.frame(id = ctr$cell_id, lon = ctr$cell_x, lat = ctr$cell_y), "2002-01-01",
                          "2002-12-31", source = cube)
d$checksum <- "local"  # a local cube has no manifest; the build refuses an NA checksum
y <- air_daily_frame(d, used)
air_part_write(air_conform(y, "cell_daily"), root, "cell_daily", "2002")

codes <- c("AAAA", "BBBB", "2002")
wet:::wet_manifest_write(
  root, air_id, drainage = stats::setNames(codes, codes),
  sources = list(list(
    source = air_source,
    description = "Made-up example: cd's example daily cube (2002, 5 x 5 cells) with five cells set to no-data.",
    citation = "Example data, not for use.",
    provenance = list(cube = "cd extdata/example_daily, masked", mask_day = "2002-01-01")
  )),
  provenance = list(wet_version = "example", wet_commit = "example"),
  crate_version = as.character(utils::packageVersion("crate")),
  built = as.POSIXct("2026-11-27 00:00:00", tz = "UTC")
)
cat(sprintf("%s: %s bytes\n", list.files(root, recursive = TRUE),
            file.size(list.files(root, recursive = TRUE, full.names = TRUE))), sep = "")
