############################################################################
### Illustrative school / district / region growth from SGPdata demo LONG.
### Relabeled into neutral regions (A/B/C) so no real DoWEA region can be
### read into illustrative numbers. Every figure is marked illustrative.
### No real DoWEA student data are used.
############################################################################

source("R/00_helpers.R")

suppressPackageStartupMessages({
  library(SGPdata)
})

dt <- as.data.table(sgpData_LONG)
dt <- dt[VALID_CASE == "VALID_CASE"]

## Map the three demo districts onto neutral regions, then hash schools
## into two fictional districts within each region.
region_map <- data.table(
  DISTRICT_NUMBER = sort(unique(dt$DISTRICT_NUMBER)),
  REGION = names(REGION_COLS)
)
dt <- merge(dt, region_map, by = "DISTRICT_NUMBER", all.x = TRUE)
dt[, DISTRICT_LABEL := paste0(
  REGION, " · District ",
  as.integer(frank(SCHOOL_NUMBER, ties.method = "dense") %% 2L) + 1L
)]
dt[, SCHOOL_LABEL := paste0("School ", sprintf("%02d",
  frank(SCHOOL_NUMBER, ties.method = "dense")))]

## Consecutive-year pairs → conditional percentile of current score given
## prior-score ventile. A transparent SGP-like quantity for illustration.
setorder(dt, ID, CONTENT_AREA, YEAR, GRADE)
dt[, `:=`(
  prior_score = shift(SCALE_SCORE),
  prior_year  = shift(YEAR),
  prior_grade = shift(GRADE),
  prior_level = shift(ACHIEVEMENT_LEVEL)
), by = .(ID, CONTENT_AREA)]

pairs <- dt[!is.na(prior_score)]
pairs[, prior_bin := as.integer(cut(prior_score, breaks = 20L, labels = FALSE))]
pairs[, SGP := as.numeric(frank(SCALE_SCORE, ties.method = "average") /
                            (.N + 1) * 100),
      by = .(CONTENT_AREA, GRADE, YEAR, prior_bin)]

proficient <- c("Proficient", "Advanced", "Above Proficient")
pairs[, PROF := ACHIEVEMENT_LEVEL %in% proficient]

latest <- pairs[YEAR == max(YEAR)]

school <- latest[, .(
  n            = .N,
  median_sgp   = median(SGP, na.rm = TRUE),
  mean_sgp     = mean(SGP, na.rm = TRUE),
  pct_proficient = 100 * mean(PROF, na.rm = TRUE)
), by = .(REGION, DISTRICT_LABEL, SCHOOL_LABEL, SCHOOL_NUMBER)]
school <- school[n >= 40]

district <- latest[, .(
  n = .N,
  median_sgp = median(SGP, na.rm = TRUE),
  pct_proficient = 100 * mean(PROF, na.rm = TRUE)
), by = .(REGION, DISTRICT_LABEL)]

region <- latest[, .(
  n = .N,
  median_sgp = median(SGP, na.rm = TRUE),
  pct_proficient = 100 * mean(PROF, na.rm = TRUE)
), by = REGION]

## Two schools with similar proficiency, different growth
school[, prof_round := round(pct_proficient)]
cand <- school[, {
  .SD[abs(pct_proficient - median(pct_proficient)) < 4]
}]
if (nrow(cand) < 8) cand <- copy(school)
spread <- cand[order(-median_sgp)]
pair_hi <- spread[1]
pair_lo <- spread[.N]
pair_dt <- rbindlist(list(
  pair_hi[, .(SCHOOL_LABEL, REGION, median_sgp, pct_proficient, role = "Higher growth")],
  pair_lo[, .(SCHOOL_LABEL, REGION, median_sgp, pct_proficient, role = "Lower growth")]
))

saveRDS(list(
  school = school, district = district, region = region,
  pair = pair_dt, latest_year = max(latest$YEAR)
), "summary/illustrative.rds")

## ── Two schools, same status, different growth ──────────────────
pair_dt[, school := fifelse(role == "Higher growth", "School B", "School A")]
pair_long <- melt(pair_dt,
                  id.vars = c("school", "REGION", "role"),
                  measure.vars = c("pct_proficient", "median_sgp"),
                  variable.name = "metric", value.name = "value")
pair_long[, metric := factor(fifelse(metric == "median_sgp",
                                     "Median growth percentile",
                                     "Percent proficient"),
                             levels = c("Percent proficient", "Median growth percentile"))]
p_pair <- ggplot(pair_long, aes(x = school, y = value, fill = role)) +
  geom_col(width = 0.62) +
  geom_text(aes(label = round(value)), vjust = -0.4, size = 7, fontface = "bold") +
  facet_wrap(~ metric) +
  scale_fill_manual(values = c("Higher growth" = GREEN, "Lower growth" = ORANGE)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25)) +
  labs(x = NULL, y = NULL,
       subtitle = "Proficiency rates look alike. Growth tells the two schools apart.",
       caption = "Illustrative data from the public SGPdata demo file, relabeled. Not DoWEA results.") +
  theme_deck(17) +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold", size = rel(1)),
        panel.grid.major.x = element_blank(),
        panel.spacing = unit(3, "lines"))

save_svg(p_pair, "Figures/process/two_schools.svg", 12, 6)

