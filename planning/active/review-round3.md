# Code-check round 3, #81 (branch 81-retire-fit-20251014-as-a-gate-re-decide vs main)

## The mechanism behind rounds 1 and 2

Both defects come from one assumption. The design treats "the AET that ships" as something the
pipeline can recompute, or read back from what it last wrote. So the user's decision was never
given its own record, with its scope (which fit: key x release, and which AET it was made for)
and its lifecycle (how it is created, carried and invalidated).

- Round 1: no record existed. The gate could send a choice to the user, but nothing the user
  wrote could come back in.
- Round 2: the record was a pipeline output (`fits.rds`), so the next run rewrote the decision.

The round 2 fix gives the decision a record inside one fit directory (`aet_decision.txt`, plus
a `"cfu"` literal). The same assumption still governs:

- (a) the decision's scope beyond that directory. A new release or a new province key is a new
  directory, and the carry is a manual copy.
- (b) every other place that restates the decided AET as a literal.
- (c) the other decision files, which record a choice without recording the AET it was made
  under.

## Findings

- **[severity: fragile]** scripts/wb_aet_compare.R:174 (with CLAUDE.md:28, "copy the file into
  each later release's fit"). The carry is a manual copy, and a missed copy fails open in one
  direction.
  - At a new release, or a new key (`wb_key_dir()` changes the fit directory too; CLAUDE.md names
    only "later release"), a fit without `aet_decision.txt` falls back to `decided_aet = "cfu"`.
  - If the user had switched to X and the rule now returns cfu, `to_user` is FALSE. The winner
    file is written and cfu ships. The user's switch is reverted without the user, which is
    exactly the "a recorded switch keeps gating every later comparison" claim at L168-170.
  - Only the other direction (the rule still picks X) is caught, as a DECISION TO USER.
  - Fix: on a fit whose release is not `wb_shipped_release`, read the shipped fit's
    `aet_decision.txt` as the reference. Or refuse when the shipped fit has one and this fit has
    none or a different one. That file is a decision file, not a pipeline output, so it does not
    reopen round 2.

- **[severity: fragile]** scripts/discharge_publish.R:291-293. The manifest's `wet_balance`
  description hardcodes "CGIAR actual evapotranspiration floored by Fu-Budyko".
  - Round 1's fix makes a non-cfu AET shippable. When one ships, the published manifest
    mislabels the balance's AET, and no check ties this text to `fits$aet`.
  - The same block conditions the snow sentence on `fits$share_spec` (L295), so this is an
    oversight, not a design choice.
  - #83 lists it as a related step, but nothing stops a publish meanwhile. A one-line
    `if (!identical(fits$aet, "cfu")) stop(...)` beside it closes it until the description is
    built from `fits$aet`.

- **[severity: fragile, doc]** scripts/wb_upstream_identity.R:8-9 (not in this diff, but it
  states the carry list). It says the fits "carry their decision files (pooled_variant.txt,
  adjust_override.txt) and the AET choice to the new key". The list is now incomplete: it omits
  `aet_decision.txt`, so following it for a key change drops the switch. That is the same
  failure as the first finding. CLAUDE.md:73 lists the three files but gives the copy rule only
  for "each later release's fit".

## Every place the mechanism reaches, and whether it is sound

| place | what it decides from | verdict |
|---|---|---|
| wb_aet_compare.R:174 `decided_aet` within one fit | `aet_decision.txt` or the literal `"cfu"` | Sound inside one fit directory. Deleting or editing the file changes `score_code_md5`, so it stales the winner. |
| wb_aet_compare.R:174 across releases and keys | manual copy | **Not sound**: fails open when the rule returns to cfu (finding 1). |
| wb_aet_compare.R:175 `winner_raw` | `cv_aet-<winner>.rds$keep_adjust`, checked against `score_code_md5` at L41 | Sound. Same code and same decision files as wb_validate.R, so it is the same gate outcome that wb_validate.R:115 would refuse. |
| aet_winner.txt consumers: wb_validate.R:41, wb_output.R:410, segment_output.R:69, discharge_publish.R:188, pcic_routed_lib.R:87 | `c(fits$aet, score_code_md5)` | Sound. `score_code_md5` covers all three decision files, so any decision change stales the winner, and each consumer checks both lines. |
| fits.rds read as "what ships" | each consumer above pairs it with the winner file | Sound, except wb_pooled_test.R:35-39 (pre-existing, not in diff). It reads `fits$aet` gated only on `code_md5`, not on a current winner file. After a DECISION TO USER, a fits.rds left from an earlier ship still passes. Low risk: the test runs once per fit and its output stales everything. |
| pooled_variant.txt | written by wb_pooled_test.R under `fits$aet`; records no AET | Disclosed (the compare report's "leans toward that AET") and filed (#83: decided on the old AET, refuses to rerun). After a switch it silently applies to the new AET. Accepted as filed. |
| adjust_override.txt | tolerance set by the user for cfu's 0.03-point tie; records no AET | Applied to every variant and fold. The report's `adjusted*` note discloses it, and a switch happens only after the user reads that report. Sound as disclosed, but the file does not say which AET it was granted for. Worth one word in its "who and why" line at the next write. |
| score_code_md5 includes aet_decision.txt (wb_score_md5.R:34-38) | hash of the decision files | Sound and conservative. A switch stales all ten `cv_aet` files even though it changes no score, which forces a full rescore (cost only). |
| literal cfu, wb_province.R:139 (MOD16 gap fill) | hardcoded | Disclosed in the compare report (L153-154, L273-276). Sound as disclosed. |
| literal cfu, wb_term_diagnose.R:116-117, wb_gauge_diversion.R:241-242 | `stopifnot(cv$aet == "cfu")` | Sound: they fail loudly after a switch. |
| literal cfu, discharge_publish.R:293 (manifest text) | hardcoded, unguarded | **Not sound** (finding 2). |
| wb_fit_accept.R:47 (fits ship different AETs, so stop) | `fits$aet` of both fits | Sound (loud); filed in #83. |
| wb_cv_lib.R:15 frozen 20251014 | release literal | Sound for everything that sources wb_cv_lib.R. wb_fit_accept.R does not. Its L34 `aet_md5_for("20251014")` now uses this branch's changed scoring files, so `wb_fit_accept.R 20251014 20260717` can never pass again. That contradicts #81's body ("keeps working while the old fit's files exist"). It is harmless for future acceptances (20260717 to next), but the issue body's claim is wrong. |

/Users/airvine/Projects/repo/wet/planning/active/review-round3.md
