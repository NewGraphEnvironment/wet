# Code check, round 2 (#127, branch diff fa9b31f...HEAD, planning/ excluded)

## Checklist read

- `index_code-check.md`, `index_code-check-r.md`, `index_code-check-shell.md`, `index_code-check-spatial.md`: in full.
- `code-check.md`: the prose of all 14 H3s under `## Mechanisms` (table rows and evidence blocks skipped). `## Rules that stand alone`, `## Security`, `## Spreadsheets and PDFs`: index only, about 22 headings not read in full (nothing in the diff is in their area).
- `code-check-r.md`: read in full: "`tryCatch()` nests its handlers", "Do not abort inside a handler for a warning raised from C++", "`tryCatch(warning = )` DISCARDS the value", "`on.exit()` at a script's top level never fires", "Postgres row order is never fixed…", "A `skip_if_not()` skips only its own block", "Tests that silently do not run", "`expect_gt()` and friends take no `info`", "A `pkg::` call in a test passes `devtools::test()`…". About 120 other headings at index level only (round 1 read a further dozen in full; none of the round 1 fixes touch their areas).
- `code-check-shell.md`: index only, all ~100 headings not read in full (the diff has no shell code).
- `code-check-spatial.md`: index only this round, all ~115 headings not read in full (round 1 read the three FWA ones; the round 1 fixes touch no spatial code).

## Findings

- **[bug]** `R/wet_pg_trial.R:45-52` (`wet_pg_trial_sql()`): the refusal **fails open** when PCRE hits its match limit. `ws` and `s` are ambiguous: `--[^\n]*` can stop before any later `--` in the same line and restart there, and the lazy `/\*[\s\S]*?\*/` can either end at the first `*/` or extend to a later one, so a run of comments has exponentially many ways to be split. Where the match then fails (any `^`/`;` position not followed by a transaction keyword, which is most of a file), PCRE backtracks through every split, exceeds its limit, and R's `gregexpr()` only **warns** (`PCRE error 'match limit exceeded' for element 1`) and returns `-1`, which the code reads as "no transaction control". Measured by sourcing the file in a scratch copy, no database:
  - `"SELECT 1;\n" + 40 dashes + "\nSELECT 2;\nCOMMIT;"` -> warning, **passes** (20 dashes: refused)
  - the same with `"-- " + 40 dashes` (an ordinary SQL section-separator line) -> warning, **passes**
  - a plpgsql body with 20 consecutive `/* x */` lines after `BEGIN`, then `SELECT 1;\nCOMMIT;` -> warning, **passes** (16: refused)

  That `COMMIT;` then runs inside `dbExecute(..., immediate = TRUE)` and commits everything before it to the shared database; the xid check after the call stops only once the write has happened. This predates round 1 (the same input passes `wet_pg_trial_sql()` at 3a967f0, whose `ws` already had both alternatives), and round 1's widening put the same `s` inside `opt` too. fwapg's two current migrations have no such line (both pass with no warning), so the committed run is unaffected, but one separator line in a future migration silently disarms the guard whose one job is to never migrate the shared database.

  Fix (both halves verified in a scratch copy; every case in `probe.R`-style lists, the fwapg migrations, nested comments, and the round 1 refuse list give the same verdicts as now, and the three cases above are refused in under 1 ms):
  1. Make the comment grammar unambiguous: define a block comment by recursion, as PostgreSQL nests them, and make the repeats possessive:
     ```r
     ws <- "(?:\\s|--[^\\n]*+|(?&c))*+"
     s  <- "(?:\\s|--[^\\n]*+|(?&c))++"
     pat <- paste0("(?im)(?(DEFINE)(?<c>/\\*(?>[^/*]++|/(?!\\*)|\\*(?!/)|(?&c))*\\*/))(^|;)", ws, ...)
     ```
     (`capture.start[, "kw"]` still resolves by name.)
  2. Fail closed regardless: collect any warning from the `gregexpr()` call with `withCallingHandlers()` (record it, `invokeRestart("muffleWarning")`), and after the call returns `stop()` with "could not scan the migration …: refusing to run it".
  Add the 40-dash line and the 20-block-comment body to the `refuse()` list in `tests/testthat/test-wet_pg_trial.R`; both pass through the current code.

## Checked and clean

- Round 1 fix 1, the widened separators and `(;|\z)`: no new false refusal of plpgsql. Bare `BEGIN`/`END` lines, `END IF;`, `END LOOP;`, `EXCEPTION WHEN … THEN`, `BEGIN -- c`, `END$$`, `DO $$ … END $$;`, `CASE … END` and an unterminated last `$$ LANGUAGE plpgsql` all pass; `END;` (a `DECLARE` body or a nested block) is refused, as accepted. `\z` correctly does not fire at a bare `BEGIN` line. Both of fwapg's migrations under `db/migrations/` pass with no warning. Nested block comments (`COMMIT /* a /* b */ c */;`) are refused through the lazy quantifier's backtracking. The new refuse cases go red against 3a967f0's regex (round 1 measured them passing there).
- Round 1 fix 2, `snap_or_message()`: measured. With `on.exit(stop("cleanup")); stop("orig")` it returns `"orig"`; an error caught by an inner `tryCatch()` inside the call never reaches the outer calling handler, so `first` cannot be polluted by a handled error (returns the real escaping one); a successful call returns its value. The `<<-` writes `snap_or_message()`'s own `first`.
- Not a finding: `PREPARE TRANSACTION` with an `E'…'`, `U&'…'`, dollar-quoted or `'it''s'` id is not refused. `PREPARE TRANSACTION` does not commit, the local server has `max_prepared_transactions = 0` (so it errors and the transaction aborts), and the xid check would stop the run.
- `BEGIN … READ\nCOMMITTED;` (a line break inside `[A-Z \t]+`) is not refused, but BEGIN/START inside an open transaction only warns and ends nothing.
- The migration's md5 in the report and `research/station_snap.md` (`98d84a339d18f1eb11a917c60f9012ad`) matches both the gitignored copy and fwapg's `b088b43` blob.
