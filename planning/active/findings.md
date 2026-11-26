# Findings — Backlog move 26: A newer provincial pin, Hakai's other watersheds, and a HYDAT gauge continued at its site (#242)

## Issue context

**If we do it:** the provincial record is read from a current copy, Hakai's other four watersheds are stations of their own, and a HYDAT gauge whose record stopped, at a site a provincial station now measures, carries its record into recent years, so a departure there is read from the gauge's own baseline. **If we never do:** the province's revised 2021 months and the months since the pinned copy stay unread, four central-coast records stay unread, and the two records at a shared site stay separate.

Order: `planning/backlog.md`, move 26. Run `/planning-init <this issue>`: one phase per batch, one PR. It starts once move 17 has merged: all three build on the registries and chaining it lands.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 26, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 29: a newer provincial pin, and Hakai's other four watersheds

**Why here:** both rebuild the station registries and rerun the regulation status once (#232, #233), and the newer pin adds the recent years batch 30's join carries. Both were split from move 17.

**Touches:** `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `scripts/station_regulation.R`, `scripts/station_sources_hakai.R`, `scripts/station_sources_harvest.R`, the bound, harvest and regulation reports under `data/checks/`, `research/station_sources.md`.

**Decided at the gate:** the snapshot date; the check on the picked stations that the new copy's January to September 2021 is the portal's, before it is trusted; whether the regulation rule's version moves when a third registry is hashed.

| issue | title |
|---|---|
| #232 | A newer provincial pin: the province's revised and added 2021 months, and the months after 2026-10-28 |
| #233 | Hakai's other four Calvert and Hecate watersheds as stations of their own |

## Batch 30: a HYDAT gauge continued by the provincial station at its site

**Why here:** it extends the chaining rule moves 13 and 17 settle, at the two sites where a natural HYDAT gauge with a 1981–2010 baseline gains years (#227).

**Touches:** `R/wet_station_daily.R`, `R/wet_station_list.R`, `inst/extdata/station_sources/`, `tests/testthat/test-wet_station_daily.R`, `research/station_sources.md`.

**Decided at the gate (the owner's: it changes what a caller reads):** whether `wet_station_daily()` returns the provincial days under the HYDAT number or a helper joins them; the same-flow check before any join; how provisional days are labelled beside HYDAT's.

| issue | title |
|---|---|
| #227 | Continue a HYDAT gauge's record with the provincial station at its site |


## Decisions

The owner's, 2026-11-26, at a plan gate for this move:

1. **How a caller reads the joined record (#227).** `wet_station_daily()` returns the provincial days after the HYDAT gauge's last federal day under the HYDAT number. Those days keep `source = "bcenv"` and the provincial `status` (`"provisional"` or `"unchecked"`, never `"approved"`). The provincial station is still listed and read under its own number, and `wet_station_list()` gains a column naming the HYDAT gauge each station continues.
2. **The same-flow check (#227).** A rule registered before any value is read. Each record's monthly flow is taken as a ratio to the nearest natural HYDAT gauge whose record spans both eras. A pair joins only where the provincial years' median ratio lies inside the range of the HYDAT years' yearly medians. A pair that fails stays unjoined, with the reason reported. (Neither pair overlaps in time, so no direct comparison exists.)
3. **The regulation rule (#233).** A dated Amendment 4 to `scripts/station_regulation_rule.R` grows the population to Hakai's stations of their own, with nothing else changed; the registering commit moves with it.
4. **Trusting the new pin (#232).** A rule registered before the new copy is read. At each station the #190 portal comparison picked that both copies hold, the new pin's January–September 2021 must equal the portal's on at least 99.9 % of compared hours. Off-the-hour spans are compared against the portal's points within each hour, at the same bar. A station that fails stops the pin and goes back to the owner.

Not yet decided: the snapshot date (the day the files are downloaded, in the gate's draft).



## Found while planning (2026-11-26)

- No overlap at either #227 pair (HYDAT 20260717 `DLY_FLOWS`): 08NJ168 1983-01 to 2015-07, provincial 08NH0001 from 2016-07-29 (named "Five Mile Creek at WSC Station 08NJ168", 0.06 km); 08JC017 1997 to 2007-05, provincial 08JC0002 2016-09-01 to 2020-06-03 (0.03 km). A same-flow check cannot compare shared days. Both provincial stations are `natural` in `regulation_20261028.csv` (08NH0001 with licensed use 8.5 %).
- `scripts/departure_donors.R` refuses unless `wet_bcenv_snapshot` and `wet_bcwatertool_snapshot` are both 20261028 (`dd_snapshot`), so a new pin freezes it as a record.
- `scripts/station_sources_harvest.R` tier (i) reproduces the survey, which exists only for 20261028; `scripts/station_sources_portal.R` names its report by the portal snapshot only, so a rerun on a new pin would overwrite `station_sources_portal_20261125.txt`.
- The Tool and Hakai registries are each held to one provincial snapshot and its reader key (`wet_registry_against()`), and `wet_station_regulation()` holds the regulation file to the provincial and Tool registry md5s.
- `wet_hakai_stations()` refuses a row with no `continues`; `wet_station_list()` lists no Hakai station of its own.
- The regulation rule header (`scripts/station_regulation_rule.R`) names the population as the provincial registry (211) and the Tool's own listings (46); `scripts/station_regulation.R` refuses a rule file that differs from `rule_commit` 6c9cb1e5.
- The rule takes a drainage area only from a Tool header or a HYDAT site, so Hakai's own stations will come out unknown, as the three continued ones did.
- Hakai's raw files and README PDF are on m1 at `data/station_sources/raw/hakai/<commit>/` in the main checkout.
