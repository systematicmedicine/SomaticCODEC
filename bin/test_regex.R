#!/usr/bin/env Rscript
#
# --- test_regex.R ---
#
# A utility script for testing regexes, before adding them to a metrics spreadsheet
#
# Example usage:
#
# Rscript bin/test_regex.R "metrics/S004/S004_filter_metrics.txt" "^Pairs that were too short:\\s+\\d+\\s+\\((?P<percent>[\\d.]+)%\\)$"
#

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  cat("Usage: Rscript scripts/test_regex.R <file_path> <regex_pattern>\n")
  quit(status = 1)
}

file_path <- args[[1]]
pattern <- args[[2]]

# Source the pipeline function
source("scripts/global_scripts/metrics/metrics_report_functions.R")

# Run and print result
result <- get_metric_txt(file_path, pattern)

cat("Extracted value:\n")
print(result)
