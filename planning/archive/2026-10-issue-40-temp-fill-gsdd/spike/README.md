# 08E spike scripts (#40)

The real-data comparison that changed the method. Inputs are `data/temp_fill/spike_08E_{water,air}.rds` (gitignored), written by `spike_data.R`.

- `spike_fit.R`: form 1, a single Kalman state on the air2stream recursion. It ran against the pre-commit `wet_temp_fill()`, which was never committed, so it no longer runs against the package. Kept for its holdout definitions.
- `fill2.R` and `spike2.R`: form 2, `S + u`, standalone. This is the form that shipped.

Results are in `../findings.md`, under "Real-data spike".
