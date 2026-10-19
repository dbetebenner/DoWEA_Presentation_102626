# Student Growth: The Pulse of the Education System

A reveal.js (Quarto) presentation for the **DoWEA Fall Leadership Meeting**,
executive learning session on growth models, **October 26–30, 2026**.

**Live deck:** <https://dbetebenner.github.io/DoWEA_Presentation_102626/>
(GitHub Pages, served from `docs/` on `main`).

The deck reuses the New Hampshire TAC pipeline (NCIEA theme, figure lightbox,
R-to-SVG figures, self-contained `docs/index.html`) in a form suited to a
non-technical leadership audience.

## The argument (38 slides, about 45 minutes)

1. **What student growth is about.** One animated scene defines the two
   terms as a pair. *Status* is what students know and can do at a fixed
   point in time; *growth* is the change in what they know and can do
   across time.
2. **Death to proficiency. Long live proficiency.** Status alone is a poor
   management tool (sports analogy, bubble kids); wear two hats —
   accountability for proficiency, management through growth.
3. **Norm and criterion.** How much did they grow (growth percentiles), and
   is it enough (percentile growth trajectories)?
4. **DoWEA status and growth.** NAEP 2024 achievement, the 2017–2024 trend,
   and DoWEA's mean SGPc of 54.1 (seventh of 52) from the Betebenner & Braun
   NAEP cohort-growth work.
5. **Growth for process management.** Illustrative charts (public demo
   data, Regions A–C) showing how a system finds pockets of strength and
   weakness.

## Present it

Open the live deck, or **`docs/index.html`** locally in any browser
(self-contained, works offline).

- **`S`** — speaker view (per-slide notes + timer)
- **`F`** — fullscreen · **`O`** — overview · arrows / space to advance
- Click any figure to enlarge it
- Slides 5–6 and the SGP-peers slide share one D3 scene stepped by fragments:
  time across (2025 → 2026), grade up (3 → 4); stick-figure students walk
  the diagonal, spring status rails mark the snapshots, and the flow between
  the rails is growth (synthetic Gaussian-copula cohort, so the colors are
  true growth percentiles)

## The pipeline

No student-level DoWEA files are used. NAEP numbers are transcribed public
statistics. School/region charts are computed from the public `SGPdata` demo
file and labeled **Illustrative data** on every slide. The demo's regions
are relabeled **Region A / B / C** so no one reads them as real DoWEA
regions.

```
data/naep_dowea.csv                    ─► R/01_naep_figures.R     ─► Figures/naep/*.svg
data/naep_sgpc_g4_2015_g8_2019.csv     ─► R/02_sgpc_figures.R     ─► Figures/sgpc/*.svg
data/naep_g4_math_2015.csv             ─┘
SGPdata::sgpData_LONG (public demo)    ─► R/03_illustrative_growth.R ─► Figures/process/*.svg
                                         R/04_concept_figures.R  ─► Figures/concept/*.svg
                                                                    + assets/img/qr_code.png
                                         DoWEA_Student_Growth.qmd ─► docs/index.html
```

### Build

```bash
./render.sh            # figures, then render
./render.sh --figures  # figures only
./render.sh --render   # render only
```

or `make` / `make figures` / `make render`.

## Data notes

- **NAEP 2024 achievement** in `data/naep_dowea.csv`, each row carrying a
  source URL (NCES snapshots and the DoWEA / DoDEA 2024 release).
- **Mean SGPc** (Grade 4, 2015 → Grade 8, 2019 mathematics) transcribed from
  the appendix of the IES / NCES briefing *Growth from Snapshots*
  (Betebenner & Braun). `SGPc-foundry` is never read.
- **2015 Grade 4 mathematics** jurisdiction averages from the NCES
  2013–2015 state-trends summary, used only for the status-versus-growth
  scatter.
- The NAEP growth slides report DoWEA mean SGPc **54.1** (SE 1.50; 95% interval
  51.2–57.1; outer band 45.1–63.1; rank 7 of 52; bucket *very high*).
  That analysis is a pseudo-cohort and is relative to the nation in the
  same years. NAEP reports DoWEA as DoDEA; figures relabel at plot time.
- **Jurisdiction names are redacted.** Only DoWEA and the nation are named.
  The named transcriptions live in `data/private/` (gitignored);
  `R/00_anonymize_jurisdictions.R` writes the committed copies with codes
  `J01`–`J51` (SGPc rank order, shared by both CSVs). Figures never label
  another jurisdiction. Exact positions on the status axis are public NAEP
  values, so an unlabeled point can still be matched to a state by anyone
  who looks up the 2015 averages.

**Publishing.** GitHub Pages serves `docs/` from `main`; each render
rewrites `docs/index.html` and `docs/.nojekyll`. To update the live deck,
render, then commit and push `docs/`. The page is public, including the
DoWEA SGPc figures.

## Files

```
DoWEA_Student_Growth.qmd   deck source
R/00_helpers.R             palette and SVG writer
R/00_anonymize_jurisdictions.R  data/private/ → anonymized public CSVs (run by hand)
R/01_naep_figures.R        NAEP achievement charts
R/02_sgpc_figures.R        DoWEA-highlighted SGPc charts (others unlabeled)
R/03_illustrative_growth.R SGPdata demo → process-management charts
R/04_concept_figures.R     height chart, high jump, fan, quadrant, QR
styles/                    reveal.js theme, figure lightbox, D3 scenes
assets/                    fonts, images, vendored d3 v7
data/                      committed public CSVs (named copies in data/private/, gitignored)
summary/illustrative.rds   aggregates computed from the public SGPdata demo
docs/index.html            rendered deck (served by GitHub Pages)
```

## Requirements

- [Quarto](https://quarto.org) ≥ 1.4
- R with `data.table`, `ggplot2`, `SGPdata`, `svglite`, and `qrcode`
