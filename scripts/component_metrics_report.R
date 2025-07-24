
# --- metrics_report.R ---
# 
# Calls on get_metrics.R functions and generates a pass/fail report for all metrics.
# 
# Authors: 
#     - Joshua Johnstone
#     - Cameron Fraser

# Redirect stdout and stderr to Snakemake log
log_con <- file(snakemake@log[[1]], open = "wt")
sink(log_con)
sink(log_con, type = "message")

# Load packages
library(dplyr)

# Load component metrics
component_metrics <- read.csv("config/component_metrics.csv") %>% 
  select(1:3, 5:9)

# Get sample types from config
ex_samples <- read.csv("config/ex_samples.csv") %>% 
  pull(ex_sample)

ex_lanes <- read.csv("config/ex_lanes.csv") %>% 
  pull(ex_lane)

ms_samples <- read.csv("config/ms_samples.csv") %>% 
  pull(ms_sample)

# Get list of sample directories within metrics directory
sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)

# Load get_metrics.R functions
source("scripts/get_metrics.R")

# Make list of functions to run
get_metric_functions <- Filter(function(x) is.function(get(x)) && startsWith(x, "get"), ls())

# Run get_metrics.R functions and store results in list
metric_dataframes <- lapply(get_metric_functions, function(function_name) {
  function_to_run <- get(function_name)
  tryCatch(
    {
      function_to_run()
    },
    error = function(e) {
      message(paste0("Error: ", function_name, " failed: ", e$message))
      # Determine metric name from function name
      function_metric <- sub("^get_", "", function_name)
      # Return data frame with NA for all samples found
      sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
      sample_names <- basename(sample_dirs)
      if (length(sample_names) == 0) sample_names <- NA_character_
      data.frame(
        metric = function_metric,
        sample = sample_names,
        value = NA_real_)
    }
  )
})

# Combine metrics values into one data frame  
combined_metrics_values <- do.call(rbind, metric_dataframes) %>% 
  # Add sample_type column
  mutate(sample_type = case_when(
    sample %in% ex_samples ~ "Experimental",
    sample %in% ex_lanes ~ "Experimental_lane",
    sample %in% ms_samples ~ "Matched")) %>% 
  # Add ms or ex to metric names based on sample type
  mutate(metric = case_when(
    sample_type == "Experimental" ~ paste0("ex_", metric),
    sample_type == "Experimental_lane" ~ paste0("ex_lane_", metric),
    sample_type == "Matched" ~ paste0("ms_", metric)))

# Create metrics report data frame
component_metrics_report <- combined_metrics_values %>% 
  # Join with component metrics, keeping only relevant metrics
  inner_join(component_metrics, by = c("metric", "sample_type")) %>% 
  mutate(nn = ifelse(value >= nn_lower & value <= nn_upper, "PASS", "FAIL"),
         ideal = ifelse(value >= ideal_lower & value <= ideal_upper, "PASS", "FAIL")) %>% 
  arrange(metric, sample) %>% 
  select(1:2, 4:6, 3, 7:12)

# Export metrics report as csv
write.csv(component_metrics_report, "metrics/component_metrics_report.csv", row.names = FALSE)

# Remove tmp directory
unlink(file.path("metrics/tmp"), recursive = TRUE)

# Clean up logging
sink(type = "message")
sink()
close(log_con)