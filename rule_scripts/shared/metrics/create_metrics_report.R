#!/usr/bin/env Rscript
#
# --- create_metrics_report.R ---
#
# Collate component level and system level metrics into respective reports
#   - To be used exclusively with Snakemake parent rule create_metrics_report
#   - Recieves parameter injection from parent rule
#
# Authors: 
#   - Cameron Fraser
#   - Joshua Johnstone
#

# ---------------------------------------------------------------------------
# Setup environment
# ---------------------------------------------------------------------------

# Load libraries
library(dplyr)
library(openxlsx)
library(argparse)
source("rule_scripts/shared/metrics/create_metrics_report_functions.R")

# Snakemake-injected paths
parser <- ArgumentParser()
parser$add_argument("--component_metrics_metadata", required = TRUE)
parser$add_argument("--system_metrics_metadata", required = TRUE)
parser$add_argument("--component_csv", required = TRUE)
parser$add_argument("--component_png", required = TRUE)
parser$add_argument("--system_csv", required = TRUE)
parser$add_argument("--system_png", required = TRUE)
parser$add_argument("--ex_lanes", required = TRUE, nargs="+")
parser$add_argument("--ex_samples", required = TRUE, nargs="+")
parser$add_argument("--ms_samples", required = TRUE, nargs="+")
parser$add_argument("--run_name", required = TRUE)
parser$add_argument("--log", required = TRUE)
args <- parser$parse_args()

COMPONENT_METRICS_PATH <- args$component_metrics_metadata
SYSTEM_METRICS_PATH <- args$system_metrics_metadata
COMPONENT_CSV <- args$component_csv
COMPONENT_PNG <- args$component_png
SYSTEM_CSV <- args$system_csv
SYSTEM_PNG <- args$system_png
EX_LANES <- args$ex_lanes
EX_SAMPLES <- args$ex_samples
MS_SAMPLES <- args$ms_samples
EXP_NAME <- args$run_name
LOG_PATH <- args$log


# Define hard coded variables
METRICS_FILE_SCHEMA <- list(
  Name = "character",
  Description = "character",
  Stage = "character",
  Scope = "character",
  nn_lower = "numeric",
  nn_upper = "numeric",
  ideal_lower = "numeric",
  ideal_upper = "numeric",
  include_automated_report = "logical",
  file_pattern = "character",
  value_pattern = "character"
)

# Start logging
log_con <- file(LOG_PATH, open = "wt")
sink(log_con, type = "message")
message(sprintf("[INFO] Script started at %s\n", Sys.time()))

# ---------------------------------------------------------------------------
# Create metrics reports (component & system)
# ---------------------------------------------------------------------------

# Define metadata for both reports
report_types <- c("Component", "System")
metrics_paths <- c(COMPONENT_METRICS_PATH, SYSTEM_METRICS_PATH)
csv_paths     <- c(COMPONENT_CSV, SYSTEM_CSV)
png_paths     <- c(COMPONENT_PNG, SYSTEM_PNG)

for (i in seq_along(report_types)) {
  type <- report_types[i]
  metrics_path <- metrics_paths[i]
  csv_path <- csv_paths[i]
  png_path <- png_paths[i]

  message(sprintf("[INFO] Starting on %s metrics report\n", type))

  # Load metrics metadata
  meta <- read.xlsx(metrics_path, sheet = "Metrics") %>%
    coerce_types(METRICS_FILE_SCHEMA)

  # Filter for included metrics
  meta <- filter(meta, include_automated_report == TRUE)

  # Assess metrics
  report_list <- lapply(
    X = split(meta, seq_len(nrow(meta))),
    FUN = assess_metric,
    ex_lanes = EX_LANES,
    ex_samples = EX_SAMPLES,
    ms_samples = MS_SAMPLES
  )
  report_df <- bind_rows(report_list)

  # Write CSV report
  write.csv(report_df, csv_path, row.names = FALSE, quote = FALSE)

  # Create and save heatmap
  heatmap <- plot_metric_heatmap(report_df, paste0(type, "-level metrics report"), EXP_NAME)
  save_scaled_heatmap(
    plot = heatmap,
    path = png_path,
    nrows = nrow(report_df),
    ncols = ncol(report_df),
    base_height = 0.06
  )
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

# Release logging
message(sprintf("[INFO] Script finished at %s\n", Sys.time()))
sink(type = "message")
close(log_con)