############################################################################
### Conceptual figures: height chart, high jumpers, percentile growth
### trajectories, growth-status quadrants, QR code.
############################################################################

source("R/00_helpers.R")

ord <- function(p) paste0(p, "th")

## ── Pediatric-style height chart: norm vs criterion ─────────────
ages <- seq(6, 14, by = 0.25)
bands <- data.table(
  age = rep(ages, 5),
  pct = rep(c(10, 25, 50, 75, 90), each = length(ages))
)
## Rough CDC-like boys' stature (cm), stylized
bands[, height := 65 + 6.2 * age + qnorm(pct / 100) * (4.2 + 0.15 * age)]
child <- data.table(age = c(7, 9, 11, 13), height = c(122, 133, 142, 154))
ride  <- 140

p_height <- ggplot(bands, aes(x = age, y = height, group = pct, colour = factor(pct))) +
  geom_line(linewidth = 1) +
  geom_text(data = bands[age == max(age)], aes(label = ord(pct)),
            hjust = -0.2, size = 5, colour = "#2E6E9E") +
  geom_hline(yintercept = ride, colour = RED, linetype = "22", linewidth = 0.9) +
  annotate("text", x = 6.1, y = ride + 2.4, label = "Tall enough to ride: a criterion",
           hjust = 0, colour = RED, size = 5.4, fontface = "bold") +
  annotate("text", x = 14.75, y = max(bands$height) + 6, label = "Percentiles:\na norm",
           hjust = 0.5, colour = "#2E86C1", size = 5.4, fontface = "bold", lineheight = 0.95) +
  geom_line(data = child, aes(x = age, y = height), inherit.aes = FALSE,
            colour = INK, linewidth = 1.3) +
  geom_point(data = child, aes(x = age, y = height), inherit.aes = FALSE,
             colour = INK, size = 3.8) +
  annotate("text", x = 6.88, y = 122, label = "One child", hjust = 1,
           colour = INK, size = 5.4, fontface = "bold") +
  scale_colour_manual(values = c("10" = "#9ECAE9", "25" = "#5DADE2",
                                 "50" = "#1F618D", "75" = "#5DADE2",
                                 "90" = "#9ECAE9"), guide = "none") +
  scale_x_continuous(breaks = seq(6, 14, 2), expand = expansion(mult = c(0.02, 0.1))) +
  labs(x = "Age (years)", y = "Height (cm)",
       subtitle = "Curves place the child among peers (norm). The red line asks: does the child meet a standard (criterion)?",
       caption = "Stylized figure for illustration. Not a clinical growth chart.") +
  theme_deck(16)

save_svg(p_height, "Figures/concept/height_chart.svg", 12, 6.4)

## ── High jumpers: an inch is not always an inch ─────────────────
jump <- data.table(
  jumper = factor(c("Judy", "Judy", "Anna", "Anna"),
                  levels = c("Judy", "Anna")),
  meet   = factor(c("Last year", "This year", "Last year", "This year"),
                  levels = c("Last year", "This year")),
  inches = c(76, 78, 42, 48)
)
p_jump <- ggplot(jump, aes(x = meet, y = inches, group = jumper, colour = jumper)) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 6) +
  geom_text(data = jump[meet == "This year"],
            aes(label = fifelse(jumper == "Judy", "+2 in", "+6 in")),
            hjust = -0.45, size = 6.5, fontface = "bold", show.legend = FALSE) +
  geom_text(data = jump[meet == "Last year"],
            aes(label = fifelse(jumper == "Judy", "Judy, elite", "Anna, novice")),
            hjust = 1.18, size = 6, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = c(Judy = BLUE, Anna = ORANGE), guide = "none") +
  scale_x_discrete(expand = expansion(add = c(1.1, 0.6))) +
  scale_y_continuous(limits = c(35, 85), name = "High jump (inches)") +
  labs(x = NULL,
       title = "Whose jump changed more? Whose change is more remarkable?",
       subtitle = "Judy, an elite jumper, added two inches. Anna, a novice, added six.",
       caption = "Story problem used in the 2016 Hawaii growth-model overview.") +
  theme_deck(16)

save_svg(p_jump, "Figures/concept/high_jump.svg", 12, 6.4)

## ── Percentile growth trajectories ──────────────────────────────
## One student starts below the cut in Grade 3. Each line is the path of a
## student who grows at that percentile every year (stylized: constant gain).
years   <- 3:8
start   <- 380
fan_pct <- c(10, 25, 50, 60, 75, 90)
fan <- CJ(pct = fan_pct, grade = years)
fan[, score := start + (grade - 3) * (26 + qnorm(pct / 100) * 12)]
fan[, key := pct == 60]
cut_line <- data.table(grade = years, cut = 430 + 18 * (years - 3))

