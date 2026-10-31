# #146: Maxan onto the site table; departure_pilot.R and departure_snow.R retired

## Outcome

Maxan Creek now runs from its row of `scripts/departure_sites.csv` like the other Chinook sites, so the extension, the carried departures and the snow regression have one code path. `scripts/departure_pilot.R` (#120) and `scripts/departure_snow.R` (#121) are deleted; their tracked reports stay as the record. `scripts/departure_site.R` and `scripts/departure_site_snow.R` gate their maxan BULK run on reproducing those reports, every non-blank line at the printed precision except a fixed exemption list, with the change table compared without the site report's added carried columns (`site_parity_pilot()`, `site_parity_snow()` in `scripts/departure_site_lib.R`; `tests/testthat/test-departure_site_parity.R`). The short-record article's data script reads the site run's series and reports, the bundle carries the site row, and the map script and article read the target and snow gauges from it. `scripts/departure_pcic.R` takes #120's box from the row. The data script also refuses a series whose site row or window dates differ from today's, since neither file is hashed (code-check rounds 1 and 3). The research provenance lines name the commit that still holds the retired scripts (d4fae1f). The map was not rebuilt: a rebuild churns only on `vm_lakes()`'s unordered query (#155).

## Measurement

- 919 of the pilot report's 928 table rows reappear verbatim in the Maxan site report; the other 9, the change table, match once characters 83–111 of the site row (the carried % normal and interval) are removed. Every snow table row reappears verbatim.
- Reruns on m4 at 86698df, 2026-10-31 00:54:47Z to 01:09:37Z: four sites, both scripts, every gate passed; every tracked site and site-snow report byte-identical; every series file `identical()` to its pre-run copy but for `code_md5`; Maxan's `mx` without the #126/#152 additions `identical()` to the pilot's saved `mx`.
- The rebuilt short-record bundle is `identical()` to the old one in every element but `provenance` and the new `site`; it was rebuilt twice more after the code-check fixes, each time moving only its commit stamp (last 13e2b3e). The article, rendered from the installed branch and from main, differs only in the bundle's commit stamp; every figure byte-identical.
- Gate proof: each script, run against a doctored copy of its tracked report, exits 1 before writing (report and rds mtimes unchanged); the data script refuses a series under a doctored window date. Helper mutation table in `findings.md` (eight mutations, each red).
- Code-check: three rounds; rounds 1 and 3 each found one fragile instance of one mechanism (a series trusted on its writer's md5, which does not cover the site table or the life-history CSV), fixed; ended by enumerating all 12 inputs the site scripts read and their cover (`findings.md`).

Wrong turns, kept: the first site-gate mutation never applied (a perl condition spent on the report's first line), so its run reproduced the report and exited 0; a map comparison read the fourth layer as `streams` when it is `lakes`; the map rebuild's churn turned out to be `vm_lakes()`'s unordered query and a one-vertex simplification drift, not this branch (#155), so the committed map was kept.

## Evidence

`data/logs/146/` on m4 (site, snow and bundle runs); `data/departure/_pre146/` on m4 (the series before the reruns).

## Owed

- m4: put the main checkout back on `main` and pull (this also clears the pull owed since #152)

Closed by: PR (opened from branch `146-move-the-maxan-pilot-onto-the-site-table`)
