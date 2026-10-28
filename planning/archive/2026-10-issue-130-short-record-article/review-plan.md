# Plan review (#130), Plan agent, 2026-10-27

Returned as reply text (the Plan type cannot write files); recorded here by the main session, with the triage below.

## Findings (summarised from the reply)

- **B1** `tests/testthat/test-vignette_data.R` budget lists only the station, segment and monthly bundles, so the committed values bundle fails its set test; no phase adds tests for the new bundles.
- **G1** the #122 sentence quotes numbers in no file the data script reads (0.72/0.67, Maxan's covariance-picked donors, their distances, 1973).
- **G2** only the migration mean's scores were bundled, while the headline is the spawning mean (extension 0.42, carried 0.49) and the migration 7-day minimum scores -0.11.
- **G3** "how much of the change follows snow" has no registered answer; the one-predictor slopes double-count (snow and melt date correlate, r 0.50-0.57).
- **G4** the limits name Houston, not Quick (08EE004), which supplies 31 of the 50 years before 1981 and contains Maxan.
- **G5** Phase 1's rds holds less than the plan says (no before/after table, no cd tags); Phase 2 recomputes the first and parses the second.
- **G6** `CLAUDE.md` (the articles paragraph, "all three articles") and the headers of `scripts/vignette_map_lib.R` and `scripts/vignette_data_lib.R` need the new article.
- **G7** cite ERA5-Land and cd's layers; keep `wet_software_cite()` to installed Suggests.
- **G8** new registry classes need new layer keys (done).
- **G9** HYDAT names are upper case: reuse `to_title()`.
- **O1/O2** bundle and prose iterate; a gauges change forces a map rebuild.
- **A1** the snow rerun's byte identity depends on cd's served layers, fwapg and the local normals; do not touch the snow script again.
- **A2** the flow change is 1931-1980 against 2011-2024 (the series ends 2024); the snow change 1950-1980 against 2011-2025: name each.
- **A3** "ungauged" overstates: the extension needs a record; "short-record" is accurate.
- **A4** say which pool Maxan's own score is from.
- **A5** the carried series and pre-1950 departures were not held to report lines.
- **S1** drop the migration 7-day minimum row: its routes disagree in sign and its extension scores -0.11.
- **S2** the extent is large (about 110 x 100 km): check legibility at 7 in.
- **S3** assert Maxan's stream key by name.
- **AC1** the planned md5 mutation (a scratch copy of the script) cannot work; the mutation used was a series file stamped with another md5.

## Triage

Fixed: B1 (budget and two shape tests, the budget test shown to fail on a stray file), G2 (scores per statistic and window from three report tables), G4, G5 and AC1 (plan wording), G8, G9, A2, A3 (renamed to short-record before any prose), A4 (the regional pool, said in the article), A5 (carried held to its per-year lines; departures cut to 1950-2025, which the report checks), S1, S3. G1: the #122 sentence is dropped, which `writing.md` ("Cut what serves the authors": how a decision was reached) also asks. G3: the article quotes only registered one-predictor slopes and R2, as descriptions of years, never adds them, and claims no share of the change. G6, G7, S2: Phase 4. A1: noted; the snow script is not touched again.
