# Code-check round 3 (#7): the system2() quoting mechanism

## Clean

No issues found.

## Mechanism

`system2(command, args)` builds one string, `paste(c(env, shQuote(command), args))`, and runs it
through `sh -c`. R quotes the command and any `stdout`/`stderr`/`stdin` file names (read from
`body(system2)`, lines 9, 28-52), but **never the args**. So any argument holding a shell
metacharacter is re-parsed by sh: `:(exclude)x` is a syntax error at the `(`, a space splits an
argument, `?`/`*`/`[` glob, `$` expands. The branch's fix is `shQuote()` over the args.

## Every call site the mechanism reaches (R/, scripts/, data-raw/, tests/)

No `pipe()`, `system()`, processx, callr or sys calls exist; tests/ has none.

| site | args at runtime | quoted | verdict |
|---|---|---|---|
| scripts/discharge_publish.R:48 `git()` | `:(exclude)<path>` (line 177), a manifest commit sha validated `^[0-9a-f]{7,40}$`, `HEAD:<report path>`, fixed literals | yes (this branch) | fixed; exercised read-only on this tree: the `:(exclude)` diff, `status --porcelain`, `rev-parse`, `show HEAD:data/checks/...` all return correctly |
| scripts/discharge_publish.R:87 `aws()` | bucket/key constants, Hive keys (`scenario=.../part-N.parquet`), local hrefs, base64 md5 (`+ / =`), `Contents[].Key` | yes (this branch) | fine |
| scripts/pcic_routed_compare.R:23 `git()` | only literals: `status --porcelain -- R scripts`, `rev-parse --short HEAD` | no | not broken: no metacharacters can reach it |
| scripts/segment_output.R:47 `git()` | only literals (`R`, `scripts`, `data/checks`) | no | not broken |
| data-raw/segment_vignette_data.R:47 `git()` | only literals (`R`, `scripts`, `data-raw`, `data/checks`) | no | not broken |
| data-raw/segment_vignette_data.R:85 `Rscript` | `scripts/mad_parity.R`, `SALR`; stdout/stderr file names are quoted by system2 itself | n/a | fine |
| data-raw/station_vignette_data.R:56 `gh api` | header shQuoted; the path (with `?` and `=`) wrapped in literal single quotes by `sprintf`; `knowledge_sha` is a sha | yes | fine |
| R/wet_cgiar_aet.R:125 `bsdtar` | `rar` and `exdir` shQuoted; the `Sys.which()` command path is quoted by system2 | yes | fine |

The three unquoted `git()` helpers carry the latent shape (a future call passing a pathspec
with `:(` or a path with a space would break them the same way), but no current call does, so
none is reported as a defect.
