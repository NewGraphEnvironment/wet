# Plan review (#146), Plan agent, delivered 2026-10-31 by message; written here by the parent

Verdict: no blockers. Findings, by category, and what was done:

- **Gap:** the report gate compared table rows and three prose lines; 43 pilot prose lines carry digits and 32 reappear verbatim, among them the donor chain, which the old `identical(mx)` protected. Fix: gate every line less an explicit exemption list. **Done** (88a503e; each exemption must match exactly one line).
- **Gap (minor):** the comparison is by set, not order. Today's reports duplicate only the per-year table header. **Accepted**, stated in the helper's comment.
- **Assumption:** the snow gate now compares cd's provenance rows, which a republish with identical values moves. **Done:** the three cd rows are exempt. The gate also needs the normals grid for maxan, as #121's run did (stated in the header).
- **Assumption:** the plan said the old gate asserted the snow `snow` list identical; it asserted only `fits` and `series`. The bundle's `identical()` check is the remaining bit-level proof. **Kept mandatory** (held on every rebuild).
- **Ordering:** push the branch before the m4 runs; commit before the data run (`vd_commit()`); land the bundle test with the bundle; code-check before the reruns, since a later edit to the two site scripts stales every rds. **Done** for the first three; the code-check found nothing in the two site scripts, so no rerun was needed after it.
- **Ordering:** confirm the rerun checkout holds the gitignored inputs (`data/wb/stations_20260717.rds`, the normals grid). **Held:** every run passed and every report reran byte-identical.
- **Assumption:** Gosnell reads the live published build's digest; snow reports read cd's latest catalog; the map reads bcdata. **Measured:** Gosnell's report reran byte-identical; the map did churn, on lakes (filed #155).
- **Assumption:** the research recovery lines (`git show d4fae1f:`) need a merge-commit merge. **Noted** for the merge.
- **Scope:** the article is only partly keyed on the row. **Accepted:** labels, nudges and `share_inside("08EE013")` stay as one site's cartography; the catchment parts carry `stopifnot(!anyNA(...))`.
- **Acceptance:** the article text cannot diff empty (commit stamp, software citation). **Measured:** only the commit stamp differed. The new bundle test compares against literals, so it needs no `scripts/` skip.
- **Acceptance:** a gate mutation edits a tracked report. **Done** on m4 with an EXIT trap restoring it.
