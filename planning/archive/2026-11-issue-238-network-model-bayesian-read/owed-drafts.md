# Owed after the merge: drafts for the owner's word (nothing posted)

## #217's body, rewritten in the file's terms

**If we do it:** what we can bring to a network model and what we are hoping for from one are written down in one place, beside how it is tested, so work on a model starts from the inputs that exist and its results can be read where the habitat work reads them. **If we never do:** inputs are rebuilt by whoever works on the model, results arrive in a shape nothing reads, and there is no agreed test against the baseline.

## The file

[`research/temperature_network_model.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/temperature_network_model.md) (written in #238): what a stream temperature network model is for; what we can bring, each input as a file with its columns and where it stands (in place, being built and by which issue, or filed and not started: #249 for traits and a prediction point per segment); what we are hoping for; where results would live; how it is tested on the baseline's holdout (#213); and the questions to work through, among them formats, the time step, the size of region fitted at once and how to hold a region with more than one outlet. The baseline read against Bayesian practice (#218) names what a network model could remove.

## Out of scope

- Building any input (each has its own issue).
- The model.
- Licence and credit for model code.

## Done when

- [x] The file exists, and each input in it either exists or names the issue that makes it.
- [ ] A reader working on network models outside our team has read it, and its open points are settled or listed.

Relates to #214, #213, #218

## Decisions

(kept as it stands, with this added) Decided by the owner, 2026-11-27 (#238): both files approved as written; catchment traits and a prediction point per segment are one issue, #249; who outside reads the file, and when, is decided after the PR.

---

## #214, the #217 line in "Being finished"

- [x] **What we can bring and what we are hoping for, written down** (#217): [`research/temperature_network_model.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/temperature_network_model.md). An outside read is still to come.

and item 5: `- [x] **5. The baseline read against Bayesian practice** (#218): [`research/temperature_bayesian_alignment.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/temperature_bayesian_alignment.md), where it takes shortcuts and what each one costs.`

## #223, its Regions line

- **Regions:** one SSN object per basin that holds stations, built from the main-flow tree, with the stations snapped as observation sites. A basin with more than one outlet is held one of the two ways `research/temperature_network_model.md` describes (each outlet's tree as its own network in one SSN object, or one region per outlet), chosen at this issue's plan gate.

## Comment on #236 (move 20)

Move 22 (#238) added `scripts/temperature_bayesian_alignment_check.R`, which holds each row of `research/temperature_bayesian_alignment.md` to the line of `R/wet_temp_fill.R`, `scripts/temp_fill_validate.R` or the baseline scripts that makes the choice. A change to those files moves lines, so this move's build reruns the check (`Rscript scripts/temperature_bayesian_alignment_check.R`) and updates the rows it moves, adding a row for any new formal with a default or top-level numeric constant.

## cred issue (show before filing)

**Title:** A page-anchored quote check: a quote held to its printed page of a library PDF

**If we do it:** a research file's quotes from a book are checked against the page they cite, by one shared function, wherever we write such reviews. **If we never do:** each repo that quotes a book copies the check and its fixes drift apart.

knowledge's `data-raw/bayesian_alignment_check.R` holds every `"..." (<citekey>, p. N)` quote in a markdown file to its printed page of the group library's PDF (front-matter offset per book, a folio test so a wrong offset fails, token matching that survives ligatures and line-end hyphens, ellipsis fragments, quote marks near a citation outside the checked form, a fixed quote count). wet copied that half for `scripts/temperature_bayesian_alignment_check.R` (#238). cred already reads PDFs (`crd_pdf_ext_txt()`) and the store; a function such as `crd_quote_check(md, books)` returning one row per quote with its verdict would let both call one copy. Offered, not started; the two copies are the reference cases.
