# Task: Simplify the segment-discharge article: define pick early, map the picked source, drop the Salmon River maps (#71)

**If we do it:** the segment-discharge article answers a user's three questions in order: what the product is, which value to use for my stream, and how far to trust it. It drops to roughly half its length, and with fewer claims in its prose it carries fewer build guards. **If we never do:** the article keeps explaining `pick` in one dense sentence before it says why a default is needed. It keeps two maps a reader cannot tell apart and links to research about a product nobody reads any more.

## Context

`vignettes/segment-discharge.Rmd` (664 lines, from #64) defines `pick` in passing, spends ~170 lines on two Salmon River maps a reader cannot tell apart, has a four-wedge scatter that makes one point, and links research nobody reads. The issue has already decided what replaces these: a province map of the picked source, `pick` in its own early section, six sections in a fixed order, and roughly half the length. The column stays `pick` in v1. This plan turns that into data, test and article changes.

What I found that shapes the plan:
- **Size and draw cost.** Province-wide: 4,907,441 FWA segments. `pick` goes to routed on 3,152,838 and to the balance on 1,380,005; the other 374,598 have neither (369,217 of those have no watershed in the lut; `data/checks/segment_output_20260717.txt`). Main-flow segments of order ≥ 5 (284,553), dissolved by `blue_line_key`, simplified at 2 km and snapped to 100 m, come to about 13k vertices, which fits the 500 KB budget easily.
- **Reading `pick` province-wide** has to come from the published parts (1.1 GB of segment parts; read only `linear_feature_id, source, month, pick`). m1's fwapg has no `discharge.*` table. The guards that already exist (`vd_published()`, `vd_verify()`, `vd_commit()` in `scripts/vignette_data_lib.R`) apply unchanged.
- **Nothing else reads the SALR data.** The monthly vignette uses only the `flow_source` registry layer. The SALR layers are read only by this article and `tests/testthat/test-vignette_data.R`.
- **Unused now, or about to be:** `provenance$routed_order8`, `routed_cov_rows` and `routed_groups`, plus `skill$in_routed` and the `coverage` outline. Only the old province map and the tests use them, and the pick map shows routed's coverage itself.
- **Places that cite the SALR comparison:** README's article line, CLAUDE.md's segment-vignette paragraph, `research/water_balance_method.md` lines 69–74 (they cite the article and the data script as its producer) and NEWS.

## Phase 1: Map data: picked source province-wide
- [x] `data-raw/segment_vignette_map.R`: guard with `vd_commit()`, `vd_published()`, and `vd_verify()` before and after the read. Read `month = 0 AND pick` (`linear_feature_id`, `source`) from the live segment parts with duckdb, joined to the order ≥ 5 main-flow segment ids (`edge_type IN (1000, 1050, 1200, 1250, 1450)`).
- [x] Classify each drawn segment as `pcic_routed`, `wet_balance` or `none`, with every segment classed exactly once. Load the classes into a TEMP table, then dissolve in SQL by `blue_line_key`, class and order band, simplify, and snap. Store the result as layer `rivers`. Tune the order threshold and tolerance to the budget and to legibility at page width (start at order ≥ 5, 2 km).
- [x] Layer `regions`: label points for the Liard basin and the Nechako Reservoir groups (LEUT, UEUT, UNRS, LNRS, as `scripts/segment_output.R` names them). Each point is computed from the group polygons, not typed in. Each carries the picked-source counts over all its segments, which back the prose's claims.
- [x] `zones` becomes a plain (zone, name) table, needed only for the dry zone's name. Drop `segments`, `groups`, `lakes`, `places`, `context*` and `coverage`. Record the published build's `wet_commit` on the layers (no routed fingerprint: the picks come from the published build, whose report checks them).
- [x] `inst/cartography/wet_segment.csv`: add a `pick_source` layer (routed, balance, neither; routed and balance in the `flow_source` colours) and a plain gauge-dot class. Removing the layers only the dropped figures used (`mad_class`, `skill_nesting`, `guide`, `gauge_error`, `province`, `context`) moved to Phase 4, since the old article read them. `flow_source` is untouched (monthly article).

## Phase 2: Values: drop SALR, add province counts
- [x] `data-raw/segment_vignette_data.R`: drop the SALR segment read, `gauges_salr`, the outlet and "holds" queries, `near_km`, the SALR balance-against-fit check (with its `output/100.parquet` read), and the routed-coverage-by-group block. Keep `skill`, the check of routed-at-gauges against fwapg, and provenance.
- [x] Add the province counts the prose quotes: FWA segments in total, and those without a lut watershed. Take neither, no-lut and far-low from the tracked segment report (of the live build's segment commit), held to the reader's picks and fwapg's counts.
- [x] Rerun both scripts on m1 (`WET_FWAPG_COMMIT=341b078`) and check the bundle stays under 500 KB.

## Phase 3: Tests
- [x] `tests/testthat/test-vignette_data.R`: change the expected names and shapes to the new layers and values. Classes must be exactly the three. The map's published commit must equal the values' commit. Every calibration gauge's zone must have a name. Remove the SALR, coverage and `in_routed` expectations.
- [x] Restore-the-bug check: each new guard (class set, commit match) goes red on a planted defect, in a scratch copy.

## Phase 4: Article rewrite
- [ ] **What it is**: the two sources, their periods, where the product lives, and the manifest. How each source was made shrinks to a paragraph each, inside this section.
- [ ] **Which value to use**: `pick` in its own short section. It gives the rule (routed unless under a fifth of the balance on its own line; whichever has a value; neither) and why a default exists, with the counts for routed, balance and neither. Then the province map of the picked source: gauges as plain dots, labels for the Liard and the Nechako Reservoir, a scale bar, and a caption naming the order threshold.
- [ ] **How to read it**: duckdb over the parts, filtered to one group (BULK, which the publish report's row-group pruning line uses), then a short `wet_db_load()` Postgres block.
- [ ] **How good it is**: the score table unchanged, then one sentence each on small basins, headwaters, the dry interior zone, and the Liard without routed coverage. The existing guards stay for each of these. The scatter goes.
- [ ] **Limits**: the bullets tightened, with segments without a value given province-wide. The research path becomes one "how the balance is built" link to `research/water_balance_method.md` on GitHub, at the end.
- [ ] **Validation**: two sentences and the build-report link. The cached-inputs paragraph becomes a code comment.
- [ ] Remove the old registry layers from `wet_segment.csv`.
- [ ] Remove the Salmon River sections, `map_labels()`, `named-on-map`, the frame checks and the unused palettes. Lower the word cap to the new length plus a small margin.
- [ ] Render with `devtools::build_rmd()` or pkgdown. Read the map PNG against the cartography self-review (placement and communication checks 1–12).

## Phase 5: Docs
- [ ] CLAUDE.md's segment-vignette paragraph, README's article line, and a NEWS entry.
- [ ] `research/water_balance_method.md` lines 69–74 and 83: keep the measurement, naming wet 7b83959 as where it was made, since the article no longer shows it (#71). Reword `research/discharge_publish.md:77`, update `research/fwapg_mad_method.md:19` and CLAUDE.md's frame-guard sentence.
- [ ] Record the `pick` → `is_default` at v2 decision in `research/discharge_publish.md`.

## Validation
- [ ] Tests pass (`devtools::test()`), and the vignette builds (`pkgdown::build_article("segment-discharge")`)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

