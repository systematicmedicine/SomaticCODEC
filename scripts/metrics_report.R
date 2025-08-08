# ===========================================================================
# Metrics report.R
#
# Collate component level and system level metrics into a report
#   - Component level metrics are defined in config/component_metrics.xlsx
#
# Author: Cameron Fraser
# ===========================================================================

# Load libraries
library(dplyr)
library(openxlsx)
source("scripts/metrics_report_functions.R")

# Define data paths (replace with Snakemake injection)

COMPONENT_METRICS_PATH <- "config//component_level_metrics.xlsx"
SYSTEM_METRICS_PATH <- "config//system_level_metrics.xlsx"
CSV_OUTPUT_PATH <- "metrics//metrics_report.csv"
HEATMAP_PATH <- "metrics//metrics_heatmap.png"

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
report.heatmap <- plot_metric_heatmap(report.df)
ggsave(HEATMAP_PATH, plot = report.heatmap, width = 12, height = 10, dpi = 300)
