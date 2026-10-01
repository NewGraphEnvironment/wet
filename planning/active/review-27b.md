# Plan review: #27 Chinook revision (Plan agent, 2026-10-01)

The Plan agent cannot write files, so its reply was copied here by the parent session. Each finding is listed with what was done about it.

| # | Finding | Disposition |
|---|---|---|
| 1-3, 20 | Filtering the windows breaks several lines at once: the `ice_win` stopifnot, `thin_003`, the `dropped`/`kept` cascade, and the registry assertions. Phases 2-4 cannot land as separate commits that each render. | Adopted. One vignette commit covers the filter, the removals, the registry and the figures. |
| 4 | "25 window-years" is wrong: 15 per station, 30 in all. | Adopted. |
| 5 | Bars against the mean's 100% line mislead, because a median 1981-2010 year is 64-72% of the mean in spawning and fry. | Adopted. Each panel also marks the median baseline year, and the interpretation is anchored on rank (the driest tenth of baseline years). |
| 6 | The hydrograph still draws provisional winter ice readings. | Adopted. The x-axis is clipped to April-October. |
| 7 | Build the bars from cd's anomaly, not from a hand-computed mean. | Adopted: the bar is 100 + anomaly, and the label is cd's `baseline_mean`. |
| 8 | Houston's "1981-2010" baseline is really 1981-1998. | Adopted. Labels give each station's baseline years, computed. |
| 9 | Key figure has no row-count guard; Houston spawning 2025 passes `min_frac` by one day. | Adopted: the guard asserts 30 bars. |
| 10 | Provisional bars carry no mark. | Adopted: provisional bars are drawn lighter, with a legend entry. |
| 11 | `thin` is vacuous now. | Adopted: `stopifnot(nrow(thin) == 0)`, and the no-baseline wording is gone. |
| 12-13 | Scale bar missing; use the gq helpers. | Scale bar added. `gq_bbox_aspect()` and `gq_scale_breaks()` used. The map is ggplot2, not tmap, because the main-registry styles are classed by FWA `feature_code`, which the bundled layers do not carry, and the keymap viewport would print a second figure. |
| 14 | Nested catchments; extent; Bulkley BLK runs to the Skeena. | Adopted: two catchment classes, drawn larger first, extent set to the catchments plus a margin, and the stream drawn clipped by the plot limits. |
| 15 | No BC outline source. | Already done: `fwa_bcboundary`, with small parts dropped. Area is taken before the simplify. |
| 16 | gpkg overhead; skip without sf. | Already done: xz rds, 64 KB; the test has `skip_if_not_installed("sf")`. |
| 17-18 | tmap pin; two figures from a keymap viewport. | Moot. tmap is not used, and it is removed from Suggests. |
| 19 | Title, "key figure" text, figure heights, recipe, NEWS, CLAUDE.md line. | Adopted. |
| 21 | Re-running the data script refreshes the daily series. | Already done: the map has its own script. |
| 22-23 | Ordering of Suggests and test; cd already upgraded. | Done in Phase 1. |
| 24 | Removing the drop rule is safe. HYDAT shows May ice in CH migration once in 30 years. | Noted. |
| 25 | "Open-water provisional flows are close to final" is unverified. | Adopted. The claim is removed from the issue and not made in the vignette. |
| 26 | The shared-dates note was a misread. Overlapping windows make the 24 trend tests correlated. | Adopted. The trend text says the windows overlap. |
| 27 | The spawning stopifnot passes by 1.1 points. | Replaced by the new interpretation's guards. |
| 29 | Agreement between the stations is partly built in, because the catchments are nested. | Adopted. The text says Buck Creek drains a quarter of the area above the Bulkley gauge. |
| 30 | The word-cap comment is stale. | Adopted. |
