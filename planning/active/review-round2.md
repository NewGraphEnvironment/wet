# Code-check round 2: #123 branch (the round-1 fixes first, then the branch)

## Checklist read

- `index_code-check.md`, `index_code-check-r.md`, `index_code-check-shell.md`, `index_code-check-spatial.md`: all read (37, 111, 67 and 93 headings).
- `code-check.md`: the prose of all 14 H3s under `## Mechanisms` (table rows and evidence blocks skipped). I read these in full: "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "Zero-length, empty, and unset" and "One fact derived twice". For the other 7 I read the headings and bold leads. Not read: 23 (the 14 standalone rules, 6 Security, 3 Spreadsheets and PDFs).
- `code-check-r.md`: read 6 of 111, the areas this diff touches: `sort()`/`order()` collate by `LC_COLLATE`; `ifelse()` with an all-NA test; `paste()` with a zero-length argument; `[[` on a named atomic vector; `match()` treats NA as a value; `read.delim()` quotes by default. Not read: 105.
- `code-check-shell.md`: read 0 of 67. The diff has no shell code.
- `code-check-spatial.md`: read 2 of 93 ("A name is not a key"; "A coordinate stored as an attribute"). Not read: 91.

## Method

I read the round-1 fix diff, the probe as it now stands, the report, the research file, and the bodies of wet#142 and wet#118. I did not run the probe. All I ran was in the scratchpad, against the stored report, the cached Water Tool station list and HYDAT 20260717 (opened read-only):
- the code's `stream_of()` and `albers()` copied, and applied to every one of the 147 passing stations;
- the Tool list, before and after the `n_yr`/WSC filter and the dedup.

These checked out:
- `code_md5` in the report is the script's md5 (`a3719fad…`).
- `count_years(within3 = TRUE)` reads `st$q3_from[i]`, `q_from[i]` and `key[i]` in one row order. All three are built before `st` is reordered at :480, and nothing after :480 reads `key` or `q_from`.
- The 3 km sensitivity takes only the nearest same-stream gauge at 1–3 km. Three passing stations have two or more such gauges with Q: 08JC0003, 08NM0028 and 08NM0066. In each, the farther gauges ran 1919–1982, before the station's years. So "a same-stream gauge" (research :18) and "the nearest" (the report) give the same 4.
- The other near-miss axis is different-name gauges within 1 km. Six passing stations have such a gauge whose Q years overlap theirs. Five are tributaries beside a main river: 08HA0036 against the Cowichan, 08HB0007 against the Nanaimo, 08LG0006 and 08LG0019 against the Nicola, 08NM0047 against the Okanagan. The sixth, HRB5454, overlaps 07FC008 in 2025 only. So none of them is the same site.
- Six facts each match their line: the Tool list holds 391 distinct `nid`s; 19 Regulator rows carry provincial `nid`s, on 17 distinct stations (08LC0005 and 08LC0006 are listed twice); the BCCF 4601/4602 pair to 08HB0011/08HB0008 and Tofino 2601–2604 to 08HC0001–0004; the lower bars 250/238 and 238/227 add up as 195 + 53 + 2 and 185 + 51 + 2; the regulation table holds; and no Water Hub or USGS name matches `regulation_of()`'s regex, so "cbwaterhub: 0" and "usgs: 0" hold even though those two sources are hard-coded `unknown`.
- No commit on the branch carries a `Claude-Session:` line. Nothing mentions a private BC Hydro copy or who manages one.

## Findings

- **[bug: wrong count and claim] probe :545–546, report "Lower bars, period proxy [I]", research/station_sources.md:81. Inside the round-1 fix.** "new listed-period stations 110" is `st$new & st$basis != "daily"`. That set also takes in the 15 provincial stations whose basis is `"no complete day"`: they are `new`, and they are not `"daily"`.
  - So 110 is 95 Water Hub datasets plus 15 provincial stations. Per network: the Water Hub has 69 not in HYDAT and 26 same-site, so 95 `new`; bcenv has 211 − 196 = 15 with no complete day.
  - Research :81 says "The Water Hub's 110 listed-period stations". The Water Hub figure is 95.
  - The 85 and 39 on the same line are right, because those 15 have no rows and so 0 window-years.
  - This is round 1's defect (two populations under one label) moved one axis over. Fix the selector to `st$source == "cbwaterhub"` or `grepl("^period", st$basis)`, rerun, and quote 95.

- **[wrong claim] GitHub wet#142, "To establish", the bullet on stations to treat as one site. Inside the round-1 fix (the body was updated then).** It says the four stations sit beside a gauge "whose years cover most of theirs (08HA0024, 08LC0006, 08MG0002, 08NM0006)". That is false for 08NM0006:
  - Coldstream Creek runs 2016–2023, and 08NM248 holds Q for 2021–2024 only. That covers 3 of its 8 years. The report line reads "3 -> 2", so it drops by one window-year.
  - The other three hold: 08HA0024 has 3 of 3 years covered, 08LC0006 5 of 6, 08MG0002 12 of 13.
  - Suggested wording: "whose years cover some or all of theirs", or name 08NM0006's overlap separately.

- **[public text] planning/active/review-round1.md:57 and :71 (committed in b741812, inside the round-1 fix); planning/active/task_plan.md:26 (outside it).** Round 1 removed private repo names and a local path from findings.md. The same text is now back on the public branch:
  - review-round1.md quotes the four private repo names it asked to remove ("Line 46 names four private repos (…)") and the local checkout path ("Line 56 gives a local machine path (…)").
  - task_plan.md:26 names one private repo in the issue-search task (the one after "fresh").
  - Describe them in words, as findings.md now does. (This file names none, for that reason.)

- **[minor wrong enumeration] research/station_sources.md:105. Inside the round-1 fix.** The 17 Regulator listings are described as "BCER's own (07FA0001, 07FC0001, 10CD0001 and others) beside Okanagan, Shuswap and Lower Mainland stations (08NM00xx, 08LC000x, 08MH0062)". The report's list also holds:
  - 08LG0019, Spaxmn Creek above S Douglas Lake St, which is Nicola;
  - 08NJ0001, which is Kootenay.

  Neither falls in the named regions, and "and others" is attached to BCER's group. Add "Nicola and Kootenay", or "among others" on the second group.

No other defect found in the round-1 fixes or the rest of the branch.

/Users/airvine/Projects/repo/wet/planning/active/review-round2.md
