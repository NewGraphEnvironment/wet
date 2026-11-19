# Findings — Backlog move 5: More donors and PCIC's years at the chinook sites (#167)

## Issue context

**If we do it:** departures at the chinook sites are carried by more donors (the province's non-integrated stations and the BC Water Tool's third-party gauges) and by #122's shipped weighting, `covariance_pick`, where PCIC covers the site, and the sites and their article are rerun once with both. **If we never do:** donors stay federal only and the comparison article's carried route stays on inverse distance, the weaker weighting.

Order: `planning/backlog.md`, move 5. Run `/planning-init <this issue>`: one phase per batch, one PR.

## Batch 7: stations beyond HYDAT

**Why here:** both feed `wet_station_daily()`, share the QA and regulation questions, and meet at six sites both hold.

**Touches:** `R/wet_station_daily.R` and new readers, `research/station_sources.md`, `data/checks/`.

**Decided at the gate:** keep, flag or drop ungraded and unchecked values; which copy at the shared sites; the credit line each published series carries.

| issue | title |
|---|---|
| #142 | Harvest the province's non-integrated hydrometric discharge into wet_station_daily() |
| #144 | Harvest the third-party gauge records the BC Water Tool serves into wet_station_daily() |

## Batch 8: PCIC's per-year files at the sites

**Why here:** `covariance_pick` needs PCIC's per-year files at every run; a cache makes them a default rather than a hand-made directory. The site rerun this batch needs is the one batch 7's new donors need.

**Touches:** a new internal fetcher beside `wet_hydat()`, `scripts/departure_site.R`, `scripts/departure_pcic.R`, `data-raw/chinook_sites_data.R`, the comparison article.

**Decided at the gate:** the rule for `covariance_pick` at the sites, registered before any run; whether the Morice and upper Fraser boxes are covered.

| issue | title |
|---|---|
| #135 | Cache PCIC's per-year files from S3, as wet_hydat() caches HYDAT |
| #147 | Carry departures at the #126 sites with covariance_pick where PCIC covers them |


## Batch 7 at the site boxes (plan gate, 2026-11-18)

From `data/checks/station_sources_20260717.txt` (the "Every station read" table), stations inside each
box of `scripts/departure_sites.csv`:

| box | beyond-HYDAT stations with daily discharge | window-years (all/new) |
|---|---|---|
| maxan (BULK) | 08EE0001 (same site as 08EE022), 08EE0002 | 2/2, 2/2 |
| swift (UFRA) | none | |
| naver (COTR) | 08JC0001, 08JC0002, 08JC0003, 08JC0005, 08JC0006, 08JC0018, 08JC0020, 08MC0001 | 4, 3, 4, 3, 4, 2, 2, 2 |
| gosnell (MORR) | 08EE0001, 08EE0002 (as maxan) | 2/2, 2/2 |

No Water Tool third-party station falls in any box. All provincial records here are 2011–2021, so
none has a 1981–2010 baseline year: the departure pool needs >= 10 (`dep_pool_of()`), the extension
pool >= 30. At most 5 Naver stations could join its short-record test set.

## PCIC coverage hints

#122's report (`data/checks/departure_pcic_20260717.txt`) scores Bulkley (08EE) and Morice (08ED)
calibration gauges, and Maxan 08EE018 as a short-record gauge (covariance_pick 0.89 against distance
0.74). The upper Fraser (UFRA) and Gosnell's mouth are to be measured in Phase 4.

## Per-year files

Public, anonymous 200: `https://fresh-bc.s3.us-west-2.amazonaws.com/fwapg/extras/pcic.subbasin_days.PNWNAmet_historical.<year>.parquet` (probed 2026-11-19 UTC).

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Trial run of Maxan on m1 (2026-11-19, frozen copy before code-check round 1's fix)

- Sections 1–5 of `data/checks/departure_site_maxan_bulk_20260717.txt` reproduce byte for byte; the
  report gains 191 lines (section 6) and loses none.
- The rds against m4's (copied to the scratchpad): every element `identical()` except the carried
  departures (`mx$*$a$anomaly` and what derives from them), which differ by at most about 7e-14
  (`all.equal()` TRUE). Printed values are unaffected. Another machine or a later change to
  `wet_donor_mean()`; not chased, since no printed line moves.
- Section 6 at Maxan: 49 of 53 box-pool gauges covered; migration mean medians, distance 0.62 and
  covariance_pick 0.67 (leave-one-out, 30 gauges), 0.56 and 0.65 leak-free: covariance_pick ships
  (gain 0.049 and 0.094).
- m1 has no snow normals grid; copied m4's `data/snow/snow_19812010_4816dbcca8.tif` (md5 1c002ccd…,
  equal on both) so the Maxan snow parity table can run here.

## The short-record bundle (Phase 5)

Rebuilt on m1 after the site reruns, `inst/vignette-data/short_record_values.rds` differed from the
committed one (built on m4) in `carried`, `change`, `departures`, `fits` (at most 2e-14) and `snow`,
`snow_change` (at most 3e-11), all `all.equal()` TRUE, beside the new report md5s. The Maxan report
lines it reads are byte-identical (sections 1–5). The committed bundle is kept: committing the
m1 rebuild would churn values by rounding (r-packages.md, "rebuild where it was built when values
pass through BLAS"), and nothing holds its recorded report md5 to the tracked report
(`test-vignette_data.R` checks only that the field exists). That article stays on distance at
Maxan (#120's record), while the comparison article now borrows Maxan's departures through
covariance_pick.

## Code-check enumeration that ended the loop (2026-11-19)

Two sets, each walked member by member:

1. Section 6's empty-pool mechanism (round 3's places, round 4's table in `review-round4.md`): 14
   places, every one holding after d5435ccb and 1b2fb78.
2. The comparison article's quantified sentences after Phase 5 (round 5, then a grep for
   "all four", "only", "every", "clear"), each with the guard that tests its whole set:
   - spawning mean lower "at all four streams": `stopifnot(all(spw$pct < 0))`
   - its range below no change at Maxan and Gosnell: `low_spw` (printed from the set)
   - seven-day low "fell at" three, held at Swift: `m7_down`, `abs(m7$pct[swift]) < 5`
   - "clearly at Maxan and Gosnell" (opening and change section): `m7_clear`, `m7_clear %in% m7_down`
   - migration "fell clearly only at Maxan", both window sets: `mig_clear`
   - spawning scores "below the bar only at Swift" (Bulkley windows): `spw_below`
   - migration scores clear the bar "in every box", both sets: `all(... >= 0.5)`
   - filled-in drops, clear "only at Maxan": `ext$site_id[ext$pct_hi < 0] == "maxan"`
   - donors chosen by modelled years "at Maxan, Naver and Gosnell": `cov_ids`
   - snow: migration slopes above zero "at all four"; melt date below measured: guards in `snow`
   - Maxan's base "rests on 10 years", "no record from 1952 to 1970": `few_ref`, `my`
   - the windows "the Bulkley's at all four": unchanged guard
