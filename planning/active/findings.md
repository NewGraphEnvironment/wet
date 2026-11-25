# Findings — Backlog move 15: Re-run the segment chain and a publish BUILD after 0.4.40 (#208)

## Issue context

Batch 17 of move 15: re-run the segment chain and a publish BUILD after 0.4.40 (#186, PR #197), expecting every part byte-identical to the live manifest and no upload. The live build is a0318b7 (5d50cc1 routed run, 512 parts, receipt and fit beside them).

## Measured 2026-11-25

- m1's `data/wb/768876badf` is 31 MB: `fit_20260717/` (output, shape files) and `upstream/`; no `segment/` or `segment_daily/`. The chain needs m4.
- `scripts/discharge_publish_own.R` is the one list of non-inputs both code guards read (#171); #186 moved `R/wet_segment_daily.R`, `R/wet_segment_monthly.R` and the departure/pilot scripts onto it.

## Errors Encountered

| Error | Resolution |
|-------|------------|
