# Code review, round 3 (#43, staged diff): the round-2 fixes, Phase 3/4 sequences, enumeration completeness

No finding lets a wrong fit or a wrong AET ship. Two are dead ends or gaps in the plan's sequence. Three are minor.

## Findings

- **[severity: dead end, conditional]** `scripts/wb_pooled_test.R:25` with `task_plan.md` Phase 4 ("`wb_pooled_test.R` on the shipped fit"). This is round 2's finding 3; the fix only half-landed.
  - The script now requires `WET_HYDAT_RELEASE`, but the plan still names the fit only as "the shipped fit". At that step `wb_shipped_release` is still `"20251014"`, because the switch is the next step. In the not-accepted branch, 20251014 really is the shipped fit, so the plan itself runs the test there.
  - If the test fixes a variant on 20251014, it writes `fit_20251014/pooled_variant.txt`. After any later scoring edit:
    - 20251014's compared winner is stale (`wb_validate.R:56`).
    - The only remedy, `wb_aet_compare.R`, refuses a fit that has `pooled_variant.txt` (`:33`).
    - The carry for 20260717 needs a *current* 20251014 winner (`wb_validate.R:38-40`), so 20260717 cannot be re-carried either.
    - Both fits stay stuck until someone moves `pooled_variant.txt` aside by hand.
  - Fix:
    - Write `WET_HYDAT_RELEASE=20260717` into the Phase 4 step.
    - Decide the not-accepted branch explicitly. Either do not run the test on 20251014 (`wb_pooled_test.R` refuses `release == "20251014"`, and the caveat stays), or document that a recompare of 20251014 needs `pooled_variant.txt` moved aside first.

- **[severity: plan gap, fails closed]** `scripts/wb_validate.R:107-110` with `task_plan.md` Phase 3 and the Phase 4 not-accepted branch.
  - Shipping deletes `<fit>/output/` and `runoff_annual.tif`. Phase 3 copies those two into `fit_20251014/`, and then its own `wb_validate.R cfu` deletes them, twice (once in the code-only proof, once in the rebuild proof).
  - Phase 3 never runs `wb_output.R`. The not-accepted branch says only "keep 20251014".
  - The result is a shipped fit with no output. `wb_map.R` stops ("run scripts/wb_output.R first"), and `segment_vignette_data.R` fails on `read_parquet`.
  - Nothing wrong ships, but Phase 5 dead-ends.
  - Fix: add `WET_HYDAT=<2025-10-14 Hydat.sqlite3> Rscript scripts/wb_output.R` at the end of Phase 3. Add it to the not-accepted branch as well, after any pooled-test rerun on 20251014. Copying `output/` and `runoff_annual.tif` in Phase 3 is then pointless.

- **[severity: minor, report text; still open from round 2 finding 5]** `scripts/wb_pooled_test.R:79-81, 128` with `task_plan.md` Phase 4.
  - When the test is uninformative, nothing tells the operator to rerun `wb_validate.R`. The plan reruns it only "if it fixes a variant".
  - So `data/checks/wb_validation_20260717.txt` keeps the unsoftened caveat. Amendment 4 requires the test to be named, which `wb_validate.R:191-194` does, but only on a rerun.
  - Fix: in the plan, "rerun `wb_validate.R cfu` either way". Add the same hint to the uninformative `how` text.

- **[severity: minor, explicit-env only]** `scripts/wb_validate.R:30`. The carry does not refuse release 20251014.
  - Take the case where `wb_aet_compare.R` unlinked 20251014's winner (`:36`) and then stopped, for example on the #15 reproduction.
  - `WET_HYDAT_RELEASE=20251014 WET_AET_CARRY=20260717 wb_validate.R cfu` would then carry from 20260717. 20260717's own carried winner and fits are current, so the check passes. 20251014 would ship cfu "carried from fit_20260717", with no comparison and a failed #15 reproduction behind it.
  - A self-carry (`WET_AET_CARRY=20251014` left exported) fails closed at `readLines` of the missing winner, so only a deliberate cross-carry reaches this.
  - The enumeration says 20251014's AET is the #15 reproduction only, and this path breaks that.
  - Fix: in the carry branch, `if (release == "20251014" || carry == release) stop(...)`.

- **[severity: minor, still open from round 2 finding 4]** `scripts/wb_fit_accept.R:35`. Acceptance cannot be re-run after `pooled_variant.txt` is fixed on 20260717, because `cv_variant` is no longer `"nested"`. It works on the first pass in the plan's order. Note it in the plan, or accept it as a property of the rule.

- **[severity: cosmetic]**
  - `scripts/wb_fit_accept.R:22-24`. `release <- args[2]` and the `source()` run before the usage check, so a call with no arguments dies with "missing: data/wb/stations_NA.rds" instead of the usage line.
  - `scripts/wb_validate.R:57`. For a stale *carried* winner, the message still says "rerun scripts/wb_aet_compare.R". Compare now refuses non-20251014 cleanly, before deleting anything, so the message only misleads. It should say "rerun with WET_AET_CARRY=<ref>".

## (a) The fixes, checked

