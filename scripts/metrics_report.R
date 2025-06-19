
# --- metrics_report.R ---
# 
# Calls on get_metrics.R functions and generates a pass/fail report for all metrics.
# 
# Author: Joshua Johnstone

# Load packages
library(tidyverse)

# Load get_metrics.R functions
source("scripts/get_metrics.R")

# Make list of functions to run
all_functions <- Filter(function(x) is.function(get(x)), ls())

# Run get_metrics.R functions and store results in list
metric_dataframes <- lapply(all_functions, function(function_name){
  function_to_run <- get(function_name)
  function_to_run()
}) 


# Combine metrics values into one data frame  
combined_metrics_values <- do.call(rbind, metric_dataframes)

# Load key metrics
key_metrics <- read.csv("config/key_metrics.csv") %>% 
  select(2, 6:9)

# Create metrics report data frame
metrics_report <- combined_metrics_values %>% 
  left_join(key_metrics, by = "metric") %>% 
  mutate(nn = ifelse(value >= nn_lower & value <= nn_upper, "PASS", "FAIL"),
         ideal = ifelse(value >= ideal_lower & value <= ideal_upper, "PASS", "FAIL"))

