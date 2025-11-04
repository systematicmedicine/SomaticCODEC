# ===========================================================================
# Metrics report.R
#
# Collate component level and system level metrics into respective reports
#   - To be used exclusively with Snakemake parent rule create_metrics_report
#   - Recieves parameter injection from parent rule
#
# Authors: 
#   - Cameron Fraser
#   - Joshua Johnstone
# ===========================================================================

# ---------------------------------------------------------------------------
# Setup environment
# ---------------------------------------------------------------------------

# Load libraries
library(dplyr)
library(openxlsx)
source("scripts/metrics_report_functions.R")

# Define hard coded variables

if (!exists("snakemake")) {
  # Manual mode (for local testing)
  COMPONENT_METRICS_PATH <- "config/component_level_metrics.xlsx"
  SYSTEM_METRICS_PATH <- "config/system_level_metrics.xlsx"
  EXP_NAME <- "Test experiment"
  COMPONENT_CSV <- "metrics/component_metrics_report.csv"
  COMPONENT_PNG <- "metrics/component_metrics_report.png"
  SYSTEM_CSV <- "results/system_metrics_report.csv"
  SYSTEM_PNG <- "results/system_metrics_report.png"
  LOG_PATH <- "logs/metrics_report.log"
} else {
  # Snakemake-injected paths
  COMPONENT_METRICS_PATH <- snakemake@input[["component_metrics_metadata"]]
  SYSTEM_METRICS_PATH <- snakemake@input[["system_metrics_metadata"]]
  EXP_NAME <- snakemake@params[["run_name"]]
  COMPONENT_CSV <- snakemake@output[["component_csv"]]
  COMPONENT_PNG <- snakemake@output[["component_png"]]
  SYSTEM_CSV <- snakemake@output[["system_csv"]]
  SYSTEM_PNG <- snakemake@output[["system_png"]]
  LOG_PATH <- snakemake@log[[1]]
}

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

  # Load metrics metadata
  meta <- read.xlsx(metrics_path, sheet = "Metrics") %>%
    coerce_types(METRICS_FILE_SCHEMA)

  # Assess metrics
  report_list <- lapply(split(meta, seq_len(nrow(meta))), assess_metric)
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