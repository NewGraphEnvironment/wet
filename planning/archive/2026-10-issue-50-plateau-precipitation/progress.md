# Progress — Dry-interior precipitation: score climr against plateau-elevation observations (#50)

## Session 2026-10-07

- Plan-mode exploration — phases approved by user. Gate decisions: score and decide only (a correction gets its own issue); the fetch lives in a wet script, cached under `data/`, not cd
- Source search (located only; no product value computed at any site): snow courses, ASWS daily/hourly archives, PCDS ENV-ASP climatology list, product lineage
- Created branch `50-dry-interior-precipitation-score-climr-a` off main
- Scaffolded PWF baseline from issue #50 with approved phases
- Next: Phase 1, pre-register the rule
- Phase 1: rule pre-registered (`952d9bf`); blind Plan review (`review-rule.md`: 4 blockers, 6 gaps, all accepted) folded into Amendment 2 (`8fe4c6c`), before any product value at a site. A first observation run under the old processing was stopped unread
- Phase 2/3: `scripts/wb_plateau_p.R` rewritten to Amendment 2; first full run started on m1 from a frozen copy (`data/logs/50/*_run1.log`)
- Runs on m1 (`data/logs/50/20261007_*`):
  - check (a) stopped the registered processing at 1.156, so Deviation 1 was recorded;
  - climr returned its 1961_1990 row, so results are filtered to the observed years, and #51 was filed for the same defect in two older scripts;
  - TerraClimate NCSS needed `temporal=all`.
- Verdict: "not decided"; T1 D(climr) 1.09, inconclusive and unstable.
- `/code-check`: 3 rounds, ended by round 3's enumeration of 25 ratios and comparisons:
  - round 1 found the catch-factor denominator (Correction 1);
  - round 2 found the archive's negative P (Deviation 1b) and an unmeasured claim;
  - round 3 named the mechanism (two derivations of the daily increment) and its remaining instance, the flag (Deviation 1c), now verified: 195 vs 196 flags on the overlap years.
- The report reproduces byte-identical from cache.
