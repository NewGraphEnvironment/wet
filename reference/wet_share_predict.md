# Predict monthly shares of annual runoff

Applies a
[`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md).
The regressions' predictions are floored at 0 and renormalised so the 12
shares sum to 1, and a watershed whose 12 floored predictions are all 0
gets `NA` shares. A donor prediction is a weighted mean of observed
shares, so it sums to 1 already; a blend is the mean of the two. A
watershed missing a predictor gets `NA` shares.

## Usage

``` r
wet_share_predict(fit, d)
```

## Arguments

- fit:

  A
  [`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md)
  result.

- d:

  `data.frame` with the predictors named in `fit`.

## Value

A matrix with one row per row of `d` and columns `share_01` to
`share_12`.
