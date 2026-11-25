# Backlog move 7: scenarios and coverage, after the channel-scale pilot (#169)

**Outcome.** Split as the plan gate decided (2026-11-25): #5's coverage report and map are delivered and close #5; the two checks wet's scenarios rest on (rule 4, what each CMIP6 run lacks against fwapg's crosswalk; rule 5, CMIP5 gridded against PNWNAmet in the Fraser) are registered (4fd260e), coded and wait on PCIC, so #4 stays open, rescoped in place; `research/pcic_hydrology.md` was re-read from what PCIC's robots.txt allows, and #205 stays open for the four claims read only under `/data/`. The products no report scores yet went to #225. The owner chose to ask PCIC before any new request to a disallowed path; the note is drafted for the owner outside this repository. Findings: [`research/pcic_scenarios.md`](../../../research/pcic_scenarios.md) and [`research/pcic_hydrology.md`](../../../research/pcic_hydrology.md). Code check: four rounds, ended by enumeration (`review-enumeration.md`, `review-verdict.md`). Owed outside this PR: #226 (rerun #45 under the new fetch so `scripts/wb_small_basin.R` runs again).

## Measurement

- PNWNAmet's twelve accumulated monthly depths summed to the pilot's annual flow at its four Fraser parity sites to two decimals (salmon 20.45, quesnel 134.18, hope 2476.28, lillooet 99.58 m³/s); 73 Fraser gauges with an outlet, as the pilot's Domains line says; median PNWNAmet share NSE 0.904. Turned "rule 5 can reproduce the pilot's accumulation month by month" from an assumption into a check that gates every CMIP5 request.
- Coverage over 246 watershed groups: published sources both 154, routed on part 44, balance alone 48; scenarios on CMIP6 routed 87, CMIP5 gridded 67, part or mixed 44, none 48; 138 groups touch PCIC's gridded cells, 110 at 0.95 of their area or more.
- `wet_pcic_annual()` on a cached Fraser year: `identical()` on origin/main and on the branch, offline, so the fetch rewrite moved no value.
- Cost: `scripts/scenario_basis.R` about 2.5 min a run from the cache; `scripts/pcic_coverage.R` about 1 min (30 s for the month-0 read of 43 parts over httpfs).
- Requests to PCIC's disallowed paths during the work: none (no fetch log; the gridded cache unchanged at 500 files). Four `.das`/`.dds` and four hydromosaic reads were made during planning, before the robots.txt was read (`findings.md`).

## Evidence

`data/logs/169/` in the main checkout: `scenario_basis_run*`, `pcic_coverage_run*`, `pcic_coverage_map_run*`. Reports: `data/checks/scenario_basis_20260717.txt`, `data/checks/pcic_coverage_20260717.txt`.

## Wrong turns

- Phase 4's first "byte-identical second render" compared the committed PNG with itself: both renders had failed (`magick::image_set_defines()` returns NULL) with their output sent to `/dev/null`. Found in code check round 3; fixed, and the check repeated with each run's last line read.
- A keep-the-newest cleanup built on `ls -t` under the shell's colour alias deleted every map-layer cache; rebuilt by one render, PNG unchanged.

- The scenario script's clean-tree guard counts untracked files, so a draft of the next phase's script in `scripts/` made two runs refuse at once; their copies were the old report, and an "identical" comparison of them would have proved nothing. The draft was moved out and the runs repeated.
- Two tracked reports first printed this machine's absolute paths; replaced with paths under the data root before their tracked runs.
- The coverage map's first render sorted its legends alphabetically and left the rivers out of the legend; caught by the self-review at 700 px. Once fixed, a second render gave the same pixels but not the same bytes until ImageMagick's date chunks were excluded.
- The resume asked the owner the three open decisions although #169's body already recorded them; the owner pointed to the body.

## Owed

- Under answer (a) to open decision 1: PCIC's answer, when it comes, recorded in `research/pcic_hydrology.md`, and the registered checks run under it.

Closed by: PR on branch `169-backlog-move-7-scenarios-and-coverage-af` (fixes #5; #4 and #205 stay open).
