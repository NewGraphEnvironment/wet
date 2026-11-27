# Code check, closing enumeration (#187), after round 4

Round 4 found a defect inside a round-3 fix, so the loop ends on an enumeration, not a quiet round.

**Mechanism (named by round 3, recurred in round 4):** a sentence restates a fact from a neighbouring artifact and its scope shifts one step: the subject is narrowed or widened, or a quantifier loses its set. The guard beside it checks only the number or date.

**Candidate set:** the 41 sentences the branch adds or rewrites in the article, `research/chinook_sites.md`, `CLAUDE.md`, the `data-raw/life_history_data.R` and `data-raw/chinook_sites_data.R` headers and the test comments: rows A1–A13, R1–R16, C1–C4, D1–D5 and T1–T3 of `review-round3.md`. Round 3 held each to its artifact; 37 held. Every row a fix touched since is re-held below. The untouched rows keep round 3's verdict, and round 4 rechecked them and found them holding.

| row | sentence now | artifact | verdict |
|---|---|---|---|
| A6 | "Spring and summer chinook bound for the Fraser above the Thompson enter the river from April [Bradford and Taylor 2023, p. 131; citing COSEWIC 2018]" (article) | Bradford and Taylor p. 131 (Zotero full text, PDF p. 3): populations "upstream of the confluence with the Thompson River ... spring-and summer-run populations, with returning adults entering the Fraser River from April to August (COSEWIC 2018)" | holds: subject equals the page's |
| R4 | research table: "spring- and summer-run adults bound above the Thompson enter the Fraser from April" | the same page | holds |
| D1 | `life_history_data.R` header: "for spring- and summer-run entry to the Fraser above the Thompson from April" | the same page | holds |
| A10 | "the flow figures show only those" | windows, years and change figures and the scores table filter `group == "BULK"`; the maps are not flow figures | holds (round 4) |
| A4 | map captions "with the gauges each borrows from under any of its windows" | map `gauges`: extension and carried donors, union over each site's window sets | holds (round 4) |
| A12 | "rest on survey estimates, not the first and last spawners seen, so their edges are uncertain" | knowledge's UFRA and COTR notes at a475dfe7: "estimates, not the first and last spawners seen" | holds |
| R6 | "estimates written on the record, mostly with no note of how they were made, rather than the first and last spawners seen" | knowledge `research/nuseds_timing.md` at a475dfe7: "an estimate written on the record"; "how a date was made is mostly unrecorded" | holds |
| R3 | "unless BULK's chinook migration and spawning rows equal `life_history_bulk.csv`'s" | `lh_pin_guard()`'s `ch()`: CH migration and spawning rows only | holds |
| R10 | "−15 % (−33..+5)" (Swift, UFRA); "−35 % (−58..+2)" (Naver, BULK, both tables) | bundle raw −15.47 (−33.07..+5.49); −35.18 (−58.49..+1.99), rounded once | holds |
| R12 | "Every UFRA and COTR interval's coverage is 0.93 or more on mean and min7, both routes" | reports' sections 5 and 6: lowest 0.931 | holds |
| C4 / A13 | CLAUDE.md "(1,253)"; `cap <- 1253` and its comment | body prose measured 1,253 | holds |
| D-header | "knowledge's CSV is read with `gh api`, which needs a GitHub login" | `lh_read()` | holds |

Every member of the set is now held to its artifact; none states more than its source.