- **`aet_md5_for()` sourced from `wb_fit_accept.R`.**
  - The script sources `wb_fit_lib.R` (:20) and sets `release` (:22) before sourcing `wb_score_md5.R` (:23). So `wb_key_dir()`, `wb_stations_path()` and `wb_fit_dir()` are all defined there.
  - Run in a sandbox copy with a fake key dir and both stations files: `aet_md5_for("20260717") == aet_code_md5`, and `aet_md5_for("20251014")` differs, as it should, since the stations file is part of the hash.
- **`score_files_for()` when the other release's stations file is absent.**
  - Sandbox: `aet_md5_for("20251014")` with that file removed stops with "missing: data/wb/stations_20251014.rds".
  - It fails only when the other release is actually used: the carry, or acceptance.
  - On m1 this means the carry and acceptance need both stations files. `segment_vignette_data.R` needs only the shipped one.
- **Phase 3 (copied old 2-line winner, 10 runs, compare, cfu).** This works.
  - Each run: `stale_carry` is FALSE (two lines); `ship_aet` is NA (old md5); the AET is named, so the run writes only `cv_aet-<v>.rds` and its report, and no `fits.rds`.
  - Compare: the release is 20251014, all ten files are present, and there is no `pooled_variant.txt`. It unlinks the winner, reads the files (the md5s match), reproduces #15 and writes `c("cfu", aet_code_md5)`.
  - `cfu` then ships.
  - The copied old `cv_aet-*.rds` would satisfy compare's file-presence check if compare were run early. It would then unlink the winner and stop on md5. With no default AET, that now only costs a rerun.
- **Phase 4.**
  - `WET_HYDAT_RELEASE=20260717 WET_AET_CARRY=20251014 wb_validate.R cfu`: there is no winner, so it carries. `rw[2]`, `rf$aet_md5` and `aet_md5_for("20251014")` all agree, and `rw[1] == rf$aet`. It writes a 3-line winner with 20260717's `aet_code_md5`, and ships the nested fit.
  - `wb_fit_accept.R 20251014 20260717`: both fits pass the `code_md5`, `aet_md5`, `nested` and release checks; the AETs are equal; the comparison is paired. Correct.
  - `WET_HYDAT_RELEASE=20260717 wb_pooled_test.R`: `fits$code_md5 == score_code_md5` holds (no pooled file yet).
  - Rerun `wb_validate.R cfu` with `WET_AET_CARRY` still set:
    - `stale_carry` is FALSE, because `aet_code_md5` excludes the pooled file, so there is no re-carry.
    - `ship_aet` is cfu, and the variant is fixed.
    - The gate stop at :103 precedes every write. On a FAIL the old nested `fits.rds` stays, and `wb_output.R` refuses it, because the md5 now includes the pooled file.
  - `wb_output.R` after the switch: the release defaults to 20260717, `WET_HYDAT` must hold 20260717, and it checks `code_md5` and the winner.
  - Without `WET_HYDAT_RELEASE`, `wb_stations.R` on the 20260717 file stops in `wb_hydat()` (it would read the release as 20251014). That fails safe.
  - Leaving `WET_AET_CARRY=20251014` exported while working on 20251014 is harmless: a self-carry fails at `readLines`.
- **Compare's ordering.** The release check (:26), the presence of all ten cv files (:27-29) and the pooled-variant check (:33) all come before the unlink (:36). Only the md5 and reproduction checks come after it. With no default AET, that costs a rerun and nothing ships.

## (b) Enumeration completeness

- **`scripts/wb_*.R` and `data-raw/segment_vignette_*.R`.** I grepped for `Sys.getenv`, `commandArgs`, `is.null(`, `else "`, `[1]`, `unlink` and `saveRDS`. I found no fallback beyond the table.
  - `WET_PG*` defaults (localhost/fwapg) and the `wb_province.R` workers default pick no release, AET, variant or fit.
  - `segment_vignette_map.R` uses `wb_shipped_release` directly, which is consistent with `segment_vignette_data.R`'s `release == wb_shipped_release` check.
- **Latent defaults in `R/` that the table omits.** No wb caller relies on any of them; every call passes the argument (grepped):
  - `wet_wb_raw(d, aet = "cgiar")` (`R/wet_wb_raw.R:13`). A NULL `fits$aet` stops on `length(aet) != 1`; it does not fall back.
  - `wet_wb_fit(pooled_adjust = c("other", "none"))`. `match.arg` defaults to `"other"`, the specification that fails the gate.
  - `wet_station_select()`, `wet_station_monthly()` and `wet_station_daily()` take `hydat = wet_hydat_path()`, tidyhydat's directory. `wb_stations.R` passes `hydat` to every call.
  - Add these three to the table as "latent; no caller omits it", so a future caller is caught by review.
- **Phase 5 bundle.** `fit_<rel>/pooled_variant.txt` is hashed into `score_code_md5`. If the m1 copy omits it, `segment_vignette_data.R` fails `identical(fits$code_md5, score_code_md5)`. That fails closed, but the copy list should name it, along with `pooled_test.txt`, `stations_<rel>.rds` and the tracked `*_<rel>.txt` reports.