p_fan <- ggplot(fan, aes(x = grade, y = score, group = pct)) +
  geom_line(data = cut_line, aes(x = grade, y = cut), inherit.aes = FALSE,
            colour = RED, linewidth = 1.2, linetype = "22") +
  annotate("text", x = 3, y = 437, label = "Proficient", hjust = 0,
           vjust = 0, colour = RED, size = 5.6, fontface = "bold") +
  geom_line(aes(colour = key, linewidth = key)) +
  geom_text(data = fan[grade == 8], aes(label = ord(pct)),
            colour = fifelse(fan[grade == 8]$key, HIGHLIGHT, "#4A7FAF"),
            hjust = -0.25, size = 5.2, fontface = "bold") +
  annotate("point", x = 3, y = start, colour = INK, size = 4.5) +
  annotate("text", x = 3.08, y = start - 9, label = "Starts below Proficient",
           hjust = 0, vjust = 1, colour = INK, size = 5.2) +
  scale_colour_manual(values = c(`TRUE` = HIGHLIGHT, `FALSE` = "#8FB9D9"), guide = "none") +
  scale_linewidth_manual(values = c(`TRUE` = 2, `FALSE` = 0.9), guide = "none") +
  scale_x_continuous(breaks = years, labels = paste("Grade", years),
                     expand = expansion(mult = c(0.03, 0.09))) +
  labs(x = NULL, y = "Scale score",
       subtitle = "Typical growth (50th percentile) never catches up.\nGrowth near the 60th percentile every year reaches Proficient by Grade 8.",
       caption = "Stylized. Each line is the path of a student who grows at that percentile every year.") +
  theme_deck(16) +
  theme(plot.subtitle = element_text(colour = INK))

save_svg(p_fan, "Figures/concept/growth_fan.svg", 12, 6.4)

## ── Four-quadrant conceptual chart ──────────────────────────────
set.seed(26)
n <- 48
quad <- data.table(
  status = rnorm(n, 50, 14),
  growth = rnorm(n, 50, 11)
)
quad[, q := fcase(
  status >= 50 & growth >= 50, "hh",
  status <  50 & growth >= 50, "lh",
  status >= 50 & growth <  50, "hl",
  default = "ll"
)]
corner <- data.table(
  x = c(-Inf, Inf, -Inf, Inf), y = c(Inf, Inf, -Inf, -Inf),
  hj = c(-0.08, 1.08, -0.08, 1.08), vj = c(1.5, 1.5, -0.8, -0.8),
  q = c("lh", "hh", "ll", "hl"),
  lab = c("Catching up", "Keep doing it", "Urgent", "The quiet risk")
)
Q_COLS <- c(hh = GREEN, lh = BLUE, hl = ORANGE, ll = RED)

p_q <- ggplot(quad, aes(x = status, y = growth, colour = q)) +
  geom_hline(yintercept = 50, colour = GREY) +
  geom_vline(xintercept = 50, colour = GREY) +
  geom_point(size = 4, alpha = 0.85) +
  geom_text(data = corner, aes(x = x, y = y, label = lab, hjust = hj, vjust = vj),
            size = 7, fontface = "bold") +
  scale_colour_manual(values = Q_COLS, guide = "none") +
  scale_x_continuous(breaks = NULL, name = "Status (achievement) →") +
  scale_y_continuous(breaks = NULL, name = "Growth →") +
  labs(subtitle = "Each point is a school. For a high-achieving system the lower-right is the quadrant to watch.",
       caption = "Conceptual scatter. Not DoWEA data.") +
  theme_deck(17)

save_svg(p_q, "Figures/concept/quadrant.svg", 12, 6.4)

## ── QR code for the public deck ─────────────────────────────────
if (requireNamespace("qrcode", quietly = TRUE)) {
  url <- "https://dbetebenner.github.io/DoWEA_Presentation_102626/"
  png("assets/img/qr_code.png", width = 800, height = 800, bg = "transparent")
  par(bg = NA, mar = c(0, 0, 0, 0))
  plot(qrcode::qr_code(url), bg = "transparent")
  invisible(dev.off())
  message("  wrote assets/img/qr_code.png")
} else {
  message("  qrcode package not available; skip QR")
}

message("Concept figures done.")
