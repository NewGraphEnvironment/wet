# Code-check round 4 (branch 242, HEAD 3138f270)

## Checklist read

- `code-check-r.md` (read by heading): `nzchar(NA)` is TRUE; `paste()` with a zero-length argument returns length ONE; `vapply(..., USE.NAMES = FALSE)` strips ALL dimnames; `match()` treats NA as a matchable VALUE; `unlist()` prefixes a `split()` group's name; `[[` on a named ATOMIC vector; `data.frame()` recycles a scalar against a zero-length column; `c()` dispatches on its first argument; `bind_rows()` of all-`NULL`; `system2(stdout = TRUE)` warns on a non-zero exit; `clusterApply()` returns `NULL` for no tasks; A `function(...)` mock hides arguments; `ifelse()` with an all-NA test; `sub()` takes one replacement. 14 read, 118 not read.
- `code-check.md` (read by heading): the prose of all 14 H3s under `## Mechanisms`, without the `|` table rows. "Zero-length, empty, and unset are three different things" and "Restore the bug and prove the guard fires" read in full; the others read as prose with the evidence blocks skipped. The 24 "Rules that stand alone" and Security/Spreadsheet headings not read.
- `code-check-shell.md`: 0 of 75 read. The diff adds no shell code; the only process call is the regulation script's `system2("git", ...)`, covered by the R heading above.
- `code-check-spatial.md`: 0 of 98 read. Nothing spatial changed apart from the data-raw `albers()` call on an existing helper, which I ran on empty input (below).

## The mechanism behind the two zero-row findings

Both earlier findings (round 1: the regulation script's Hakai `data.frame()`; round 3: `wet_station_list()`'s untested guard) come from one assumption. A row builder over a **filtered subset of a registry** (Hakai's own rows, or its continuing rows) assumed the subset is non-empty, because today's shipped registry happens to hold rows of both kinds. When such a builder mixes scalar literal columns (`source = "hakai"`, `network = ...`, `hydat_site = NA`) with zero-length columns, `data.frame()` cannot recycle the scalar onto zero rows and stops (code-check-r.md "`data.frame()` recycles a scalar against a zero-length column"; code-check.md "Zero-length, empty, and unset are three different things"). The other shapes that put a phantom row into an empty result (`paste()` with a zero-length argument, `ifelse()` on an empty test, `split()`/`vapply()` on nothing, `match()` against NA) are the same assumption by other routes.

## Every place in the diff that the mechanism reaches, and whether it holds at zero rows

I ran each of these in a scratch worktree (`load_all()`) or as an isolated snippet, with an empty input.

| Site | Empty subset | Holds? |
|---|---|---|
| `R/wet_station_list.R`, Hakai block | no own rows; also a zero-row registry | Holds: the `any(is.na(hakai$continues))` guard skips it, and `any(logical(0))` is FALSE |
| `R/wet_station_list.R`, `wet_continue_list(p, hakai, hakai$licence)` (unchanged, reached with own rows mixed in) | own rows only, so no continuing rows | Holds: `keep` drops the NA rows, and assigning to `i = integer(0)` does nothing |
| `R/wet_hakai.R`, `wet_hakai_station_days()` | own empty, cont empty, both empty | Holds. Probed: both empty returns `wet_daily_empty()`. Own-only (cont has zero rows) runs `wet_continue_days()` with `match(x, character(0))`, all NA, so every row is kept (test "Hakai's own station is read under its own number" exercises it). Mixed returns WTS693 1885 days and H08KC0626 1885 days |
| `R/wet_hakai.R`, `wet_hakai_hours()` (`none`, `keep`) | no rows (early return), or every hour "NA" | Holds: `[keep, ]` gives zero rows with the types kept |
| `R/wet_hakai.R`, `wet_hakai_stations()` new check | zero rows | Holds (vector predicate) |
| `R/wet_station_list.R`, `wet_station_regulation()` `built` | zero-row status file | Refuses: `unique()` gives `character(0)`, `identical()` is FALSE, so it stops. It fails toward refusal, and the behaviour predates this branch |
| `scripts/station_regulation.R`, Hakai population `data.frame()` | no own Hakai rows | Holds after 51db296d. Probed: `rep(..., 0)`, and `ifelse(logical(0), ...)` is `logical(0)`, which `rbind` coerces to character. `str(st)` is correct |
| `scripts/station_regulation.R`, `against` (`added`, `moved`, `why_moved`, `dropped`) | all empty | Holds. Probed: `sprintf()` with a zero-length argument returns `character(0)`, so no phantom line, and `listed()` prints "". `why` holds no NA in either file (counted 0), so `!=` cannot put an NA into `both[...]`. `prior_digest`'s `grep()` matches exactly one line at the pinned `a08f3207` (counted) |
| `scripts/station_regulation.R`, `src_label[st$source]` and the population counts | — | Holds |
| `scripts/station_sources_hakai.R`, `test` (continuing) and `test_own` | zero continuing; zero own | Holds: `lapply` over an empty vector gives `list()`, and `unlist()` gives NULL, so only the headers print |
| `scripts/station_sources_hakai.R`, `pdays`/`pstart`/diff loop | zero continuing | Holds. Probed: `wet_bcenv_days_read(f, character(0))` queries `WHERE false` (0 rows), `pstart` is `named numeric(0)`, and `pstart[NA]` is NA, so `format()` gives NA, `identical()` with the registry's NA is TRUE, and nothing differs |
| `scripts/station_sources_hakai.R`, `before` | an own station's NA cut | Holds: `is.na(cut)` keeps all of its days. This also fixes the old `date < NA` NA-row for a continuing row with no cut |
| `data-raw/station_sources_hakai.R`, `own` / `watersheds` split | zero continuing; zero own | Holds. Probed: `mapply()` over nothing gives `named list()`, and `all(list())` is TRUE; `albers(numeric(0), numeric(0))` is 0x2, so `km` is `numeric(0)` and `any()` is FALSE; `own$name <- sprintf(<zero>)` is fine; `rbind` is fine; `pdays` queries `WHERE false`; `pstart[NA]` gives an NA `continues_before` |

## The round 3 fix

- In a scratch worktree at 3138f270, `test-wet_station_list.R` runs 12 tests: 0 failed, 0 errors.
- With the guard deleted (`if (!is.null(hakai)) {`), the new test ends in **error** (not failed), from the `data.frame()` recycling. Every other test still passes. So the test reaches the guard.
- Run alone (`test_file(desc = ...)`), the new test makes 3 expectations, 0 failed. It mocks the regulation file, the provincial registry and the Hakai registry. The only real file it reads is the shipped bcenv manifest, through `wet_bcenv_days_key()`, and it needs no cache, HYDAT or another test.
- `test-wet_station_daily.R` at HEAD: 0 failures and 0 skips across all of its Hakai tests, both live ones included (the cache is present).

## Clean

No issues found.

index, diff and changed files read from file
