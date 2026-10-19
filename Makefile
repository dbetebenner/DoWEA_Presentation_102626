# DoWEA Fall Leadership deck — build pipeline
#
#   make            # figures + render
#   make figures    # regenerate SVGs from committed CSVs + SGPdata
#   make render     # render the deck only (assumes figures exist)
#   make clean      # remove rendered HTML + freeze/cache dirs

QMD      := DoWEA_Student_Growth.qmd
HTML     := docs/index.html

.PHONY: all figures render clean

all: render

figures:
	Rscript --no-init-file R/01_naep_figures.R
	Rscript --no-init-file R/02_sgpc_figures.R
	Rscript --no-init-file R/03_illustrative_growth.R
	Rscript --no-init-file R/04_concept_figures.R

render: figures
	quarto render $(QMD) --to revealjs
	mkdir -p docs
	mv -f index.html docs/index.html
	rm -rf index_files
	touch docs/.nojekyll

clean:
	rm -f $(HTML) index.html
	rm -rf .quarto index_files index_cache \
	       DoWEA_Student_Growth_files DoWEA_Student_Growth_cache
