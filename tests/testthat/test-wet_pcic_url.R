test_that("historical and scenario URLs follow the PCIC file naming", {
  expect_equal(
    wet_pcic_url("RUNOFF", base = "https://x.org/hmo/"),
    "https://x.org/hmo/allwsbc.TPS_gridded_obs_init.1945to2099.RUNOFF.nc"
  )
  expect_equal(
    wet_pcic_url("BASEFLOW", run = "CanESM2_rcp85_r1i1p1", base = "https://x.org"),
    "https://x.org/allwsbc.CanESM2_rcp85_r1i1p1.1945to2099.BASEFLOW.nc"
  )
})

test_that("default base is the services host, not the redirecting data host", {
  withr::local_options(wet.pcic_base = NULL)
  expect_match(wet_pcic_url("RUNOFF"), "^https://services\\.pacificclimate\\.org/")
})

test_that("bad variable or run is refused", {
  expect_error(wet_pcic_url(""))
  expect_error(wet_pcic_url(c("RUNOFF", "BASEFLOW")))
  expect_error(wet_pcic_url("RUNOFF", run = NA_character_))
})
