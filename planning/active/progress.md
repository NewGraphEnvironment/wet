# Progress — Vignette: mean annual discharge per segment (#28)

## Session 2026-10-02

- Plan-mode exploration; phases approved by user, with the data/wb copy decision
- Created branch `28-vignette-mean-annual-discharge-per-segme` off main
- Scaffolded PWF baseline from issue #28 with approved phases
- Next: Phase 1 (SALR parity run); the user is copying data/wb from the original machine
- Ran mad_parity SALR on m1 (PCIC fetch, ~4 min); parity 100 %
- Copied a reduced data/wb bundle from m4 (md5 identical for fits, stations, cv); m4 then went off
- Wrote data-raw/segment_vignette_map.R and data-raw/segment_vignette_data.R; data 416 KB
- Found the SALR gap between WB and PCIC; attributed to both products at nearby gauges
