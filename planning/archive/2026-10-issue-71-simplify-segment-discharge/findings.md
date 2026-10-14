# Findings — Simplify the segment-discharge article (#71)

## Issue context

**If we do it:** the segment-discharge article answers a user's three questions in order: what the product is, which value to use for my stream, and how far to trust it. It drops to roughly half its length, and with fewer claims in its prose it carries fewer build guards. **If we never do:** the article keeps explaining `pick` in one dense sentence before it says why a default is needed. It keeps two maps a reader cannot tell apart and links to research about a product nobody reads any more.

## What is wrong with it now (`vignettes/segment-discharge.Rmd`, from #64)

- **`pick` is defined in passing,** inside the opening paragraph, before the reader knows each segment can have two rows. The rule is that one source per segment is the default, chosen on annual flow and applied to all twelve months (`wet_source_pick()`, #57):
  - routed PCIC, unless its annual flow is under a fifth of the balance's;
  - except off a watershed's own line, where routed is kept however low it is;
  - whichever source has a value where only one does.
- **The Salmon River side-by-side maps look almost identical.** Flow is drawn in wide log-scale bands (0.1, 0.5, 2, 10, 50 m³/s), and the balance's flow there is only modestly above routed's, so few segments change band. The only difference a reader can see is the gauge dots, which the gauge table above the map already gives. The Salmon River is there because wet reproduced fwapg's old annual table on it, not because it shows anything about the two sources. The map, its labels, framing and guards take about 170 lines.
- **The research references serve us, not the reader.**
  - `research/fwapg_mad_method.md` shows wet reproduces fwapg's old unrouted annual table, which is no longer read.
  - `research/water_balance_method.md` ("Refit on HYDAT 2026-07-17") appears as a code path, not a link, and points at an internal decision whose consequence the bullet already states.
- **The scatter with four wedges** takes a figure and a long caption to say one sentence: routed PCIC is closer at most gauges, and both miss some small headwater basins.

## Decided (2026-10-14)

- **Replace the Salmon River maps with a province map of the source `pick` takes:** routed PCIC, the balance, or neither. It shows routed's coverage, the Liard and the other northern basins falling to the balance, and the Nechako reservoir segments where routed is far too low. The calibration gauges are plain dots.
- **Define `pick` early**: its own short section right after "what the product is", with the rule, why a default exists, and how many segments go each way.
- **The column name stays `pick` in v1** and is defined in the article's second section. It is renamed to `is_default` when a v2 is cut for another reason, because under `research/discharge_publish.md` a renamed column means a new version (S3 prefix, crate schema, Postgres table and fresh's query). `is_default` follows fresh's `is_`/`has_` pattern; `q_pick` was set aside because under the product's `<quantity>_<unit>` pattern (`q_m3s`, `runoff_mm`) it reads as a flow.
- **The monthly article (#65) stays separate.** This one is about what the product is and which value to use; that one is about the months.

## Proposed structure

1. **What it is:** the two sources, their periods, where the product lives, the manifest.
2. **Which value to use:** `pick`, as above.
3. **How to read it:** one path first (duckdb over the parts, filtered to a watershed group), then loading into Postgres as a short second block.
4. **How good it is:** the score table as it is, and one sentence each on where it is weak: small basins, headwaters, the dry interior zone, and the Liard without routed coverage. The scatter goes. The province map becomes the `pick` map above.
5. **Limits:** the current bullets, tightened. The research path in the bullet becomes one "how the balance is built" link to `research/water_balance_method.md` on GitHub, at the end.
6. **Validation:** two sentences and the build-report link. The cached-inputs paragraph moves into a code comment.

Data: `data-raw/segment_vignette_map.R` and `data-raw/segment_vignette_data.R` need the per-segment pick by source province-wide, simplified for a page-width map, in place of the Salmon River layers. Guards that only served the removed prose or maps go with them (`named-on-map`, the Salmon River frame checks).

Relates to #57, #64, #65.



## Plan-mode measurements (2026-10-14, m1)

- FWA segments 4,907,441; order >= 4..10 counts: 307,059 / 153,878 / 73,292 / 35,817 / 15,740 / 9,296 / 634.
- Main-flow order >= 5, dissolved by blue_line_key, simplified 2 km, snapped 100 m: 5,113 lines, 13,355 vertices.
- Published pick (data/checks/discharge_publish_20260717.txt, reader rows): routed 3,152,838, balance 1,380,005.
- data/checks/segment_output_20260717.txt: neither 374,598; 369,217 have no lut watershed.
- Segment parts total 1,110 MB; m1's fwapg has no discharge.* schema, so pick is read from the parts.
- Liard groups by name: LIAR, ULRD; Nechako Reservoir groups (scripts/segment_output.R): LEUT, UEUT, UNRS, LNRS.

## Errors Encountered

| Error | Resolution |
|-------|------------|
