# Skill of modelled runoff against observed runoff at gauges

Per station: the annual error `100 * (mod - obs) / obs` and log ratio
`log(mod / obs)`, and over the 12 months the Nash-Sutcliffe efficiency
of the monthly climatology (mm) and of the monthly shares of the annual
total. Summaries by group give the metrics of Chapman et al. (2018)
(mean, median and mean absolute error in percent, and the share of
stations within +/- 20 %) plus the log-ratio bias and spread.

## Usage

``` r
wet_flow_validate(x, groups = NULL, min_obs = 10)
```

## Arguments

- x:

  `data.frame(station_number, month, obs, mod)` in mm, `month` 0 for the
  annual total and 1-12 for months. Modelled values below 0 should be
  floored before they reach here.

- groups:

  Optional `data.frame(station_number, <group columns>)`; each group
  column gets its own summary.

- min_obs:

  Minimum observed annual runoff (mm) for a station to count.

## Value

`list(stations, summary)`. `stations`: one row per station with `obs`,
`mod`, `err_pct`, `log_ratio`, `nse_month`, `nse_share`. `summary`: one
row per group value (and an `"all"` row) with `n`, `n_low`, `n_no_mod`
(stations with no modelled value, left out), `mean_err_pct`,
`median_err_pct`, `mae_pct`, `within_20`, `log_bias_median`, `log_sd`,
`nse_month_median`, `nse_share_median`.

## Details

A station whose observed annual runoff is below `min_obs` mm is left out
of every summary and counted in `n_low`: percentage errors on near-zero
runoff are not informative, and a log ratio of zero or negative runoff
is undefined. Months need all 12 values in both series; a station
without them gets `NA` monthly metrics.
