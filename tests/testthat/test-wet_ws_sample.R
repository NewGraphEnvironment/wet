# 2 x 2 lon/lat raster of 1-degree cells: values 10, 20 / 30, NA
grid <- function() {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2,
                   crs = "EPSG:4326")
  terra::values(r) <- c(10, 20, 30, NA)
  r
}
polys <- function(wkt, ids) {
  v <- terra::vect(wkt, crs = "EPSG:4326")
  v$watershed_feature_id <- ids
  v
}

test_that("centroid takes the cell under the centroid and flags NA", {
  ws <- polys(c("POLYGON((0.1 1.1,0.9 1.1,0.9 1.9,0.1 1.9,0.1 1.1))",   # top-left, 10
                "POLYGON((1.1 0.1,1.9 0.1,1.9 0.9,1.1 0.9,1.1 0.1))"),  # bottom-right, NA
              c(1L, 2L))
  out <- wet_ws_sample(grid(), ws, "centroid")
  expect_equal(out$watershed_feature_id, 1:2)
  expect_equal(out$value, c(10, NA))
  expect_equal(out$cover, c(1, 0))
})

test_that("area method weights by overlap and reports cover", {
  # spans the top row equally: mean of 10 and 20
  top <- "POLYGON((0.5 1.2,1.5 1.2,1.5 1.8,0.5 1.8,0.5 1.2))"
  # spans the bottom row equally: 30 and NA -> value 30, cover 0.5
  bottom <- "POLYGON((0.5 0.2,1.5 0.2,1.5 0.8,0.5 0.8,0.5 0.2))"
  # entirely on the NA cell
  na <- "POLYGON((1.2 0.2,1.8 0.2,1.8 0.8,1.2 0.8,1.2 0.2))"
  out <- wet_ws_sample(grid(), polys(c(top, bottom, na), 1:3), "area")
  expect_equal(out$value, c(15, 30, NA), tolerance = 1e-6)
  expect_equal(out$cover, c(1, 0.5, 0), tolerance = 1e-6)
})

test_that("ground beyond the raster edge counts as uncovered", {
  # half on the 20 cell (x 1-2, y 1-2), half beyond xmax = 2
  off <- "POLYGON((1.5 1.2,2.5 1.2,2.5 1.8,1.5 1.8,1.5 1.2))"
  out <- wet_ws_sample(grid(), polys(off, 1L), "area")
  expect_equal(out$value, 20, tolerance = 1e-6)
  expect_equal(out$cover, 0.5, tolerance = 1e-6)
  # entirely off the raster
  away <- "POLYGON((5 5,6 5,6 6,5 6,5 5))"
  out <- wet_ws_sample(grid(), polys(away, 1L), "area")
  expect_true(is.na(out$value))
  expect_equal(out$cover, 0)
  out <- wet_ws_sample(grid(), polys(away, 1L), "centroid")
  expect_true(is.na(out$value))
  expect_equal(out$cover, 0)
})

test_that("inputs are checked", {
  ws <- polys("POLYGON((0 0,1 0,1 1,0 1,0 0))", 1L)
  expect_error(wet_ws_sample(c(grid(), grid()), ws))
  ws$watershed_feature_id <- NULL
  expect_error(wet_ws_sample(grid(), ws))
})

test_that("centroid sampling from lon/lat points matches polygons", {
  ws <- polys(c("POLYGON((0.1 1.1,0.9 1.1,0.9 1.9,0.1 1.9,0.1 1.1))",
                "POLYGON((1.1 0.1,1.9 0.1,1.9 0.9,1.1 0.9,1.1 0.1))"), 1:2)
  pts <- data.frame(watershed_feature_id = 1:2, lon = c(0.5, 1.5), lat = c(1.5, 0.5))
  expect_equal(wet_ws_sample(grid(), pts, "centroid"), wet_ws_sample(grid(), ws, "centroid"))
  expect_error(wet_ws_sample(grid(), pts, "area"), "needs polygons")
})

grid2 <- function() {
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2, crs = "EPSG:4326")
  a <- r; terra::values(a) <- c(10, 20, 30, NA)
  b <- r; terra::values(b) <- c(1, NA, 3, 4)
  x <- c(a, b); names(x) <- c("a", "b"); x
}
polys2 <- function(wkt, ids) { v <- terra::vect(wkt, crs = "EPSG:4326"); v$watershed_feature_id <- ids; v }

test_that("several layers are averaged over the cells where every layer has a value", {
  top <- "POLYGON((0.5 1.2,1.5 1.2,1.5 1.8,0.5 1.8,0.5 1.2))"     # a 10,20; b 1,NA
  bottom <- "POLYGON((0.5 0.2,1.5 0.2,1.5 0.8,0.5 0.8,0.5 0.2))"  # a 30,NA; b 3,4
  out <- wet_ws_sample(grid2(), polys2(c(top, bottom), 1:2), "area")
  expect_equal(names(out), c("watershed_feature_id", "a", "b", "cover"))
  # top: only the left cell has both layers -> a 10, b 1, cover 0.5
  expect_equal(out$a, c(10, 30), tolerance = 1e-6)
  expect_equal(out$b, c(1, 3), tolerance = 1e-6)
  expect_equal(out$cover, c(0.5, 0.5), tolerance = 1e-6)
  # a linear combination of layers samples to the same combination
  g <- grid2()
  comb <- c(2 * g[["a"]] - g[["b"]], g[["b"]])
  names(comb) <- c("lin", "b")
  lin <- wet_ws_sample(comb, polys2(c(top, bottom), 1:2), "area")
  expect_equal(lin$lin, 2 * out$a - out$b, tolerance = 1e-6)
})

