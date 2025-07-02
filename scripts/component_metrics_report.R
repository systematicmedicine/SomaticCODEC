
# --- metrics_report.R ---
# 
# Calls on get_metrics.R functions and generates a pass/fail report for all metrics.
# 
# Author: Joshua Johnstone

# Load packages
library(dplyr)

# Load component metrics
component_metrics <- read.csv("config/component_metrics.csv") %>% 
  select(1:3, 5:9)

# Get sample types from config
ex_samples <- read.csv("config/ex_samples.csv") %>% 
  pull(ex_sample)

ms_samples <- read.csv("config/ms_samples.csv") %>% 
  pull(ms_sample)

# Load get_metrics.R functions
source("scripts/get_metrics.R")

# Make list of functions to run
get_metric_functions <- Filter(function(x) is.function(get(x)) && startsWith(x, "get"), ls())

# Run get_metrics.R functions and store results in list
metric_dataframes <- lapply(get_metric_functions, function(function_name) {
  function_to_run <- get(function_name)
  
  tryCatch({
    message("Running ", function_name, "...")
    result <- function_to_run()
    result  # Return result if successful
  }, error = function(e) {
    warning("Function ", function_name, " failed: ", conditionMessage(e))
    
    # Insert placeholder row with cleaned metric name
    data.frame(
      metric = sub("^get", "", function_name),
      sample = NA_character_,
      value = NA_real_
    )
  })
})

# Combine metrics values into one data frame  
combined_metrics_values <- do.call(rbind, metric_dataframes) %>% 
  # Add sample_type column
  mutate(sample_type = case_when(
    sample %in% ex_samples ~ "Experimental",
    sample %in% ms_samples ~ "Matched")) %>% 
  # Add ms or ex to metric names based on sample type
  mutate(metric = case_when(
    sample_type == "Experimental" ~ paste0("ex_", metric),
    sample_type == "Matched" ~ paste0("ms_", metric)))

# Create metrics report data frame
component_metrics_report <- combined_metrics_values %>% 
  # Join with component metrics, keeping only relevant metrics
  inner_join(component_metrics, by = c("metric", "sample_type")) %>% 
  mutate(nn = ifelse(value >= nn_lower & value <= nn_upper, "PASS", "FAIL"),
         ideal = ifelse(value >= ideal_lower & value <= ideal_upper, "PASS", "FAIL")) %>% 
  arrange(metric, sample)

# Export metrics report as csv
write.csv(component_metrics_report, "metrics/component_metrics_report.csv", row.names = FALSE)

