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
  echo "==> Done: docs/index.html"
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
