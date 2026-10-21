############################################################################
### TIMSS mathematics cohort growth (SGPc), Grade 4 (2015) → Grade 8 (2019).
### Reads the committed jurisdiction-level app extract from the SGPc TIMSS
### reporting app (aggregates only; no student records) and writes
###   data/private/timss_sgpc_g4_2015_g8_2019_named.csv   (gitignored)
###   data/timss_sgpc_g4_2015_g8_2019.csv                 (committed)
### Every education system except the United States is replaced by a code
### (C01–C32, in order of estimate). Run by hand only when the extract
### changes; R/02 reads the committed anonymized file.
###
### Selection matches the TIMSS app defaults: pair 2015-2019, arm "cohort",
### systems in the comparison pool (benchmarking participants and
### excluded systems dropped). Estimates are rescaled from 0–1 to 0–100.
############################################################################

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

EXTRACT <- Sys.getenv(
  "TIMSS_EXTRACT",
  "~/GitHub/dataimago/SGPc/SGPc-ai-apps/apps/timss/data/timss-xsec-app-extract.v0.json"
)
EXTRACT <- path.expand(EXTRACT)
KEEP_ID <- "USA"
KEEP_NAME <- "United States"

expected <- strsplit(readLines(paste0(EXTRACT, ".sha256"), n = 1), "\\s+")[[1]][1]
actual <- strsplit(system2("shasum", c("-a", "256", shQuote(EXTRACT)), stdout = TRUE), "\\s+")[[1]][1]
if (!identical(expected, actual)) stop("Extract checksum mismatch: ", actual)

x <- fromJSON(EXTRACT)
rows <- as.data.table(x$rows)
sel <- rows[pair == "2015-2019" & arm == "cohort" & pool_status == "in_pool"]
if (!KEEP_ID %in% sel$jurisdiction_id) stop("United States row missing from selection")

out <- sel[, .(
  jurisdiction_id,
  jurisdiction = jurisdiction_name,
  mean_sgpc = round(100 * estimate, 1),
  se        = round(100 * se, 2),
  ci95_lo   = round(100 * inner_low, 1),
  ci95_hi   = round(100 * inner_high, 1),
  outer_lo  = round(100 * envelope_low, 1),
  outer_hi  = round(100 * envelope_high, 1),
  bucket
)][order(-mean_sgpc)]
out[, rank := seq_len(.N)]
out[, source := sprintf("SGPc TIMSS app extract v0 (sha256 %s; policies %s)",
                        substr(actual, 1, 12), substr(x$provenance$policies_commit, 1, 12))]
setcolorder(out, c("rank", "jurisdiction_id", "jurisdiction"))

dir.create("data/private", showWarnings = FALSE)
fwrite(out, "data/private/timss_sgpc_g4_2015_g8_2019_named.csv")

others <- out[jurisdiction_id != KEEP_ID, jurisdiction_id]
key <- setNames(sprintf("C%02d", seq_along(others)), others)
anon <- copy(out)
anon[, jurisdiction := fifelse(jurisdiction_id == KEEP_ID, KEEP_NAME, unname(key[jurisdiction_id]))]
anon[, jurisdiction_id := NULL]
fwrite(anon, "data/timss_sgpc_g4_2015_g8_2019.csv")

message("TIMSS: ", nrow(out), " systems; ", length(key), " anonymized.")
