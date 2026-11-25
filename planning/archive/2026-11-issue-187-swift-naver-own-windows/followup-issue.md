# Follow-up issue draft (not filed: auto mode refused `gh issue create`, 2026-11-25)

Title: Re-pin the UFRA and COTR chinook windows if knowledge's Fraser timing review revises them

**If we do it:** Swift and Naver creeks stay scored under the upper Fraser (UFRA) and Cottonwood (COTR) chinook windows as knowledge's life history table cites them, once its Fraser and Thompson review lands. **If we never do:** a revised window in knowledge would leave wet's site reports and the comparison article on the old one, with nothing to say so.

#187 pinned `data-raw/life_history_data.R` to knowledge commit a475dfe7, the last commit that touched `data/life_history_timing.csv` (NewGraphEnvironment/knowledge#256 revised only the UFRA and COTR chinook notes). NewGraphEnvironment/knowledge#242 reviews the Fraser and Thompson timing rows; its body says the UFRA and COTR chinook rows stay unless the review finds otherwise.

## The work, when knowledge#242 closes

- Diff `data/life_history_timing.csv` between a475dfe7 and the commit that closes #242. If no UFRA or COTR chinook start, end or source moved, close this issue: re-pinning would only change notes.
- Otherwise move the pin in `data-raw/life_history_data.R`, update `lh_chinook` to the new rows, and rerun it (`lh_pin_guard()` holds BULK and MORR).
- Rerun `scripts/departure_site.R` and `scripts/departure_site_snow.R` for `swift` and `naver` (the BULK reports must rewrite byte-identical), rebuild `data-raw/chinook_sites_data.R` and `data-raw/chinook_sites_map.R`, and revise the Swift and Naver paragraph and the window limit in `vignettes/articles/flow-change-sparse-gauges.Rmd`, and `research/chinook_sites.md`, "Swift and Naver under their own windows".

Relates to #182, #187.
