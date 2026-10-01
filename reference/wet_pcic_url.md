# OPeNDAP URL for one PCIC VIC-GL gridded variable

PCIC serves its gridded hydrologic model output (`hydro_model_out`) one
variable per file. The historical run is `"TPS_gridded_obs_init"`
(PNWNAmet forcing, VICGL-RGM, 1945-2012); scenario runs are named
`"<GCM>_<rcp>_<member>"`, e.g. `"CanESM2_rcp85_r1i1p1"` (VICGL,
1945-2099). Every file name carries `1945to2099` regardless of the run's
real span.

## Usage

``` r
wet_pcic_url(
  variable,
  run = "TPS_gridded_obs_init",
  base = getOption("wet.pcic_base",
    "https://services.pacificclimate.org/data/hydro_model_out")
)
```

## Arguments

- variable:

  Character. VIC output variable, e.g. `"RUNOFF"` or `"BASEFLOW"`.

- run:

  Character. Run identifier. Default is the historical run.

- base:

  Character. Base URL of the `hydro_model_out` data service. Defaults to
  option `wet.pcic_base`, else
  `https://services.pacificclimate.org/data/hydro_model_out`.

## Value

Character URL of the dataset (no OPeNDAP suffix).

## Examples

``` r
wet_pcic_url("RUNOFF")
#> [1] "https://services.pacificclimate.org/data/hydro_model_out/allwsbc.TPS_gridded_obs_init.1945to2099.RUNOFF.nc"
wet_pcic_url("BASEFLOW", run = "CanESM2_rcp85_r1i1p1")
#> [1] "https://services.pacificclimate.org/data/hydro_model_out/allwsbc.CanESM2_rcp85_r1i1p1.1945to2099.BASEFLOW.nc"
```
