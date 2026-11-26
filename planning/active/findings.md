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

## Errors Encountered

| Error | Resolution |
|-------|------------|
