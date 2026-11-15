# Findings — Backlog move 2: The published build's record (#164)

## Issue context

**If we do it:** each published discharge build carries one receipt in crate's shape, a database that loads it records which parts it holds, the shipped fit is published beside the product so one watershed group's build runs anywhere, and the manifest gives both reasons a month's days need not average to the month. **If we never do:** the manifest, the vignette bundles and the table comment keep three provenance shapes, consumers key on a comment that names only the last scenario loaded, and `scripts/segment_group.R` runs only where the fit sits.

Order: `planning/backlog.md`, move 2, after move 1 so the fit published beside the product is the refit one. Run `/planning-init <this issue>`: one phase per batch, one PR.

## Batch 3: the published build's record

**Why here:** all four change what the manifest holds or what a reader keeps of it, so one format change and one PUBLISH carry them. The parts' bytes do not change, so that publish uploads the manifest, the receipt and the fit only. #161 is wet's member of the cross-repo provenance track; it is batched here because #88 and #160 take its names.

**Touches:** `R/wet_manifest_write.R`, `R/wet_catalog.R`, `R/wet_db_load.R`, `scripts/discharge_publish.R`, `scripts/segment_group.R`, `DESCRIPTION` (crate in Imports).

**Decided at the gate:** the receipt in place of the manifest or beside it, and how long `wet_catalog()` reads both; the load table's name and columns (a stored schema); which parts of the fit, and per-group samples or `layers.tif`, are published. Open work in crate on the receipt (a v1.1 form, `file:checksum`, a table fingerprint that fails past 2^31 bytes of canonical JSON) can move what the receipt holds; link reads the table comment and refuses one that does not name `scenario historical`.

| issue | title |
|---|---|
| #108 | Manifest: routed PCIC's daily description gives the clamp but not the February fold |
| #161 | Write the shared provenance receipt for published discharge through crate, in place of the manifest |
| #88 | wet_db_load(): record which parts were loaded (key, md5) in the database |
| #160 | Publish the shipped fit beside the discharge product, so one group's build runs anywhere |


## Owed from move 1 (#163)

#163 republishes the product on province run `768876badf` and fwapg 5d50cc1's routed rebuild, which places the Nechako Reservoir (`fwapg#24`): picks moved on 59,206 segments, almost all in LEUT, LNRS, UEUT and UNRS, and the balance did not move. What reads the old build waits for this move:

- [ ] Regenerate the `inst/vignette-data/` bundles (`data-raw/segment_vignette_{data,map}.R`, `data-raw/monthly_vignette_{data,map}.R`) against the new live build. They keep run `92b893c4da` and the old routed build until then.
- [ ] Rewrite the segment-discharge article's Nechako sentences (the `nech_bal > 90` guard and the map's reading) for the placed reservoir.
- [ ] Remake `man/figures/readme-pick.png` (`data-raw/readme_figure.R`); its alt text says the Nechako Reservoir is orange, which no longer holds.
- [ ] On the machine that builds the bundles, reload `pcic` from fwapg 5d50cc1's published export first: the data scripts refuse a routed table other than the tracked routed report's.

**Touches** (added): `data-raw/`, `inst/vignette-data/`, `vignettes/segment-discharge.Rmd`, `man/figures/readme-pick.png`.


## From plan-mode exploration (2026-11-15)

Explored: `R/wet_catalog.R` (holds `wet_manifest_write()`, `wet_catalog()`, `_verify()` and `_digest()`), `R/wet_db_load.R`, `scripts/discharge_publish.R` (the sources block is at about line 373, the PUBLISH upload, keep list and deletes at 97–140), `scripts/segment_group.R` (reads `fits.rds` and `aet_winner.txt`, and samples from `<key>/sample/<G>.rds`), crate 0.16.0's `crt_receipt_write()` and `crt_receipt_keys()` (part SHA-256 over files under `dir`), and link's comment parser (`.lnk_discharge_wet_load_id()` strips `; subset …`; the walk cache refuses a comment without `scenario historical`). On m1, `fits.rds` is 44 KB. m4 didn't answer ssh during planning, so the sample sizes are measured in Phase 4. Peer work that can move the receipt: crate#62 (form v1.1.0, read older forms), crate#50 (fingerprints past 2^31 bytes; not hit, because no table is fingerprinted), and link#466 (link's own receipt, same writer). None of them blocks this.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| ssh m4 timed out (Tailscale, then LAN port 22 refused) during planning | sample sizes deferred to Phase 4 |
