#!/usr/bin/env bash
#
# Build the DoWEA Fall Leadership deck.
#
#   ./render.sh           # figures + render
#   ./render.sh --figures # figures only
#   ./render.sh --render  # render only (assumes figures exist)
#
set -euo pipefail

cd "$(dirname "$0")"

MODE="${1:-all}"
OFFLINE_NAME="DoWEA_Presentation_Betebenner_102626.html"

run_figures() {
  echo "==> [1/4] NAEP achievement figures"
  Rscript --no-init-file R/01_naep_figures.R
  echo "==> [2/4] NAEP SGPc figures"
  Rscript --no-init-file R/02_sgpc_figures.R
  echo "==> [3/4] Illustrative process-management figures"
  Rscript --no-init-file R/03_illustrative_growth.R
  echo "==> [4/4] Concept figures and QR code"
  Rscript --no-init-file R/04_concept_figures.R
}

run_render() {
  echo "==> Rendering deck"
  quarto render DoWEA_Student_Growth.qmd --to revealjs
  mkdir -p docs
  mv -f index.html docs/index.html
  rm -rf index_files
  touch docs/.nojekyll
  cp docs/index.html "docs/${OFFLINE_NAME}"
  echo "==> Done: docs/index.html (offline copy: docs/${OFFLINE_NAME})"
}

case "$MODE" in
  --figures|-f) run_figures ;;
  --render|-r)  run_render ;;
  all|--all|"") run_figures; run_render ;;
  *)
    echo "Usage: $0 [--figures|--render]" >&2
    exit 1
    ;;
esac
