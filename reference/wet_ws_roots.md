# Minimal FWA watershed codes of a set

The codes of a set that have no proper ancestor in it: every code in the
set lies under exactly one of them. FWA codes are a 3-digit root label
then 6-digit labels, so a code's ancestors are its prefixes ending at a
label boundary.

## Usage

``` r
wet_ws_roots(wscode)
```

## Arguments

- wscode:

  Character. FWA watershed codes as text (ltree form, e.g.
  `"100.190442"`). `NA` is ignored; duplicates are fine.

## Value

Character, the minimal codes, sorted in byte order (ltree order).

## Examples

``` r
wet_ws_roots(c("100.190442.244975", "100.190442", "100.190442.999094",
               "300.625474.584724", "300.625474.584724.100997"))
#> [1] "100.190442"        "300.625474.584724"
```
