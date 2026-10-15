# Progress — Publish the snow-informed monthly balance and regenerate the vignette data (#77)

## Session 2026-10-14

- Plan-mode exploration — phases approved by user
- Created branch `77-publish-the-snow-informed-monthly-balanc` off main (dcd15b0)
- Scaffolded PWF baseline from issue #77 with approved phases
- Next: Phase 1, the upload from m4's wet-16 worktree

- Phase 3 (done while the upload ran on m4): `monthly_vignette_data.R` reads `cv_ann`/`cv_share` from `cv_aet-cfu.rds`; `predict_cv()` dropped. Guards exercised on m1's bundle (4095 rows, spec snow) and each of the four fires on a planted defect (shares rotated, spec, obs + 1e-9, obs_share cell).
