############################################################################
### NAEP achievement figures for the DoWEA leadership deck.
### Reads committed CSVs only. No student-level data.
############################################################################

source("R/00_helpers.R")

naep <- fread("data/naep_dowea.csv")

## ── Dumbbell: 2024 DoDEA vs national public ─────────────────────
cmp <- naep[year == 2024]
cmp[, pair := paste0(subject, " · Grade ", grade)]
cmp[, pair := factor(pair, levels = c(
  "Mathematics · Grade 4", "Mathematics · Grade 8",
  "Reading · Grade 4", "Reading · Grade 8"
))]
wide <- dcast(cmp, pair + subject + grade ~ jurisdiction,
              value.var = "scale_score")
setnames(wide, c("DoDEA", "National public"), c("dodea", "nation"),
         skip_absent = TRUE)

p_dumbbell <- ggplot(wide, aes(y = reorder(pair, dodea))) +
  geom_segment(aes(x = nation, xend = dodea, yend = pair),
               colour = GRID, linewidth = 2.2) +
  geom_point(aes(x = nation), colour = GREY, size = 5.2) +
  geom_point(aes(x = dodea), colour = BLUE, size = 5.8) +
  geom_text(aes(x = nation, label = nation), vjust = 2.1,
            colour = GREY, size = 4.2) +
  geom_text(aes(x = dodea, label = dodea), vjust = -1.3,
            colour = BLUE, size = 4.4, fontface = "bold") +
  geom_text(aes(x = (nation + dodea) / 2, label = paste0("+", dodea - nation)),
            vjust = -0.9, colour = INK, size = 4.6, fontface = "bold") +
  scale_x_continuous(limits = c(200, 310), breaks = seq(200, 310, 20),
                     name = "Average NAEP scale score (0–500)") +
  labs(y = NULL,
       title = "DoWEA led the nation on NAEP in 2024",
       subtitle = "Blue: DoWEA. Grey: national public. All four grade × subject combinations.",
       caption = "Source: NCES, The Nation's Report Card, 2024 Reading and Mathematics. DoWEA is reported by NAEP as DoDEA.") +
  theme_deck(17) +
  theme(panel.grid.major.y = element_blank())

save_svg(p_dumbbell, "Figures/naep/dowea_vs_nation_2024.svg", 12.5, 6.2)

## ── Percent proficient 2024 ─────────────────────────────────────
prof <- cmp[!is.na(pct_proficient)]
prof[, group := fifelse(jurisdiction == "DoDEA", "DoWEA", "National public")]
p_prof <- ggplot(prof, aes(x = pair, y = pct_proficient, fill = group)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.68) +
  geom_text(aes(label = paste0(pct_proficient, "%")),
            position = position_dodge(width = 0.72), vjust = -0.45,
            size = 6, fontface = "bold", colour = INK) +
  scale_fill_manual(values = c(DoWEA = BLUE, `National public` = GREY)) +
  scale_y_continuous(limits = c(0, 62), breaks = seq(0, 60, 20),
                     labels = function(x) paste0(x, "%"),
                     name = "At or above NAEP Proficient") +
  labs(x = NULL,
       subtitle = "Percent of students at or above NAEP Proficient, 2024.",
       caption = "Source: NCES 2024 NAEP, as reported. DoWEA is reported by NAEP as DoDEA.") +
  theme_deck(17) +
  theme(panel.grid.major.x = element_blank())

save_svg(p_prof, "Figures/naep/dowea_proficient_2024.svg", 12, 6.4)

## ── 2017–2024: DoWEA vs national public ─────────────────────────
## National public is DoWEA's score minus the reported difference.
tr <- naep[jurisdiction == "DoDEA" & year >= 2017 & !is.na(diff_from_np)]
tr <- rbindlist(list(
  tr[, .(subject, grade, year, group = "DoWEA", score = scale_score)],
  tr[, .(subject, grade, year, group = "National public", score = scale_score - diff_from_np)]
))
tr[, pair := factor(paste0(subject, " · Grade ", grade), levels = c(
  "Mathematics · Grade 4", "Mathematics · Grade 8",
  "Reading · Grade 4", "Reading · Grade 8"
))]
## Same 40-point span in every panel, so slopes compare honestly.
span <- tr[, .(mid = (max(score) + min(score)) / 2), by = pair]
span <- span[, .(year = 2017, score = c(mid - 20, mid + 20)), by = pair]

p_trend <- ggplot(tr, aes(x = year, y = score, colour = group, group = group)) +
  geom_blank(data = span, aes(x = year, y = score), inherit.aes = FALSE) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 3.6) +
  geom_text(data = tr[year %in% c(2017, 2024)],
            aes(label = score, hjust = fifelse(year == 2017, 1.35, -0.35)),
            size = 4.8, fontface = "bold", show.legend = FALSE) +
  facet_wrap(~ pair, nrow = 1, scales = "free_y") +
  scale_colour_manual(values = c(DoWEA = BLUE, `National public` = GREY)) +
  scale_x_continuous(breaks = c(2017, 2019, 2022, 2024),
                     labels = c("'17", "'19", "'22", "'24"),
                     expand = expansion(mult = 0.28)) +
  scale_y_continuous(breaks = NULL) +
  labs(x = NULL, y = NULL,
       caption = "Source: NCES NAEP 2024 release, historical tables (DoWEA reported as DoDEA). National public = DoWEA score minus the reported difference.") +
  theme_deck(17) +
  theme(strip.text = element_text(face = "bold", size = rel(0.85)),
        panel.spacing = unit(1.4, "lines"))

save_svg(p_trend, "Figures/naep/dowea_trend.svg", 12, 5)

message("NAEP achievement figures done.")
