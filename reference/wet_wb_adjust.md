# Apply a fitted water-balance adjustment

`raw + sum_k (a_k * z_k + b_k * zp_k)`, floored at 0 when
`floor = TRUE`. The floor is applied to the watershed value only: cells
stay signed, so the adjustment remains linear through accumulation.

## Usage

``` r
wet_wb_adjust(fit, d, floor = TRUE)
```

## Arguments

- fit:

  A
  [`wet_wb_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_wb_fit.md)
  result.

- d:

  `data.frame` with `raw` and the `z<k>`, `zp<k>` columns. A zone in
  `fit` missing from `d` counts as share 0, so `d` with no zone columns
  at all gets no adjustment; a zone in `d` missing from `fit` is an
  error.

- floor:

  Logical. Floor the result at 0.

## Value

Numeric vector of adjusted runoff (mm), one per row of `d`.
