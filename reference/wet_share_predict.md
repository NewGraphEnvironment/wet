# Predict monthly shares of annual runoff

Applies the 12 regressions of
[`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md),
floors each prediction at 0 and renormalises so the 12 shares sum to 1.
A watershed whose 12 floored predictions are all 0 gets `NA` shares.

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
