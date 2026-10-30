# Student Growth: The Pulse of the Education System

Part of Damian Betebenner's talks: <https://dbetebenner.github.io/talks/>

A reveal.js (Quarto) presentation for the **DoWEA Fall Leadership Meeting**,
executive learning session on growth models, **October 26–30, 2026**.

**Live deck:** <https://dbetebenner.github.io/DoWEA_Presentation_102626/>
(GitHub Pages, served from `docs/` on `main`).

The deck reuses the New Hampshire TAC pipeline (NCIEA theme, figure lightbox,
R-to-SVG figures, self-contained `docs/index.html`) in a form suited to a
non-technical leadership audience.

## The argument (39 slides, about 45 minutes)

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
   NAEP cohort-growth work. One level up, the same cohort design on TIMSS
   places U.S. growth (47.4) in the typical range among education systems.
   A four-rung ladder (international, national, consortium, unique) says
   what each kind of assessment can compare.
5. **Growth for process management.** Illustrative charts (public demo
   data, Regions A–C) showing how a system finds pockets of strength and
   weakness.

## Present it

Open the live deck, or **`docs/index.html`** locally in any browser.

**Offline copy.** `docs/DoWEA_Presentation_Betebenner_102626.html` is the
same deck under a shareable name (about 7 MB), rewritten by every render and
downloadable from the live site at
`dbetebenner.github.io/DoWEA_Presentation_102626/DoWEA_Presentation_Betebenner_102626.html`.
It makes no network requests: figures, d3, scripts and fonts are all
embedded, and it opens by double-click without a web server. Speaker view
(`S`) opens a popup, which some browsers ask permission for.

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
data/naep_g4_math_2015.csv             ─┤
data/timss_sgpc_g4_2015_g8_2019.csv    ─┘   (written by R/00_extract_timss.R)
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
- **TIMSS mean SGPc** (Grade 4, 2015 → Grade 8, 2019 mathematics) for the
  United States and 32 other education systems. `R/00_extract_timss.R`
  reads the committed, jurisdiction-level extract from the SGPc TIMSS app
  (`SGPc-ai-apps/apps/timss/data/timss-xsec-app-extract.v0.json`, checked
  against its SHA-256; override the path with `TIMSS_EXTRACT`). It keeps the
  app's defaults: the `cohort` arm and systems in the comparison pool, with
  benchmarking participants and excluded systems dropped. The United States
  is **47.4** (SE 2.0; 95% interval 43.5–51.3; outer band 37.3–56.9;
  *typical*), relative to international academic peers. The extract's
  ranks count benchmarking participants, so the slide reports the growth
  group, not a rank. Other systems are coded `C01`–`C32`; the named copy is
  in `data/private/`. The NAEP and TIMSS numbers use different tests and
  different peers and do not combine.

**Publishing.** GitHub Pages serves `docs/` from `main`; each render
rewrites `docs/index.html` and `docs/.nojekyll`. To update the live deck,
render, then commit and push `docs/`. The page is public, including the
DoWEA and U.S. TIMSS SGPc figures.

**Fonts.** Headings use Josefin Sans; the D3 scene labels use Noto Sans;
body text is Reveal's built-in Source Sans Pro. The deck does not load
Google Fonts, because Quarto embeds whatever a remote stylesheet returns at
render time. `styles/fonts.css` declares Latin-subset woff2 files in
`assets/fonts/`, built by `tools/subset_fonts.py` (instructions in its
header; all fonts are SIL Open Font License 1.1). Re-run it only if the
deck starts using new weights or characters outside Latin-1 and common
punctuation.

## Files

```
DoWEA_Student_Growth.qmd   deck source
R/00_helpers.R             palette and SVG writer
R/00_anonymize_jurisdictions.R  data/private/ → anonymized public CSVs (run by hand)
R/00_extract_timss.R       SGPc TIMSS app extract → TIMSS CSVs (run by hand)
R/01_naep_figures.R        NAEP achievement charts
R/02_sgpc_figures.R        DoWEA (NAEP) and U.S. (TIMSS) SGPc charts, others unlabeled
R/03_illustrative_growth.R SGPdata demo → process-management charts
R/04_concept_figures.R     height chart, high jump, fan, quadrant, QR
styles/                    reveal.js theme, fonts.css, figure lightbox, D3 scenes
assets/                    subset woff2 fonts, images, vendored d3 v7
tools/subset_fonts.py      builds assets/fonts/*.woff2 (run by hand)
data/                      committed public CSVs (named copies in data/private/, gitignored)
summary/illustrative.rds   aggregates computed from the public SGPdata demo
docs/index.html            rendered deck (served by GitHub Pages)
docs/DoWEA_Presentation_Betebenner_102626.html  identical offline copy for sharing
```

## Requirements

- [Quarto](https://quarto.org) ≥ 1.4
- R with `data.table`, `ggplot2`, `SGPdata`, `svglite`, and `qrcode`
