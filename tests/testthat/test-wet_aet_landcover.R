# 2 x 3 grid: two all-conifer cells, two all-grass cells, one half-and-half
# (majority conifer by a hair), one cell with no cover at all (outside Canada)
local_lc <- function() {
  r <- terra::rast(nrows = 2, ncols = 3, xmin = 0, xmax = 3, ymin = 0, ymax = 2)
  aet <- terra::setValues(r, c(300, 340, 200, 220, 320, 500))
  frac <- c(terra::setValues(r, c(1, 1, 0, 0, 0.51, 0)),
            terra::setValues(r, c(0, 0, 1, 1, 0.49, 0)))
  names(frac) <- c("coniferous", "grass")
  list(aet = aet, frac = frac)
}

test_that("each class ratio is its measured AET over the mean model AET of its majority cells", {
  x <- local_lc()
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275))
  rt <- out$ratio
  expect_equal(rt$class, c("coniferous", "grass"))
  expect_equal(rt$n_cells, c(3, 2))
  expect_equal(rt$aet_mean, c(mean(c(300, 340, 320)), mean(c(200, 220))))
  expect_equal(rt$ratio, c(276, 275) / rt$aet_mean)
})

test_that("the multiplier mixes the ratios by cover fraction, and uncovered ground keeps ratio 1", {
  x <- local_lc()
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275))
  rc <- out$ratio$ratio[1]
  rg <- out$ratio$ratio[2]
  v <- terra::values(out$aet, mat = FALSE)
  expect_equal(v[1:4], c(300 * rc, 340 * rc, 200 * rg, 220 * rg))
  expect_equal(v[5], 320 * (0.51 * rc + 0.49 * rg))
  expect_equal(v[6], 500)  # no cover: CGIAR unchanged
})

test_that("a partly covered cell keeps ratio 1 on its uncovered part and does not vote", {
  x <- local_lc()
  x$frac[[1]][6] <- 0.3  # 30 % conifer, 70 % outside the land-cover product
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275))
  expect_equal(out$ratio$n_cells[1], 3)  # still three majority cells
  rc <- out$ratio$ratio[1]
  expect_equal(terra::values(out$aet, mat = FALSE)[6], 500 * (0.3 * rc + 0.7))
})

test_that("a class with no majority cell gets ratio 1, and a missing class is an error", {
  x <- local_lc()
  x$frac <- c(x$frac, terra::setValues(x$frac[[1]], c(0, 0, 0, 0, 0, 0.1)))
  names(x$frac)[3] <- "water"
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275, water = 425))
  expect_equal(out$ratio$ratio[out$ratio$class == "water"], 1)
  expect_equal(out$ratio$n_cells[out$ratio$class == "water"], 0)
  expect_error(wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275)), "water")
})

test_that("the shipped Table 3 carries every NRCan 2020 class code found in BC once", {
  t3 <- wet_chapman_table3()
  codes <- as.integer(unlist(strsplit(t3$nrcan_2020_codes, ";")))
  expect_false(anyDuplicated(codes) > 0)
  expect_true(all(c(1, 2, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19) %in% codes))
  expect_true(all(t3$aet_mm > 0))
})

test_that("domain limits the denominators, min_cells and clamp bound the ratios", {
  x <- local_lc()
  dom <- terra::setValues(x$aet, c(1, 0, 1, 1, 0, 1))  # cells 2 and 5 are outside
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275), domain = dom)
  expect_equal(out$ratio$aet_mean[1], 300)
  expect_equal(out$ratio$n_cells[1], 1)
  # still applied everywhere, the outside cells included
  expect_equal(terra::values(out$aet, mat = FALSE)[2], 340 * 276 / 300)
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 276, grass = 275), min_cells = 3)
  expect_equal(out$ratio$ratio, c(276 / mean(c(300, 340, 320)), 1))  # grass has only 2
  out <- wet_aet_landcover(x$aet, x$frac, c(coniferous = 5000, grass = 1), clamp = c(0.25, 4))
  expect_equal(out$ratio$ratio, c(4, 0.25))
})
