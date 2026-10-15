## Outcome

The HYDAT that wet's scripts, data scripts and live tests read is now pinned by release. Before, it depended on which release a machine last downloaded (m1 and m4 disagreed on 2026-10-15).
- **Resolver.** `wet:::wet_hydat(release)` returns `tools::R_user_dir("wet", "cache")/hydat/<release>/Hydat.sqlite3`.
  - It downloads ECCC's current release into a per-call partial directory and renames it into place once the copy passes `PRAGMA quick_check` and its `VERSION` names the release.
  - It refuses a superseded release with a classed `wet_hydat_unavailable` error naming the private S3 backup. Live tests skip on that class only, so a cache holding the wrong file fails rather than skips.
  - It refuses a file that is not whole or holds another release.
- **Scripts.** Every script goes through `wb_hydat(wb_release())`, including the station-flow scripts, the vignette data scripts and `mad_basin.R`'s Fraser check. `WET_HYDAT` is refused rather than ignored.
- **Outputs.** The departure report and `station_map.rds` record the release.
- **Copies.** The copies on m1 and m4 moved into the cache, and both releases were backed up to `s3://fresh-bc/hydat/<release>/`.
- **Two lessons.**
  - The plan review's "truncated file passes the VERSION check" did not reproduce, because SQLite already refuses a truncated file as malformed. An explicit whole-file check was added anyway.
  - Round 1 of the code review caught a value from the database driver assumed to be a double: RSQLite returns PRAGMA page counts as integers, which overflow past 2 GiB.

## Measurement

- **Backups.** Both are private: an anonymous GET answers 403, while the published manifest answers 200 from the same endpoint. Each was read back on m4 to the same md5.

  | release | md5 | bytes |
  |---|---|---|
  | 2025-10-14 | da00052022aa1533b80f9fab7cb8b4d0 | 1,274,108,928 |
  | 2026-07-17 | 0a1c40705f31ca89606560b569ea0af5 | 1,296,893,952 |

  The 2026-07-17 copies on m1 and m4 have that same md5.
- **Fraser at Hope.** The pinned `mad_basin.R` check gives 2664 m3/s over 10,957 days, the tracked `data/basin/100_report.txt` exactly, so the script was not rerun.
- **`station_map.rds` regenerated.** Five layers are `all.equal` to the committed file. Lakes hold the same 19 rows in another order (the query has no ORDER BY), and only a provenance attribute is new.
- **Full suite on m1.** 1,113 pass, 0 fail, 0 skip. The pinned Buck Creek and snap tests ran, not skipped.
- **Mutations.** Each of nine restored defects in `wet_hydat()` turns its own test red.

## Evidence

`data/logs/46/` on m1 (gitignored): test result tables, the departure smoke run, the committed `station_map.rds` the regeneration was compared against. Reviews: `review-plan.md`, `review-round{1,2,3}.md` in this directory.

Closed by: PR (see `/gh-pr-push`), branch `46-pinned-hydat-releases-one-resolver-a-per`
