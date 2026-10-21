############################################################################
### Copula growth (SGPc) figures.
### NAEP: DoWEA highlighted, transcribed from the IES deck appendix.
### TIMSS: the United States highlighted, from the SGPc TIMSS app extract
### (R/00_extract_timss.R). SGPc-foundry is never read. Every other
### jurisdiction is coded in the committed CSVs and never labeled.
############################################################################

source("R/00_helpers.R")

## NAEP reports DoWEA under its former name; relabel for display only.
NAEP_NAME <- "DoDEA"
SHOW_NAME <- "DoWEA"
NAME_NOTE <- "DoWEA is reported by NAEP as DoDEA."

sg <- fread("data/naep_sgpc_g4_2015_g8_2019.csv")
st <- fread("data/naep_g4_math_2015.csv")

sg[, highlight := fcase(
  jurisdiction == NAEP_NAME, "DoWEA",
  jurisdiction == "Nation", "Nation",
  default = "Other"
)]

## One row per jurisdiction, only the focus row labeled. `dt` needs
## jurisdiction, mean_sgpc, ci95_lo, ci95_hi and a logical `focus` column.
sgpc_dots <- function(dt, focus_lab, ref_lab, limits, breaks, subtitle, caption) {
  dt <- copy(dt)
  dt[, highlight := fifelse(focus, "Focus", "Other")]
  f <- dt[focus == TRUE]
  ggplot(dt, aes(x = mean_sgpc, y = reorder(jurisdiction, mean_sgpc))) +
    geom_vline(xintercept = 50, colour = INK, linewidth = 0.7, linetype = "22") +
    annotate("text", x = 50, y = -Inf, label = ref_lab, vjust = -0.6,
             hjust = -0.08, colour = INK, size = 5.2) +
    geom_errorbar(aes(xmin = ci95_lo, xmax = ci95_hi, colour = highlight),
                  orientation = "y", width = 0, linewidth = 0.8, alpha = 0.8) +
    geom_point(aes(colour = highlight, size = highlight)) +
    annotate("text", x = f$ci95_hi, y = f$jurisdiction, label = focus_lab,
             hjust = -0.06, colour = HIGHLIGHT, fontface = "bold", size = 6) +
    scale_colour_manual(values = c(Focus = BLUE, Other = "#B6B6B0"), guide = "none") +
    scale_size_manual(values = c(Focus = 4.6, Other = 2), guide = "none") +
    scale_x_continuous(limits = limits, breaks = breaks,
                       name = "Mean SGPc, Grade 4 (2015) → Grade 8 (2019) mathematics") +
    labs(y = NULL, subtitle = subtitle, caption = caption) +
    theme_deck(16) +
    theme(
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid.major.y = element_blank()
    )
}

plot_dt <- sg[jurisdiction != "Nation"]
plot_dt[, focus := highlight == "DoWEA"]
plot_dt[, rank := frank(-mean_sgpc, ties.method = "min")]
dowea <- plot_dt[focus == TRUE]

p_dots <- sgpc_dots(
  plot_dt,
  focus_lab = sprintf("%s  %.1f · rank %d of %d", SHOW_NAME, dowea$mean_sgpc,
                      dowea$rank, nrow(plot_dt)),
  ref_lab = "Nation = 50",
  limits = c(36, 72), breaks = seq(40, 60, 5),
  subtitle = "One row per jurisdiction, others unlabeled. Dot: estimate. Bar: 95% sampling interval.",
  caption = paste("Source: Betebenner & Braun, Growth from Snapshots (IES / NCES briefing, 2026).",
                  "Pseudo-cohort; no student records.", NAME_NOTE)
)

save_svg(p_dots, "Figures/sgpc/dodea_highlighted_dots.svg", 12, 6.6)

## TIMSS: the United States among other education systems (others coded)
tm <- fread("data/timss_sgpc_g4_2015_g8_2019.csv")
tm[, focus := jurisdiction == "United States"]
us <- tm[focus == TRUE]

p_timss <- sgpc_dots(
  tm,
  focus_lab = sprintf("United States  %.1f · %s", us$mean_sgpc, us$bucket),
  ref_lab = "International peers = 50",
  limits = c(28, 72), breaks = seq(30, 70, 10),
  subtitle = "One row per education system, others unlabeled. Dot: estimate. Bar: 95% sampling interval.",
  caption = paste("Source: SGPc analysis of TIMSS 2015 Grade 4 and 2019 Grade 8 mathematics (IEA).",
                  "Pseudo-cohort; no student records. Benchmarking participants excluded.")
)

save_svg(p_timss, "Figures/sgpc/timss_us_highlighted_dots.svg", 12, 5.2)

## Status vs growth quadrant
quad <- merge(sg, st, by = "jurisdiction", all.x = TRUE)
quad <- quad[!is.na(g4_math_2015)]
quad[, lab := fcase(highlight == "DoWEA", SHOW_NAME,
                    highlight == "Nation", "Nation",
                    default = "")]

corner <- data.table(
  x = c(-Inf, Inf, -Inf, Inf), y = c(Inf, Inf, -Inf, -Inf),
  hj = c(-0.06, 1.06, -0.06, 1.06), vj = c(1.6, 1.6, -0.9, -0.9),
  lab = c("Lower status · higher growth", "Higher status · higher growth",
          "Lower status · lower growth", "Higher status · lower growth")
)

p_quad <- ggplot(quad, aes(x = g4_math_2015, y = mean_sgpc)) +
  geom_hline(yintercept = 50, colour = GREY, linetype = "22") +
  geom_vline(xintercept = 240, colour = GREY, linetype = "22") +
  geom_text(data = corner, aes(x = x, y = y, label = lab, hjust = hj, vjust = vj),
            colour = "#8A8A84", size = 5, fontface = "bold") +
  geom_point(aes(colour = highlight, size = highlight), alpha = 0.92) +
  geom_text(aes(label = lab, colour = highlight),
            vjust = -1.1, size = 5.6, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(DoWEA = BLUE, Nation = INK, Other = "#A8A8A2"),
                      guide = "none") +
  scale_size_manual(values = c(DoWEA = 6, Nation = 4, Other = 2.8),
                    guide = "none") +
  labs(x = "Status: 2015 Grade 4 NAEP mathematics",
       y = "Growth: mean SGPc to Grade 8 (2019)",
       subtitle = "Grey points are other jurisdictions, unlabeled. Dashed lines: national status (240) and growth (50).",
       caption = paste("Status: NCES 2015 state snapshot. Growth: Betebenner & Braun (2026).",
                       "Different students at each grade.", NAME_NOTE)) +
  theme_deck(16)

save_svg(p_quad, "Figures/sgpc/status_vs_growth.svg", 12, 6.6)

message("SGPc figures done.")
