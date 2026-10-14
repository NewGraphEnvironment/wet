# Plan review (#71), Plan agent, 2026-10-14 — findings and disposition

| id | finding | disposition |
|----|---------|-------------|
| B1 | removing `named-on-map` leaves `wordcount` without `f`/`x` | already handled: the rewrite defines both inside `wordcount` |
| B2 | "neither" is invisible at order >= 5 (1,557 drawn segments, ~0.2 % of length); a legend entry points at nothing | not drawn; the caption says the segments without a value are almost all first-order streams, guarded by a new count (`no_lut_order1`) |
| G1 | plan's picked + neither check reads as circular | landed code parses neither from the segment report; plan text updated |
| G2 | "mostly on the central coast" unguarded | dropped from the Limits bullet |
| G3 | Yukon/Alsek/Hay/Skagit named without guard | bullet says "a few northern and border basins", guarded by basins with balance parts and no routed part |
| G4 | "routed far too low" is a claim about the truth | prose says routed is far below the balance's (what the pick implies), with fwapg#24 linked |
| G5 | Liard and Nechako sentences need guards | `liard$pcic_routed == 0`, `nech_bal > 90` in the `pick` chunk |
| G6 | the scatter's sentence needs a guard | `n_rt_closer > n_both / 2` |
| G7 | docs: fwapg_mad_method.md:19, water_balance_method.md:83 and 69-74 (name commit 7b83959), discharge_publish.md:77 (reword), CLAUDE.md:46 | Phase 5 |
| G8 | the `is_default` decision is recorded nowhere | Phase 5: research/discharge_publish.md |
| G9 | the map script never checks the picked ids exist in fwapg | added: picked ids joined to fwapg must be all of them |
| O1 | two Phase 1 boxes ticked but not landed | plan text corrected: the routed fingerprint is not needed on the map (its picks come from the published build); registry removal moved to Phase 4 |
| O2 | article and tests broken between commits | expected on the branch; nothing pushed until Phase 4 lands |
| O3 | both bundles must be rebuilt together | map then values, rerun together |
| A2 | 289k is all edge types; main flow is 284,553 | plan text corrected |
| A3 | the order >= 5 map understates the balance on islands | caption says small and island streams are not drawn |
| A5 | Validation prose overclaims | reworded to what the scripts check |
| AC1 | concrete length target | cap set to 800 words |
