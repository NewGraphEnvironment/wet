# Daily flow at hydrometric stations, from HYDAT through to the present

One daily discharge series per station. Approved HYDAT flows come first;
after HYDAT's last approved day, ECCC provisional daily means fill in,
and the real-time feed covers the days since. Each day keeps the source
it came from and its HYDAT symbol, so a result built on the series can
say what it rests on (ice-affected winter flows are estimates).

## Usage

``` r
wet_station_daily(
  stations,
  hydat = wet_hydat_path(),
  from = NULL,
  to = Sys.Date(),
  sources = c("hydat", "provisional", "realtime")
)
```

## Arguments

- stations:

  Character vector of station numbers.

- hydat:

  Path to the HYDAT sqlite database. Defaults to tidyhydat's download
  location.

- from, to:

  Optional first and last date (a `Date` or a string
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) reads). `NULL`
  means no bound.

- sources:

  Which sources to read, from `"hydat"`, `"provisional"` and
  `"realtime"`. Each source continues the one before it, per station,
  from that source's last day over its whole record: provisional days
  are used only after HYDAT's last day, and real-time days only after
  both, whatever `from` and `to` are. `"provisional"` reads the
  water-temp-bc archive of ECCC daily means (option
  `wet.provisional_root`, default
  `s3://water-temp-bc/data/canonical/Parameter=6/`) with duckdb, and
  `"realtime"` calls
  [`tidyhydat::realtime_ws()`](https://docs.ropensci.org/tidyhydat/reference/realtime_ws.html)
  for the days after the other sources end (at most about 18 months
  back).

## Value

`data.frame(station_number, date, q_m3s, symbol, source, status)`, one
row per station-day that has a flow, ordered by station and date.
`symbol` is HYDAT's daily symbol (`"B"` ice, `"E"` estimated, `"A"`
partial day, `"D"` dry) or `NA`; `status` is `"approved"` or
`"provisional"` (any ECCC approval other than final counts as
provisional). Provisional days carry no ice symbol, so their `NA` means
"not recorded", not "open water".

A gap between the end of one source and the start of the next (for
example an old HYDAT ending before the provisional archive begins) is
left unfilled and reported with a warning when it overlaps `from`-`to`.
A source that fails is skipped with a warning and the others are
returned.

## Details

Ported from `ngr::ngr_hyd_q_daily()`, which joined HYDAT with about 18
months of real-time flow.

## Examples

``` r
if (FALSE) { # \dontrun{
# Buck Creek at the mouth, from the start of its record to last week
q <- wet_station_daily("08EE013")
table(q$source, q$status)
} # }
```
