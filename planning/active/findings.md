# Findings — Move the Maxan pilot onto the site table and retire departure_pilot.R and departure_snow.R (#146)

## Issue context

**If we do it:** Maxan's pilot, snow regression, data, map and article run from the same site table as the #126 sites, so there is one code path for the method, and a fix lands once. **If we never do:** `scripts/departure_pilot.R` and `scripts/departure_snow.R` stay as copies of `scripts/departure_site.R` and `scripts/departure_site_snow.R`, and an edit to one silently diverges from the other.

#126 generalised the Maxan pilot (#120) and snow regression (#121) to `scripts/departure_sites.csv`. Maxan has a row there only for the parity gates, which make `departure_site.R maxan` reproduce the pilot's series exactly and `departure_site_snow.R maxan` the snow fits.

- Point `data-raw/short_record_vignette_data.R` and `data-raw/short_record_vignette_map.R` at the site runs (`departure_site_maxan_bulk_20260717.rds`), and key the article's hard-coded gauges and labels on the site row.
- Retire `scripts/departure_pilot.R` and `scripts/departure_snow.R`, keeping their tracked reports as #120's and #121's record. Turn the parity gates into a test against those reports.
- `scripts/departure_pcic.R` (#122) copies the Maxan box too; give it a site id.

Relates to #120, #121, #122, #126, #130.


## Parity helpers: mutation table (Phase 1, 2026-10-30)

`tests/testthat/test-departure_site_parity.R` against `scripts/departure_site_lib.R`, each mutation in a
scratch copy (test file and lib copied, `data/checks` linked), `testthat::test_file()` blocks failed of 5:

| mutation | blocks red |
|---|---|
| none | 0 |
| no column cut (site change rows compared whole) | 3 |
| prose lines not compared | 1 |
| change table not compared | 1 |
| snow helper always passes | 1 |
| no guard on a tracked report with no rows | 1 |
| no guard on missing prose lines | 1 |

## Plan review (2026-10-30, Plan agent): what was acted on

No blockers. Acted on: (a) the gate compared table rows and three prose lines, so prose lines carrying
results (donor chain, pool and block counts, coverage) went unguarded, where the old `identical(mx)`
protected the donor chain; the helpers now compare every non-blank line, less an exemption list in
which each pattern must match exactly one tracked line; (b) the snow report's cd provenance rows are
exempt, so a cd republish with unchanged values does not fail the gate; (c) the article diff against
main will differ in the commit stamp and the software citation (expected); (d) Gosnell's report reads
the live published build's digest, so a republish since #152 would move it for reasons outside #146.
Not acted on: an ordered-subsequence check (set-based compare loses nothing on today's reports: the
only duplicated row is the per-year table header); keying the article's remaining literals (labels,
nudges, Buck in `share_inside`) on the row, which would add a second source of truth for one site's
cartography.

Mutation table after (a)-(b), blocks failed of 6: none 0; no column cut 4; change table not compared 1;
no exemption guard 1; table rows only (prose ungated) 2; snow always passes 2; cd row not exempt 1;
no empty-report guard 1.

## Errors Encountered

| Error | Resolution |
|-------|------------|
