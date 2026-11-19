## Checklist read

- Indexes: index_code-check.md, index_code-check-r.md, index_code-check-shell.md, index_code-check-spatial.md (all read).
- code-check.md `## Mechanisms`, every H3 (most relevant here: "A guard that fails toward pass", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "One fact derived twice").
- code-check-r.md: "`summarise()` and `mutate()` evaluate in order..." not used; "`paste()` with a zero-length argument returns length ONE", "`sort()` and `order()` collate by `LC_COLLATE`" checked against the diff (no hit).
- code-check-spatial.md: "A raster's drawn footprint..." n/a; the map hunk uses `sf::st_line_sample()` / `st_coordinates()` only (no hit).
- the writing convention: "State each claim by the code's definition" and "Check that each guard covers the set its sentence names".

What I checked against the bundle and the reports (read-only R):
- Every substituted covariance_pick score in `score_settings` (n, q25, median, q75; 24 rows) equals, at `%.2f`, the line in section 6 of its site report: no rounding mismatch.
- The `snow` carried rows: exactly one per site, group, window and predictor (no duplicates or drops after the distance carried fits are skipped).
- The `score_rows` index arithmetic (`length(score_rows) - 6 + k`) hits this site and group's six rows, in the same order as `lab6`. `mig_row` is checked before the substitution. Swift (distance) and the extension columns stay as they were.
- The section-6 `held()` formats match `scripts/departure_site.R` (lines 1336, 1351, 1413, 1430) and `scripts/departure_site_snow.R` (line 536, whose `ci_txt` is `ci3`). The distance per-year lines at an ungauged site are held to `pre6`. Section 5 and the race, headline and score-table lines are held to the whole report, but none of their formats occurs in section 6, so nothing passes by matching there.
- Every article guard I checked holds against the bundle; the one sentence below has no guard and is false.

## Findings

- **[severity: bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:495-497: the sentence "Borrowed, the spawning window's lowest seven-day flow fell by X to Y at Maxan, Naver and Gosnell creeks, **again clear only at Maxan**." is now false, and nothing guards it.
  - Under covariance_pick, Gosnell's borrowed spawning min7 range is −56.1 % to −15.3 % (BULK), which stays below no change, as Maxan's (−80.5 % to −37.2 %) does.
  - The opening now says, under the guard `m7_clear == c("gosnell", "maxan")` (line ~120), "clearly at Maxan and Gosnell". So the rendered article contradicts itself.
  - The guard that used to back this sentence (`identical(m7$site_id[m7$pct_hi < 0], "maxan")`) was rewritten for the opening. The change-numbers chunk (lines ~485-489) has nothing that tests this sentence.
  - The word "again" also ties it to the preceding claim about filled-in records ("clear of no change only at Maxan", which `ext` still guards and which still holds). The borrowed min7 result no longer repeats that pattern.
  - Fix: make the clause read from `m7_clear` (as the opening does) and drop "again", or cut the clause.
  - **Rule:** writing convention "Check that each guard covers the set its sentence names"
