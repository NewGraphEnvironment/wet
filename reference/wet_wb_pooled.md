# Zones to pool in a water-balance fit

The zones where fewer than `min_gauges` stations have their largest
upstream share. It reads only where stations are, never what they
measured, so computing it on a fold's training stations leaks nothing.

## Usage

``` r
wet_wb_pooled(d, min_gauges = 8)
```

## Arguments

- d:

  `data.frame` with `obs` and `raw` (mm) and, per zone `k`, columns
  `z<k>` (upstream zone share) and `zp<k>` (upstream mean of zone-masked
  annual P), e.g. `z08`, `zp08`.

- min_gauges:

  Minimum stations per zone before it is fitted on its own.

## Value

Character vector of zone codes.
