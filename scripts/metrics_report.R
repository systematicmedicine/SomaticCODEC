# ===========================================================================
# Metrics report.R
#
# Collate component level and system level metrics into a report
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
  VERSION_METADATA_PATH <- "logs/global_rules/git_metadata.json"
  CSV_OUTPUT_PATH <- "metrics/metrics_report.csv"
  HEATMAP_PATH <- "metrics/metrics_heatmap.png"
  LOG_PATH <- "logs/metrics_report.log"
} else {
  # Snakemake-injected paths
  COMPONENT_METRICS_PATH <- snakemake@input[["component_metrics_metadata"]]
  SYSTEM_METRICS_PATH <- snakemake@input[["system_metrics_metadata"]]
  EXP_NAME <- snakemake@params[["run_name"]]
  VERSION_METADATA_PATH <- snakemake@input[["version_metadata"]]
  CSV_OUTPUT_PATH <- snakemake@output[["csv_path"]]
  HEATMAP_PATH <- snakemake@output[["heatmap_path"]]
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
# Create metrics report
# ---------------------------------------------------------------------------

# Load metrics metadata
component.meta <- read.xlsx(COMPONENT_METRICS_PATH, sheet = "Metrics") %>%
    coerce_types(METRICS_FILE_SCHEMA)

system.meta <- read.xlsx(SYSTEM_METRICS_PATH, sheet = "Metrics") %>%
    coerce_types(METRICS_FILE_SCHEMA)

combined.meta <- bind_rows(component.meta, system.meta) %>%
    filter(include_automated_report == TRUE)

# Assess each metric
report.list <- lapply(split(combined.meta, seq_len(nrow(combined.meta))), assess_metric)
report.df <- bind_rows(report.list)

# Create CSV report
write.csv(report.df, CSV_OUTPUT_PATH, row.names = FALSE, quote = FALSE)

# Create heatmap report
report.heatmap <- plot_metric_heatmap(report.df, EXP_NAME, get_pipeline_version(VERSION_METADATA_PATH))
save_scaled_heatmap(
  plot = report.heatmap, 
  path = HEATMAP_PATH, 
  nrows = nrow(report.df), 
  ncols = ncol(report.df),
  base_height = 0.06
  )

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

# Release logging
message(sprintf("[INFO] Script finished at %s\n", Sys.time()))
sink(type = "message")
close(log_con)