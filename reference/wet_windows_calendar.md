# Calendar months and seasons as date windows

The twelve months and four meteorological seasons in the windows format
[`wet_window_stats()`](https://newgraphenvironment.github.io/wet/reference/wet_window_stats.md)
takes: a name and month-day `start` and `end`, both inclusive. An `end`
of `"02-29"` means the last day of February in leap and common years
alike.

## Usage

``` r
wet_windows_calendar()
```

## Value

`data.frame(window, start, end)` with 16 rows.

## Details

The seasons are named `djf`, `mam`, `jja` and `son` rather than winter,
spring and so on. That is deliberate:
[`cd::cd_seasons()`](https://rdrr.io/pkg/cd/man/cd_seasons.html) builds
winter from December, January and February of one calendar year, while
here `djf` is the contiguous December to February and takes the year of
its December, so the two would disagree under the same name.

## Examples

``` r
wet_windows_calendar()
#>    window start   end
#> 1     jan 01-01 01-31
#> 2     feb 02-01 02-29
#> 3     mar 03-01 03-31
#> 4     apr 04-01 04-30
#> 5     may 05-01 05-31
#> 6     jun 06-01 06-30
#> 7     jul 07-01 07-31
#> 8     aug 08-01 08-31
#> 9     sep 09-01 09-30
#> 10    oct 10-01 10-31
#> 11    nov 11-01 11-30
#> 12    dec 12-01 12-31
#> 13    djf 12-01 02-29
#> 14    mam 03-01 05-31
#> 15    jja 06-01 08-31
#> 16    son 09-01 11-30

# Add a species window to the calendar ones
rbind(wet_windows_calendar(),
      data.frame(window = "ch_spawning", start = "08-01", end = "09-15"))
#>         window start   end
#> 1          jan 01-01 01-31
#> 2          feb 02-01 02-29
#> 3          mar 03-01 03-31
#> 4          apr 04-01 04-30
#> 5          may 05-01 05-31
#> 6          jun 06-01 06-30
#> 7          jul 07-01 07-31
#> 8          aug 08-01 08-31
#> 9          sep 09-01 09-30
#> 10         oct 10-01 10-31
#> 11         nov 11-01 11-30
#> 12         dec 12-01 12-31
#> 13         djf 12-01 02-29
#> 14         mam 03-01 05-31
#> 15         jja 06-01 08-31
#> 16         son 09-01 11-30
#> 17 ch_spawning 08-01 09-15
```