## ── School bubble: status × growth, color = region ──────────────
p_bubble <- ggplot(school, aes(x = pct_proficient, y = median_sgp,
                               colour = REGION, size = n)) +
  geom_hline(yintercept = 50, colour = GREY, linetype = "22") +
  geom_vline(xintercept = median(school$pct_proficient),
             colour = GREY, linetype = "22") +
  geom_point(alpha = 0.82) +
  scale_colour_manual(values = REGION_COLS) +
  scale_size_area(max_size = 14, guide = "none") +
  guides(colour = guide_legend(override.aes = list(size = 6))) +
  labs(x = "Percent proficient", y = "Median growth percentile",
       subtitle = "Each bubble is a school. Color is region; size is the number of students.",
       caption = "Illustrative data. Dashed lines mark median proficiency and typical growth (50).") +
  theme_deck(16) +
  theme(legend.text = element_text(size = rel(1)))

save_svg(p_bubble, "Figures/process/school_bubbles.svg", 12, 6)

## ── Region → district drill-down (one figure) ───────────────────
region_lab <- region[, .(REGION, strip = sprintf("%s\nmedian %d", REGION, round(median_sgp)))]
district <- merge(district, region_lab, by = "REGION")
district[, strip := factor(strip, levels = region_lab[order(-region$median_sgp)]$strip)]
district[, short := sub(".* · ", "", DISTRICT_LABEL)]

p_drill <- ggplot(district, aes(x = median_sgp, y = reorder(short, median_sgp), fill = REGION)) +
  geom_col(width = 0.68) +
  geom_vline(xintercept = 50, colour = INK, linetype = "22") +
  geom_text(aes(label = round(median_sgp)), hjust = -0.25, size = 6, fontface = "bold") +
  facet_grid(strip ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_fill_manual(values = REGION_COLS, guide = "none") +
  scale_x_continuous(limits = c(0, 70), breaks = seq(0, 70, 10),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Median growth percentile", y = NULL,
       subtitle = "Start with the region, then its districts. Dashed line: typical growth (50).",
       caption = "Illustrative data. Not DoWEA results.") +
  theme_deck(17) +
  theme(strip.placement = "outside",
        strip.text.y.left = element_text(angle = 0, hjust = 1, face = "bold"),
        panel.grid.major.y = element_blank(),
        panel.spacing = unit(1, "lines"))

save_svg(p_drill, "Figures/process/region_district.svg", 12, 6)

## ── Growth by prior achievement ─────────────────────────────────
latest[, prior_band := fcase(
  prior_level %in% c("Unsatisfactory", "Below Basic", "Level 1"), "Below proficient",
  prior_level %in% c("Partially Proficient", "Basic", "Level 2"), "Approaching",
  prior_level %in% proficient, "Already proficient",
  default = as.character(prior_level)
)]
## Collapse to three bands using current-year prior score terciles if labels
## are messy.
latest[, prior_band := cut(prior_score, breaks = quantile(prior_score, c(0, 1/3, 2/3, 1),
                                                          na.rm = TRUE),
                           include.lowest = TRUE,
                           labels = c("Started lower", "Started in the middle", "Started higher"))]
by_prior <- latest[!is.na(prior_band), .(
  median_sgp = median(SGP),
  n = .N
), by = .(REGION, prior_band)]

p_prior <- ggplot(by_prior, aes(x = prior_band, y = median_sgp, fill = REGION)) +
  geom_hline(yintercept = 50, colour = INK, linetype = "22") +
  geom_col(position = position_dodge(0.76), width = 0.72) +
  geom_text(aes(label = round(median_sgp)), position = position_dodge(0.76),
            vjust = -0.4, size = 5.4, fontface = "bold") +
  scale_fill_manual(values = REGION_COLS) +
  scale_y_continuous(limits = c(0, 66), breaks = seq(0, 60, 20)) +
  labs(x = NULL, y = "Median growth percentile",
       caption = "Illustrative data. Students grouped by prior achievement. Dashed line: typical growth (50).") +
  theme_deck(17) +
  theme(panel.grid.major.x = element_blank(),
        legend.position = "right",
        legend.text = element_text(size = rel(1)),
        axis.text.x = element_text(size = rel(1.1), face = "bold"))

save_svg(p_prior, "Figures/process/growth_by_prior.svg", 12, 4.6)

## ── Median SGP over time as a light control chart ───────────────
trend <- pairs[, .(median_sgp = median(SGP), n = .N), by = .(YEAR, REGION)]
trend[, year_lab := gsub("_", "–", YEAR)]
p_ctrl <- ggplot(trend, aes(x = year_lab, y = median_sgp,
                            colour = REGION, group = REGION)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 45, ymax = 55,
           fill = "#3498DB", alpha = 0.12) +
  annotate("text", x = -Inf, y = 54.5, label = "  Typical range", hjust = 0,
           vjust = 1, colour = "#2E86C1", size = 5.2, fontface = "bold") +
  geom_hline(yintercept = 50, colour = GREY, linetype = "22") +
  geom_line(linewidth = 1.4) +
  geom_point(size = 3.6) +
  scale_colour_manual(values = REGION_COLS) +
  scale_y_continuous(limits = c(35, 62)) +
  guides(colour = guide_legend(override.aes = list(linewidth = 2))) +
  labs(x = NULL, y = "Median growth percentile",
       subtitle = "One year is weather; a run of years is climate. Persistent departure from 50 is a signal.",
       caption = "Illustrative data. Shaded band is a conventional 45–55 'typical' window, not a statistical limit.") +
  theme_deck(16) +
  theme(legend.text = element_text(size = rel(1)))

save_svg(p_ctrl, "Figures/process/control_chart.svg", 12, 6)

message("Illustrative process figures done.")
