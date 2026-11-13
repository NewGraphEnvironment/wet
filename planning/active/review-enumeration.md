# Code-check enumeration (#163, after round 4)

Round 4 found a defect inside round 3's fix (`wb_run_compare.R`'s guard tested that a path exists, not that the run holds it), so the loop ends on an enumeration, not a quiet round. Mechanism (round 4's statement): a report line or verdict true only under an assumption about its inputs that nothing checks. Candidate set: every verdict, report line, refusal and guard the branch adds or rewords under `R/`, `scripts/`, `data-raw/` and `vignettes/` (from `git diff ccb6fa7...HEAD` grepped for `sprintf(`, `cat(`, `writeLines(`, `stop(`, `stopifnot(`, `message(`), 13 places:

| place | assumption | what holds it |
|---|---|---|
| `wb_gate_score.R` "made" column | scores made before the rule | refuses any cv file recording `gate_arm` (round 3) |
| `wb_gate_score.R` "made" column | one scoring code per fit | refuses a fit whose variants' `code_md5` differ (round 4) |
| `wb_gate_score.R` "fit_20260717 cfu (shipped)" | cfu is the fit's winner | refuses unless `aet_winner.txt` names cfu (this pass) |
| `wb_gate_score.R` label "0.10-point tolerance" | the override's recorded value | historical: `adjust_override.txt` line 1 read `0.1` (checked on m4, 2026-11-13) |
| `wb_gate_score.R` fit_20251014 path | the frozen record's copy | named in the header and the report, with why |
| `wb_run_compare.R` IDENTICAL | two complete province runs | refuses a run without `upstream/_complete` or with a part missing or empty (round 4; proved on synthetic runs both ways) |
| `wb_run_compare.R` part list | covers what `wb_province.R` writes | rounds 2 and 4 read `wb_province.R`: rds, tif, csv, txt only |
| `wb_inputs.R` "30 observed years" | 30 rows per point | `stopifnot` on the row count per point |
| `wb_term_diagnose.R` same | same | same `stopifnot`; ECCC cache keyed on the script's md5 |
| `wb_validate.R` GATE line and arm | one headwater and one nested MAE | `wb_gate()` refuses anything but four finite values |
| `wb_aet_compare.R` header and `adjusted*` note | a fixed pooled variant, where named | the note's variant clause prints only when one is fixed (round 4) |
| `wb_fit_accept.R` gate text | a pre-#47 fit has no `gate_arm` | it names the override then, true of every fit made before #47 |
| `segment-discharge.Rmd` limits bullet | kept within a margin | guard requires `gate_arm` margin or absent (pre-#47 override, capped at 0.5 < 1.0; round 1) |

Every place has a check or is a historical statement measured on the record. Loop ends here.
