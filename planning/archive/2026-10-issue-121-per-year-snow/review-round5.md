# Code-check round 5: the self-md5 fix (a7cbd85), scripts/departure_pilot.R:217-222

Measured 2026-10-26 on R 4.5.2 (macOS, /Library/Frameworks/R.framework), with probe scripts holding
exactly lines 219-222 of scripts/departure_pilot.R at HEAD (plus a first line printing a per-file
marker and a last line printing `self` and `code_md5`), under
<scratch dir>
"Executed" is the file whose marker printed; "md5 ok" compares `code_md5` with `md5 -q` of that file.
The front end that encodes paths is `bin/R` (a sh script): `--file=*` and `-f` pass the path through
`echo | sed 's/ /~+~/g'`, and the result is spliced into an unquoted `${args}`.

## Enumeration

| # | invocation | `self` | run | md5 of executed file? | header claim |
|---|---|---|---|---|---|
| 1 | `Rscript /abs/plain/p.R` | `/abs/plain/p.R` | proceeds | yes | holds |
| 2 | `Rscript plain/p.R` (relative; nothing before line 221 changes the wd: no `setwd` in the pilot, `wb_fit_lib.R`, `~/.Rprofile`; no project `.Rprofile`) | `plain/p.R` | proceeds | yes | holds |
| 3 | `Rscript "/abs/sp ace/p.R"` (round 4's case) | `/abs/sp ace/p.R` (decoded) | proceeds | yes | holds |
| 4 | `Rscript "two  sp/p.R"` (two spaces) | `two  sp/p.R` | proceeds | yes | holds |
| 5 | `Rscript "lit~+~dir/p.R"` with `lit dir/` also present | `lit dir/p.R` | proceeds | yes: R itself decodes `~+~` and executes `lit dir/p.R`, the same file hashed | holds |
| 6 | `Rscript "lit~+~dir/p.R"` with no `lit dir/` | n/a | R fails to open the file (R's own decoding) | n/a | n/a |
| 7 | `Rscript link/l.R` (symlink) | `link/l.R` | proceeds | yes (md5sum follows the link, as R does) | holds |
| 8 | `Rscript ~/x.R` unquoted | shell-expanded path | proceeds | yes | holds |
| 9 | `Rscript '~/plain/p.R'` quoted tilde | n/a | R: "cannot open file '~/plain/p.R'" | n/a | n/a |
| 10 | paths with `'`, `$`, `*`, `[...]`, non-ASCII (`ünï`) | literal path | proceeds | yes (no glob match: the word starts `--file=`) | holds |
| 11 | path with `\t` or a real tab/newline | n/a | R fails to open the split path (`echo` expands `\t`, `${args}` word-splits) | n/a | n/a |
| 12 | path with `\q` (non-escape) | literal | proceeds | yes | holds |
| 13 | path `dbl\\x` (double backslash), `dbl\x` also present | `dbl\x/p.R` | proceeds | yes: `echo` collapses `\\`, R executes `dbl\x/p.R`, the same file hashed | holds |
| 14 | `R --no-echo --file=/abs/sp ace/p.R` / `--file=plain/p.R` | decoded path | proceeds | yes | holds |
| 15 | `R -f plain/p.R`, `R -f "sp ace/p.R"` | `character(0)` | stops at line 220 | n/a | n/a |
| 16 | `R CMD BATCH plain/p.R` (uses `-f`) | `character(0)` | stops at line 220 | n/a | n/a |
| 17 | `R CMD BATCH "sp ace/p.R"` | n/a | R fails to open `sp` (BATCH's unquoted `${in}`) | n/a | n/a |
| 18 | `R --vanilla < p.R` | `character(0)` | stops at line 220 | n/a | n/a |
| 19 | `Rscript - < p.R` | `-` | stops at line 222 (md5 NA) | n/a | n/a |
| 20 | `Rscript -e 'source("plain/p.R")'` | `character(0)` | stops at line 220 | n/a | n/a |
| 21 | interactive `source()` (R console / RStudio: no `--file=` in argv) | `character(0)` | stops at line 220 | n/a | n/a |
| 22 | `Rscript plain/p.R --file=x` (user arg) | two values | stops at line 220 | n/a | n/a |
| 23 | `Rscript --file=plain/p.R` | n/a | Rscript: "File name is missing", exit 1 | n/a | n/a |
| 24 | **`Rscript wrap.R` (or `R --file=wrap.R`) where `wrap.R` does `source("scripts/departure_pilot.R")`** | `wrap.R` | **proceeds** | **no: records `wrap.R`'s md5 (06124de2…), not the pilot's** | **fails** |
| 25 | **`Rscript scripts/departure_pilot.R` (unfrozen, as the header's usage line 8 shows) with the file edited after line 221 runs** | the path | **proceeds** | **no: records the start md5; R reads the script incrementally and executes the edited later lines (probe: md5 a0d7832e… recorded, `LATE B` printed from the edit)** | **fails** |

Not measured: littler `r`, Windows `Rscript.exe` (no `bin/R` sh wrapper, so no `~+~` encoding there),
`callr::rscript()` (it calls `Rscript <file>`, i.e. row 1/2).

## Findings

**[minor]** scripts/departure_pilot.R:219-222 — An invocation that `source()`s the pilot from another
script run under Rscript or `R --file=` (row 24) proceeds and records the md5 of the wrapper, not of the
script executed, contradicting the header (lines 17-19). scripts/departure_snow.R:162 then refuses the rds,
so it fails safe, but only after the whole pilot has run and written the tracked report — the same
late-refusal class round 4 fixed for the space-in-path case. `sys.nframe()` is 0 at an Rscript/`--file=`
script's top level and 4 inside `source()` (measured), so `if (sys.nframe() != 0) stop(...)` beside line
220 would stop it at the start.

**[minor]** scripts/departure_pilot.R:8, 17-19, 218 — With the unfrozen invocation the header itself gives
(`Rscript scripts/departure_pilot.R`), an edit to the script during the run (row 25) is executed while
`code_md5` keeps the start-of-run md5, because Rscript reads the file incrementally. Downstream it fails
safe while the file stays edited (departure_snow.R:162 compares with the current file), but if the file is
restored to its start state before departure_snow.R runs (a branch switched and switched back), an rds
from code that never existed as a file is accepted. Line 218's comment ("a frozen copy, say") names the
remedy, yet the usage line runs the live file; either show the frozen-copy command on line 8 (the
CLAUDE.md convention: `cp scripts/departure_pilot.R "${TMPDIR:-/tmp}/departure_pilot_frozen.R" && Rscript
…`) or narrow the claim to "the md5 of the script file at the start of the run".

No invocation that proceeds records an md5 other than that of the executed file except rows 24 and 25;
every `~+~`/space/backslash/glob variant (rows 3-13) either hashes exactly the file R opened or fails
before running.
