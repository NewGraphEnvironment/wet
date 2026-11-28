# Findings — Backlog move 22: What we can bring, written down, and the baseline read against Bayesian practice (#238)

## Issue context

**If we do it:** what we can bring to a network model and what we are hoping for from one is written down in one file, beside a list of the baseline's shortcuts with what each costs. **If we never do:** inputs are rebuilt by whoever works on the model, and the baseline is read as a fair yardstick without knowing which of its numbers a fuller model should improve on.

Order: `planning/backlog.md`, move 22. Run `/planning-init <this issue>`: one phase per file, one PR. It can start now: both files read what the whole-station baseline (#213) built.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 22, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

### Batch 24: what we can bring, written down, and the baseline read against Bayesian practice

**Why here:** one reading of the baseline's scripts and scores serves both files, and together they are what a reader working on a network model starts from.

**Touches:** two new files under `research/` (named at the plan gate), `research/README.md`, a check script with its dated log (#218).

**Decided at the gate:** the first file's name and wording, proposed to the owner before it is written: #217's title and body predate the wording settled for the roadmap (#214), which offers and asks and assigns nothing; where the books' local copies are read from (#218); who outside reads the first file, through the owner.

| issue | title |
|---|---|
| #217 | Stream temperature network model: what goes over, what comes back and how it is scored |
| #218 | Read the temperature baseline against Bayesian practice, and say what each shortcut costs |

## Read while planning (2026-11-26)

- Members #217 and #218 both read `FREE` from `members_check.sh`; the move was claimed for this session by `/backlog-dispatch` and re-claimed for the branch.
- knowledge's review (`research/bayesian_alignment.md`, 482 lines, and `data-raw/bayesian_alignment_check.R`, 291 lines, at f0a6cbd0) is the model: quotes in `"..." (<citekey>, p. N)` form, checked on the printed page through `pdftotext` with a folio test; a coverage table per choice with an anchor line that must occur once; verdicts from a fixed set; `n_quotes` fixed. knowledge, cred and link are public repos, so links to them from wet's public files resolve.
- The books' PDFs are under `~/Zotero/storage/PVGNFJC9/` and `~/Zotero/storage/JP3BM8T9/BDA3.pdf` on m1; `pdftotext` at `/opt/homebrew/bin/pdftotext`.
- cred exports `crd_pdf_srch_clm()` and the audit family, none of which checks a quote on a printed page; hence the copy and an offer to cred.
- The baseline's state, from `research/station_temperature_fill.md` ("A station with no record", verified 2026-11-25): 209 stations, regression 293.9 / 298.0 °C-days, benchmark 97.5, population mean 412.8 / 414.1; intervals stop at the parameters (87–94 % at nominal 90 %); the benchmark is in-sample by about 11 °C-days; the simulation draws the parameters independently though intercept and slope correlate −0.49. The fill's "Not done": no hierarchical fit, no parameter uncertainty in the interval.
- Wording: the owner's rules for public text about the stream temperature network model (memory, 2026-11-25) and the roadmap #214 as the reference for tone. #217's own title and body use "goes over", "comes back", "a modelling team", which those rules retire.
- Inputs with no issue that builds them yet: catchment traits per segment (#213 builds them per station). Stations on the network and the SSN object per basin: #223 (move 23, waiting on the fwapg fork's network check).
- Move 20 (#236: #222, #224) changes the fill and may land before this; the anchors are code text, so a moved choice fails the check rather than passing silently.

## Phase 1 (2026-11-27)

- **Inventory.** 64 choices, held in `scripts/temperature_bayesian_alignment_check.R`'s `choices` list (id, file, anchor), not drafted here first: the script is where it has to live, and the table in the research file cites each `file:line`. Coverage: 24 names (the 10 formals with defaults of `wet_temp_fill()` and `wet_temp_gsdd()`, and 14 top-level numeric constants across the scope) each mapped to a row in `registry`. `wb_cv_lib.R` is in `choices` (`share_related()`'s `up | t(up)`) but not in the constants sweep: only that function is in scope.
- **Correction to the plan: gsdd has no `complete` argument.** gsdd 0.3.0.9007's `gsdd()` takes `ignore_truncation = FALSE`, `start_temp = 5`, `end_temp = 4`, `window_width = 7`, `pick = "all"`; `complete = TRUE` is internal to `gsdd_vctr()` (as `research/station_temperature_fill.md` says). The inherited choices are anchored at the `gsdd::gsdd()` call as planned (`gsdd_season`).
- **Books.** Passages located with `cred::crd_search()` on the `statistics` store (opened from knowledge's `data/rag`, the store source being unset in wet) and by grep over each book split into printed pages (Rethinking offset 16, BDA3 offset 10), then read on the page. 20 quotes, all one sentence or less; the check reads each on its printed page.
- **Log.** Written only for the research file with no `MD=` and the books present (Phase 2's line, "the log is #218's file's only", is the one followed; #217's file is checked with `MD=` and writes none). Rerunning gives a byte-identical log.
- **Lint.** After splitting knowledge's semicolon lines, double-quoting its regex and escaping non-ASCII in code (the Write tool had stored the `\u` escapes as literal, partly invisible, characters), the script carries only `indentation_linter` and `line_length_linter`, classes `scripts/temp_baseline*.R` already carry.

### The check can fail (mutation table)

Each break planted on copies in a detached worktree of HEAD plus the new files, run with `MD=` set so no log is written; the committed log and the scope's files were md5-identical before and after.

| planted break | exit | first failure |
|---|---|---|
| a quote's wording | 1 | passage not on the page (p. 408) |
| a quote's page (413 → 412) | 1 | passage not on the page |
| an anchor in `choices` | 1 | anchor occurs 0 times in R/wet_temp_fill.R |
| a row's `file:line` | 1 | cites :275 but its anchor is at :274 |
| a verdict | 1 | last cell is not one verdict |
| a figure (298.0 → 298.1) | 1 | not in `figures` |
| an unlisted figure (42 °C-days) | 1 | not in `figures` |
| a new top-level constant appended to a scope script | 1 | `tb_extra` has no entry in `registry` |
| a registry entry for a name the scope does not set | 1 | registry names `gone`, which the scope no longer sets |
| a row dropped | 1 | no row for `rule_tie` |
| a stray quote mark near a citation | 1 | quote mark within 200 characters of a page citation |
| no PDFs (`ZOTERO_DIR=/nonexistent`) | 2 (0 until code-check round 1) | QUOTES NOT CHECKED, PASS WITHOUT QUOTES; no log written in default mode |
| (round 1) unlisted figures inside listed ones: 7 °C, 1 °C, 4 %, 0 °C-days, and 3 °C with a no-break space | 1 each (passed before the fix) | not in `figures` |
| (round 1) a listed figure removed where a longer number still contains it (0 °C) | 1 (passed before the fix) | listed but not in the file |

A constant inserted mid-file fails first on the moved anchors, which is the check working too; appended at the end it isolates the coverage failure.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| Write tool stored `\\u` escapes as literal (some invisible) characters in the check script | Escaped every non-ASCII character in code lines back to `\\uXXXX` with a script |
| `cred::crd_store_connect("statistics")` from wet: no store source configured | Ran the search from knowledge, whose `.Rprofile` sets it and whose `data/rag` holds the store |
