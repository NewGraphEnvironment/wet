# #242, backlog move 26, first PR: Hakai's own stations (#233); the newer provincial pin waits (#232)

## Outcome

Planned as batch 29 (a newer provincial pin, #232, and Hakai's other four watersheds, #233) with batch 30 (#227) owed to a second PR. The owner answered the plan's five open decisions as recommended at the resume (2026-11-27). The bar a newer pin must pass, and the regulation rule's Amendment 4, were registered and pushed (82aa3f24) before any new provincial file was read. The province's `Discharge_Archive_2019Oct_2021Oct.csv` then proved byte-identical to the 20261028 pin's, so a newer pin would carry the unrevised January–September 2021 and fail the bar at four stations. The owner chose no new pin (answer 6), and #232's body records why it waits. This PR ships #233 against the 20261028 pin. Watersheds 693, 708, 819 and 1015 are stations of their own under the package's numbers (WTS693, ...), read by `wet_station_daily()` and listed by `wet_station_list()`. Their reading rules were registered before any of their days was counted: an hour whose `Qrate` is "NA" is dropped, and WTS708 takes the paper's Table A1 position, because README Table 1 repeats WTS693's coordinates for it. The regulation status was rerun under Amendment 4 and the status file now holds the Hakai registry too. Findings: `research/station_sources.md` ("The bar a newer pin must pass", "The Hakai package in wet", "Regulation per non-HYDAT station").

## Measurement

- **The provincial files, 2026-11-27.** The 2019–2021 archive downloaded at 23:07:55Z: md5 `d48e04430a139b4e8a2a4f83011fa933`, the 20261028 manifest's. Only `Discharge.csv` and `Discharge_Archive_Post_20251001.csv` had changed (Post: 68,338,530 bytes against 67,708,536).
- **The bar on the old pin** (cached copies, January–September 2021, compared hours equal at 3 decimals): 07FC0001 100 % of 4,034; 08MH0054 3.2 % of 6,445; 08NM0004 1.6 %, 08MH0056 0.03 % and 08NM0002 0.0 %, each of 6,552. Strict 3-decimal equality and #190's tolerance agree on 99.996 % of 277,485 hours where the copies agree (January 2022 to May 2026). In the five off-the-hour spans (20,484 hours), each pinned hour equals the portal's first point in that clock hour on 100 %. This turned owner decision 4's bar from an assumption into a predicted fail, and it changed what the PR builds.
- **Hakai's own stations** (`data/checks/station_sources_hakai_8318556d2baf.txt`): 1,885–2,203 kept days each, 85.2–97.6 % approved, 5–6 complete chinook window-years, so all four pass the station test. The three continued rows are unchanged.
- **Regulation** (`data/checks/station_regulation_20261028.txt`): 261 stations. The 257 earlier statuses and reasons are unchanged on the same published build (catalog digest `d554e3aa…`). The four Hakai stations are `unknown`: their names give no stream and they have no stated drainage area, so none has an accepted snap. A rerun from the caches writes both files byte for byte.
- **Wrong turns.** The plan expected to pin first and test after, but a header read and one 100 MB download decided the bar before any pin was built. The README's duplicated WTS693/WTS708 coordinates were caught only by reading the paper's Table A1 xlsx. The reader refused the four watersheds outright until the "NA" hour was registered.
- **Code check.** Four rounds; round 3 restored 20 defects and found one guard untested (fixed with a test that goes red without it); none found a defect inside a fix.

## Evidence

`data/logs/242/` in the main checkout of the machine that ran them (`station_regulation_20261127T*`, `station_sources_hakai_20261127*`, `test_20261127.log`).

## Owed

- Phase 2, batch 30 (#227): a HYDAT gauge continued by the provincial station at its site. Built in a second PR from main after this one merges (answer 5), under this plan's owner decisions 1 and 2, on the 20261028 pin. Its phase list is in `task_plan.md` here.
- #232 resumes when the province's `Discharge_Archive_2019Oct_2021Oct.csv` Last-Modified moves; this plan's answers 1, 2 and 4 stand for it.

Closed by: PR from branch `242-backlog-move-26-a-newer-provincial-pin-h` (#233; #242 stays open for batch 30)
