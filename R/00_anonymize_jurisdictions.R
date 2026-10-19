############################################################################
### Anonymize jurisdiction names for the public repository.
### Reads the named transcriptions in data/private/ (gitignored) and writes
### data/naep_sgpc_g4_2015_g8_2019.csv and data/naep_g4_math_2015.csv with
### every jurisdiction except DoDEA (DoWEA) and the nation replaced by a code.
### Codes follow the SGPc rank order and are shared by both files, so the
### status-vs-growth merge in R/02 still works. Run only when the private
### transcriptions change; the committed anonymized files are what R/02 reads.
############################################################################

suppressPackageStartupMessages(library(data.table))

KEEP <- c("DoDEA", "Nation")

sg <- fread("data/private/naep_sgpc_g4_2015_g8_2019_named.csv")
st <- fread("data/private/naep_g4_math_2015_named.csv")

others <- sg[!jurisdiction %in% KEEP][order(rank), jurisdiction]
key <- setNames(sprintf("J%02d", seq_along(others)), others)

unmatched <- setdiff(st[!jurisdiction %in% KEEP, jurisdiction], others)
if (length(unmatched)) stop("Status rows without an SGPc row: ", length(unmatched))

recode <- function(x) fifelse(x %in% KEEP, x, unname(key[x]))
sg[, jurisdiction := recode(jurisdiction)]
st[, jurisdiction := recode(jurisdiction)]

fwrite(sg, "data/naep_sgpc_g4_2015_g8_2019.csv")
fwrite(st[order(jurisdiction)], "data/naep_g4_math_2015.csv")

message("Anonymized ", length(key), " jurisdictions.")
