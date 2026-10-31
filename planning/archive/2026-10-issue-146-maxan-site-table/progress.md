# Progress — Move the Maxan pilot onto the site table and retire departure_pilot.R and departure_snow.R (#146)

## Session 2026-10-30

- Plan-mode exploration — phases approved by user
- Created branch `146-move-the-maxan-pilot-onto-the-site-table` off origin/main
- Scaffolded PWF baseline from issue #146 with approved phases
- Next: start Phase 1
- Phase 1 (3992872): parity helpers and test; mutation table in findings.md
- Phase 2 (d4fae1f): the site scripts' gates read the tracked reports
- Phase 3 (c644439): pilot scripts retired; comments, research provenance and CLAUDE.md repointed
- Phase 5: `departure_pcic.R` reads its box and target from `site_get("maxan")`; `identical()` to the old literals (checked by Rscript). Its header, the registered rule, is left as written (it states the same values); the comment sits at the assignment instead of a header line. Not rerun.
- Plan review delivered (findings.md): prose lines now gated with a fixed exemption list (88a503e)
- m4 reruns 00:54:47Z to 01:09:37Z at 86698df (logs `data/logs/146/` on m4): all four sites, both scripts, every gate passed; every tracked site and site-snow report byte-identical (`git status` clean); every series file `identical()` to its pre-run copy (`data/departure/_pre146/`) but for `code_md5`; Maxan's `mx` without the #126/#152 additions still `identical()` to the pilot's saved `mx`
- Short-record data on m4 at 88a503e: every element `identical()` to the committed bundle but `provenance` and the new `site`; committed from m4's bytes
- Short-record map: NOT recommitted. Rebuilt on m4 and on m1, it differs from the committed map only in the lakes layer: row order (vm_lakes() has no ORDER BY) and one vertex more on Tahtsa Reach and Ootsa Lake (simplification drift in the database); the script's inputs (catchment ids, blue line keys) are `identical()` to the old literals. Pre-existing, filed separately
- Article: rendered from the installed branch and from main; text differs only in the bundle's commit stamp, every figure byte-identical
