### Shared palette, ggplot theme, and SVG writer for the DoWEA deck.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

INK        <- "#141410"
GREY       <- "#7c7c7c"
BLUE       <- "#3498DB"
ORANGE     <- "#E67E22"
GREEN      <- "#27AE60"
RED        <- "#C0392B"
GRID       <- "#D8D8D4"
HIGHLIGHT  <- "#1A5276"

BUCKET_COLS <- c(
  "very high" = "#2166AC",
  "high"      = "#67A9CF",
  "typical"   = "#9E9E9E",
  "low"       = "#EF8A62",
  "very low"  = "#B2182B",
  "Nation"    = INK
)

REGION_COLS <- c(
  "Region A" = "#3498DB",
  "Region B" = "#8E44AD",
  "Region C" = "#16A085"
)

theme_deck <- function(base_size = 16) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(
      text             = element_text(colour = INK),
      plot.title       = element_text(face = "bold", size = rel(1.08)),
      plot.subtitle    = element_text(colour = GREY, size = rel(0.9)),
      plot.caption     = element_text(colour = GREY, size = rel(0.75), hjust = 0),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = GRID, linewidth = 0.4),
      plot.background  = element_rect(fill = "transparent", colour = NA),
      panel.background = element_rect(fill = "transparent", colour = NA),
      legend.position  = "top",
      legend.title     = element_blank(),
      axis.title       = element_text(colour = GREY),
      axis.text        = element_text(colour = INK)
    )
}

save_svg <- function(p, path, width, height) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggsave(path, p, width = width, height = height, bg = "transparent")
  message("  wrote ", path)
}

root_dir <- function() {
  here <- getwd()
  if (file.exists(file.path(here, "DoWEA_Student_Growth.qmd"))) return(here)
  this <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(this)) return(dirname(dirname(normalizePath(this))))
  here
}
