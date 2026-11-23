## Outcome

#168 (backlog move 6, carrying #9) piloted PCIC's channel-scale output on the FWA, and found it already scaled. As far as can be traced, the portal's product is hydromosaic's outlet series, which fwapg's crosswalk places on the whole network and wet publishes as routed PCIC. So the pilot (decision 1 d) did not download per site or build a hand crosswalk. `scripts/channel_scale_pilot.R` read PCIC's raw series in bulk under rules registered at 7d6c7b1, before the first logged fetch, and held them to routed PCIC as published at every scored gauge with an outlet, to PNWNAmet, and to HYDAT. Verdict for move 7 (#169), by PCIC domain: CMIP6 routed through fwapg's crosswalk on the coast (8 GCMs, no TaiESM1), the Columbia and the Peace; CMIP5 gridded in the Fraser, where the CMIP6 runs' historical flow fails rule 2. The Fraser fallback is unscored, so move 7 scores CMIP5 first. Write-up: [`research/pcic_channel_scale.md`](../../../research/pcic_channel_scale.md); `research/monthly_error.md`'s check-1 paragraph now rests on the measurement.

Wrong turns, kept:
- The plan's headwater rule (the smallest segment under 10 km²) would have picked a few-hectare catchment. It was changed before the rule commit.
- Rule 3's listing check was first coded stricter than its words: all 9 GCMs at every outlet, which read the coast as having no CMIP6. It is corrected and recorded as an amendment.
- The confluence rule borrowed fwapg's `qa.sql` test for a tributary's flow landing above its junction. Code review round 3 found that the test fires mostly on ordinary confluences (96 of 110 in the Fraser). The pick is one of them, so the site shows an ordinary confluence. The miscount is filed as fwapg#59.

## Measurement

- **Rule 1:** routed PCIC as published against PCIC's own PNWNAmet outlet series over 1981–2010 passes at all 244 scored gauges with an outlet. Annual flow agrees within 1e-4 at 242 of them, and the largest difference is 0.12 % (08LE031, where the networks disagree). This turns fwapg's design statement into a measurement.
- **Rule 2:** the absolute difference between the 9-GCM median and PNWNAmet's 1981–2010 annual flow, over observed flow, is (median over gauges) Fraser 0.082 (fail, against a bound of 0.05), coast 0.026, Columbia 0.037, Peace 0.019. The signed differences are −7.3 %, −2.0 %, −3.3 % and +1.5 %. The median share NSE drop is within 0.05 in every domain.
- **Crosswalk flags:** the share of outlets placed is 98.7 % in the Fraser, 93.9 % on the coast, 49.4 % in the Columbia and 63.2 % in the Peace; most unplaced outlets have no candidate.
- **Cost:** 2,194 CMIP6 outlet series took 798 MiB and 35 min, one request at a time. A whole CMIP6 run is about 17 GiB.
- Each report line is in `data/checks/channel_scale_pilot_20260717.txt`. Two runs from the cache gave byte-identical reports after every fix.

## Evidence

- Run logs and reports: `data/logs/168/run*_20261123.log`, `data/logs/168/report_run*.txt`.
- Fetch log: `data/logs/168/channel_scale_fetch.tsv`.
- All three are in the main checkout's `data/logs/168/`; the fetched series are in its `data/channel_scale/raw/`.
- Code review: `review-round1.md` to `review-round4.md`, verdict in `review-verdict.md`.

## Owed

- Draft a short note to PCIC with the pilot's result, as #9 asks ("share the result with PCIC if it supports scaling up"); shown to the owner, sent only with their word (outside our repos).

Closed by: PR (opened next, for #168)
