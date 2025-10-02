# ===========================================================================
# create_run_timeline_plot.R
#
# Create a plot of jobs and resource usage during the run
#   - To be used exclusively with Snakemake parent rule create_run_timeline_plot
#
# Author:
#   - Joshua Johnstone
# ===========================================================================


# Load libraries
library(dplyr)
library(tidyr)
library(ggpubr)
library(jsonlite)

# Define hard coded variables
if (!exists("snakemake")) {
  # Manual mode (for local testing)
  config <- list(experiment = list(name = "local_test_experiment"))
  git_metadata <- "logs/global_rules/git_metadata.json"
  job_log_path <- "logs/global_rules/job_log.csv"
  resources_log_path <- "logs/global_rules/system_resource_usage.csv"
  max_iops <- 3000
  log_path <- "logs/global_rules/create_run_timeline_plot.log"
  output_plot_path <- "logs/global_rules/run_timeline.pdf"
} else {
  # Snakemake-injected paths
  config <- snakemake@config
  git_metadata <- snakemake@input[["git_metadata"]]
  job_log_path <- snakemake@input[["job_log"]]
  resources_log_path <- snakemake@input[["resources_log"]]
  max_iops <- snakemake@params[["max_iops"]]
  log_path <- snakemake@log[[1]]
  output_plot_path <- snakemake@output[["plot"]]
}

# Start logging
log_con <- file(log_path, open = "wt")
sink(log_con, type = "message")
message(sprintf("[INFO] Starting create_run_timeline_plot.R at %s\n", Sys.time()))

# Load data
job_log <- read.csv(job_log_path) %>% 
  mutate(start_time = as.POSIXct(start_time, tz = "UTC"),
         finish_time = as.POSIXct(finish_time, tz = "UTC"))
resources_log <- read.csv(resources_log_path)

# Create jobs plot
exp_name <- config$experiment$name
date <- format(Sys.Date(), "%Y-%m-%d")
pipeline_version <- fromJSON("logs/global_rules/git_metadata.json")$git_tag
title <- paste0(exp_name, " timeline")
subtitle <- paste0(date, ", ", pipeline_version)

job_log <- job_log %>%
  arrange(desc(jobid)) %>%
  mutate(mid_time = start_time + (finish_time - start_time)/2) %>%
  unite("rule_jobid", rule, jobid)

job_labels <- job_log %>%
  filter(finish_time - start_time > 60)

jobs_plot <- job_log %>%
  ggplot() +
  geom_segment(aes(x = start_time, xend = finish_time, y = rule_jobid, yend = rule_jobid),
             size = 1, color = "steelblue") +
  geom_text(data = job_labels, aes(x = mid_time, y = rule_jobid, label = rule_jobid),
            size = 2, vjust = -0.7) +
  scale_x_datetime(limits = as.POSIXct(c(min(job_log$start_time), 
                                         max(job_log$finish_time)),
                                       tz = "UTC")) +
  theme_bw() +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        axis.text.x = element_blank(),
        axis.title.x = element_blank()) +
  labs(title = title,
    subtitle = subtitle)

# Create resources plot
resources_utilised <- resources_log %>% 
  mutate(disk_space = disk_used_GB / (disk_used_GB + disk_avail_GB) * 100,
         disk_IOPS = (disk_IOPS / max_iops) * 100,
         mem = mem_used_GB / (mem_used_GB + mem_avail_GB) * 100,
         cpu = cpu_load / (cpu_load + cpu_avail) * 100) %>% 
  select(time, disk_space, disk_IOPS, mem, cpu) %>% 
  pivot_longer(cols = c(disk_space, disk_IOPS, mem, cpu),
               values_to = "pct_utilisation",
               names_to = "resource")

resources_plot <- ggplot(resources_utilised) +
  geom_line(aes(x = time, y = pct_utilisation, colour = resource), linewidth = 1) + 
  theme_bw() +
  scale_y_continuous(limits = c(0, 100)) +
  scale_x_datetime(limits = as.POSIXct(c(min(job_log$start_time), 
                                         max(job_log$finish_time)),
                                       tz = "UTC")) +
  theme(plot.caption = element_text(hjust = 0))

timeline_plot <- ggarrange(jobs_plot, resources_plot, 
          nrow = 2,
          align = "v")

# Export pdf
ggsave(output_plot_path, timeline_plot, width = 25, height = 10)

# Release logging
message(sprintf("[INFO] Script finished at %s\n", Sys.time()))
sink(type = "message")
close(log_con)

