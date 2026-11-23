# Plan review of #187 (Plan agent, 2026-11-23, synchronous, before the parked baseline)
Blockers raised: 2
Owner forks: 1

Each finding was probed before it was folded or declined.

| finding | verdict | where it went |
|---|---|---|
| Blocker 1: any edit to `scripts/departure_site.R` or `departure_site_snow.R` stales every site's saved series (`chinook_sites_data.R:102` checks `code_md5`; `departure_site_snow.R:178`), so Maxan and Gosnell would need rerunning, Gosnell against the live catalogue | confirmed (`chinook_sites_data.R:98`–`:104`) | owner fork: Open decision 3; Phase 2 runs swift and naver only under its recommendation (no script edit) |
| Blocker 2: `Rmd:158` asserts only Gosnell has a non-BULK window set; seven other assertions span every window set (`:81`, `:102`, `:108`, `:136`, `:148`, `:560`, `:581`) | confirmed (`:158`, `:148`) | folded: Phase 3 lists each, case by case |
| Assumption 1: no row names all three UFRA keys; sources differ per row | confirmed against the c97c4d0..4e2d8a0c diff | folded: Phase 1 asserts each row's exact source |
| Assumption 2: `wsource <- source[1]` prints the migration row's source only, dropping Candy et al. from the UFRA header | confirmed (`departure_site.R:414`) | folded into Open decision 3 (fixing it edits the script); recorded in Phase 4 |
| Assumption 3: BULK reports rerun byte-identical only if cd's layers and `pcic.series` are unchanged | confirmed (`departure_site_snow.R:374`) | folded: Phase 2 pre-run check, stop if republished |
| Assumption 4: April migration starts may drop complete windows below 3 at the targets | plausible, unmeasured | folded: Phase 2 pre-run count |
| Assumption 5: no site script names `WET_FWAPG_COMMIT`; `vignette_bib.R` takes the Rmd path; it stops on an entry with no url or DOI | confirmed (grep 0 hits; `vignette_bib.R:110`) | folded: Phases 2 and 3 |
| Gap 1: `identical()` on the bundle fails on rbind row names, `sites$windows`, `gauges` union | accepted | folded: Phase 3 names the expected differences |
| Gap 2: the map draws `values$gauges` | accepted | folded: Phase 3 map item |
| Gap 3: the bundle script needs no logic change | accepted | folded: Phase 3 and the gate notes |
| Gap 4: `research/chinook_sites.md:21` is the key sentence | confirmed | folded: Phase 4 |
| Gap 5: stale pin comment; CLAUDE.md states the cap as 1,060 | confirmed | folded: Phases 1 and 4 |
| Acceptance 1: guard over the wrong set (MORR notes are written; BULK guard does not protect parity); restored defect needs an injection point | accepted | folded: Phase 1 |
| Acceptance 2: Phase 4 greps match nothing today; text diff shows the bundle commit line | accepted | folded: Validation and Phase 3 |
| Ordering 1: commit CSVs before runs, reports before the bundle, bundle on m1, map after | accepted | folded: Phases 1–3 |
| Scope 1: figures filter to BULK; leave them as Gosnell's were | accepted | folded: Phase 3 |
| Scope 2: parity test needs no edit while Maxan's reports stay untouched | accepted | folded: Phase 2 |

## Files the plan names

data-raw/life_history_data.R
data-raw/station_vignette_data.R
inst/vignette-data/life_history_bulk.csv
inst/vignette-data/life_history_morr.csv
inst/vignette-data/life_history_ufra.csv
inst/vignette-data/life_history_cotr.csv
scripts/departure_sites.csv
scripts/departure_site_lib.R
scripts/departure_site.R
scripts/departure_site_snow.R
data/checks/departure_site_swift_bulk_20260717.txt
data/checks/departure_site_naver_bulk_20260717.txt
data/checks/departure_site_snow_swift_bulk_20260717.txt
data/checks/departure_site_snow_naver_bulk_20260717.txt
data/checks/departure_site_swift_ufra_20260717.txt
data/checks/departure_site_naver_cotr_20260717.txt
data/checks/departure_site_snow_swift_ufra_20260717.txt
data/checks/departure_site_snow_naver_cotr_20260717.txt
tests/testthat/test-departure_site_parity.R
data-raw/chinook_sites_data.R
data-raw/chinook_sites_map.R
vignettes/articles/flow-change-sparse-gauges.Rmd
vignettes/articles/flow-change-sparse-gauges.bib
data-raw/vignette_bib.R
vignettes/flow-departure-normal.Rmd
research/chinook_sites.md
CLAUDE.md
