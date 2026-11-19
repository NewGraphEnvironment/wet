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
