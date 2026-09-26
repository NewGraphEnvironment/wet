# wet (development version)

* Package scaffold, PCIC VIC-GL OPeNDAP subsetting, annual/monthly runoff
  aggregation, upstream area weighting and an fwapg MAD parity check (#1).

* Join-free upstream accumulation over FWA codes (`wet_upstream_sums()`,
  `wet_upstream_irregular()`, `wet_ws_fetch()`): whole basins, no order-8
  skip. `wet_upstream_mean()` now takes `(ws, values, denom, irregular_pairs,
  upstream_area)` instead of a pairs table. `wet_pcic_annual()` fetches PCIC
  one year at a time; `scripts/mad_basin.R` builds the Fraser (#2).
