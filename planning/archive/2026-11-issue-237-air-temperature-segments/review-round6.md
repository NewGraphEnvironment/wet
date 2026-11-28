## Checklist read

From the index (/private/tmp/.../ckwet/index), the headings relevant to a NEWS.md merge resolution:
- code-check-shell.md: "`git diff a..b` compares TIPS; a change on `a` shows up as the branch's" (used three-way/merge-tree comparisons, not two-dot tips)
- code-check.md: "Verification that reads its own output" (compared against git's own merge-tree result, not the resolution)
- code-check.md: "One fact derived twice"
- feature-workflow.md: "The version lives in one place"
- readme.md / writing.md: "Check each claim against the code path a run takes" / "State each claim by the code's definition" (for the bullet's claims)

## Round 6: merge 6ffb11e4 (origin/main, wet 0.7.1, into 237-...)

### What was checked

1. **Only NEWS.md was hand-edited.** `git merge-tree --write-tree 6ffb11e4^1 6ffb11e4^2` reproduces git's own merge (tree 7156e966), reporting auto-merges of CLAUDE.md, DESCRIPTION and research/README.md and a conflict only in NEWS.md. `git diff 7156e966 6ffb11e4 --stat` is `NEWS.md | 4 +---` and nothing else: the four lines are the three conflict markers removed and the `=======` replaced by a blank line. Every other file is as git auto-merged it. `git show --cc` lists only NEWS.md and research/README.md; the research/README.md hunk is git's clean auto-merge (it is identical in the merge-tree result).
2. **No entry lost or altered.** `git show 6ffb11e4^2:NEWS.md` equals the merged NEWS.md from line 5 down, byte for byte (main's side intact: `# wet 0.7.1` with both its bullets, then everything older). The branch's side below its development section equals the merge base 49afd870's NEWS.md, so the branch added nothing else that could have been dropped. The air temperature bullet is identical to the branch's (f1ba35f0).
3. **No conflict marker remains** (`grep '^<<<<<<<\|^=======\|^>>>>>>>' NEWS.md`: none).
4. **Heading order.** `# wet (development version)` on top, then `# wet 0.7.1`, `# wet 0.7.0`, ... as earlier releases did (`git log -S'# wet (development version)'` shows Release v0.7.1 and v0.6.0 promoting such a heading). DESCRIPTION's `Version: 0.7.1` (main's) agrees with the newest numbered heading, so `/gh-pr-merge` can promote the development heading to the next version.
5. **The bullet's claims against the code.**
   - `wet_air_daily()` reads daily mean, max, min (`variables` `tmean`, `tmax`, `tmin`) from `air_temperature/fwa/v1` (`wet_air_id`), `segment_cell` then `cell_daily`: R/wet_air_daily.R.
   - "every segment": scripts/air_publish.R places every segment of `whse_basemapping.fwa_stream_networks_sp`.
   - "each used cell's days from 1950": `used <- unique(lookup$cell_id[...])`, one part per cube year; years are read from the cube and must run contiguously to `air_mask_day` (2025); research/air_temperature_segments.md records 1950–2025.
   - "copied unchanged from cd's daily cube": the series come from `cd::cd_extract_daily()` at each used cell's centre, conformed and read back; roxygen says the values are the cube's unchanged.
   - midpoint cell, else nearest of the eight around it with data: `wet_air_cells()` calls cd at the midpoint (`ST_LineInterpolatePoint(geom, 0.5)`), status `moved` from cd's `cell_moved`; the roxygen "The cell" section says the same.
   - "a segment with no cell is listed, not dropped": `wet_air_cells()` keeps `no_data`/`outside` rows with `cell_id` NA; the reader returns their days with `value` NA.
   - "what `wet_temp_fill()` takes as `air`": roxygen `@seealso` and description.
   - `scripts/air_station_check.R` exists and holds the tree to `cd::cd_extract_daily()` at the stations.
   - "#246": issue title "Cell elevation in the air temperature lookup (cell_elev_m)"; roxygen says there is no elevation adjustment.

## Clean

No issues found.
