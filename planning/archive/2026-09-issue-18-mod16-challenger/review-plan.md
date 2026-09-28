# Plan review (#18) — Plan agent, 2026-09-27

Read-only agent; findings transcribed here by the parent session. Disposition in the right-hand notes.

## Blockers
- B1 fill codes are uint16 65529-65535 (not 32761-32767), terra applies the 0.1 scale on read. **Already found by the Phase 1 probe; code masks scaled > 6551. Add a plausibility cap (stop if masked max > 3000 mm).**
- B2 disclosure must name every gap code (incl. permanent wetland, unclassified). **Fold into rule text from the MOD16 v6.1 user guide.**
- B3 aggregate NA handling. **Already: value na.rm=TRUE, frac = share of all fact^2 sub-cells valid (outside tiles = gap). Pin invariant frac > 0 <=> !is.na(aet).**
- B4 data/logs is gitignored. **Evidence goes to tracked data/checks/*.txt (as wb_province_run.txt did in #15); plan text corrected.**

## Decision rule
- R1 (d) threshold: the incumbent's as-shipped headwater MAE on this run. **Written into the rule before scoring.**
- R2 fixed incumbent is conservative toward the incumbent (its score is post-selection). **Disclosed; plus a two-stage nested selection (stage 1 then stage 2 inside each fold) as transparency, from one per-fold metric table over all 7 candidates.**
- R3 gap fill dilutes power. **Add frac_mod16 layer; report the upstream MOD16 share of stations and headwater MAE for frac >= 0.8 (transparency). Disclose period mixing in gap cells.**
- R4 freeze processing knobs before the first mod16 score; assert incumbent == "cfu" else stop. **Adopted.**
- R5 report per-fold choice counts. **Adopted.**

## MOD16 processing
- Offline cache hit, search filtering, duplicates. **Already in code (local granules used without search; https .hdf only; year filter; duplicates stop).**
- Validate a download (a login page can arrive as 200). **Adopted: open ET_500m, 2400x2400, before trusting it; delete and stop otherwise.**
- Tile merge with slightly different x/y res. **Two-tile test added; real mosaic checked in the Phase 2 build.**
- Write project() output to file. **Adopted.**
- Constant-field oracle cannot fail. **Adopted: sheared stripe near -130, 57 N checked against exact polygon overlap; mutation to a one-step average must fail.**
- timeout default, raw vs blended name clash, citation. **Default 600 set; fetcher layer renamed et_mod16; DOI in roxygen and manifest.**

## Province / compare / reruns
- Blend after ex is masked; keep existing ex_filled_cells lines byte-identical, append full/partial counts; frac NA->0 before masking; explicit mask. **Adopted.**
- Stage-1 reproduction needs hard-coded #15 numbers. **Adopted.**
- Commit all score_files edits before the 10-variant loop. Do not re-run wb_stations.R. Upstream match tolerance ~1e-12. wb_map.R always overwrites the png. **Adopted.**
- If MOD16 wins, wb_map legend "1981-2010" needs revisiting. **Noted.**
