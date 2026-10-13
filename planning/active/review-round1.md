# Review round 1: branch 7-discharge-upload vs main (code/report/research)

## Clean

No issues found.

Checked:

- Every `git()` call site in `scripts/discharge_publish.R` (status --porcelain, rev-parse, diff with built_at/seg_commit, show HEAD:<report>, diff with `:(exclude)` pathspecs) and every `aws()` call site (put-object with `--content-md5` base64, `--cache-control no-cache`, list-objects-v2 with `--query Contents[].Key --output text`, delete-object). No argument relies on shell expansion, none is an empty string, none was previously split into two args by the shell; `Contents[].Key` was never globbed (unclosed bracket), so quoting changes nothing there. shQuote handles an embedded `'` correctly (probed). Error messages still paste the raw, unquoted args.
- Probed live (read-only): `system2("git", shQuote(c("diff","--name-only","653fc13","HEAD","--","R","scripts", ":(exclude)..." x4)))` returns `character(0)` with no status, i.e. the BUILD guard now passes as intended.
- Research claims: `wet_db_load()` adds the primary key, the id index and the partial `(scenario, id) WHERE month = 0 AND pick` index only inside `if (created)` (R/wet_db_load.R:119-130); its table comment names the manifest and `wet_commit` (lines 132-139). `wet_catalog_verify()` compares the HEAD's ETag (quotes stripped) to the manifest md5 (R/wet_catalog.R:234-238), so the SSE-S3 / single-PUT statement is accurate.
- Numbers: report rows 43 segment parts summing to 102,790,688 (43,901,481 + 58,889,207) and 24 watershed parts summing to 41,904,356; part-400 pcic_routed has 3,420,157 rows. All match the research doc. Report commit 7c62b9e has no R/ or scripts/ change against HEAD.
