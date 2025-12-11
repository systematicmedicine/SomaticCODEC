#!/usr/bin/env Rscript
#
# --- create_run_timeline_plot.R ---
#
# Create a plot of jobs and resource usage during the run
#   - To be used exclusively with Snakemake parent rule create_run_timeline_plot
#
# Author:
#   - Joshua Johnstone
#

# Load libraries
library(dplyr)
library(tidyr)
library(ggpubr)
library(jsonlite)
library(argparse)

# Snakemake-injected paths
parser <- ArgumentParser()
parser$add_argument("--job_log", required = TRUE)
parser$add_argument("--resources_log", required = TRUE)
parser$add_argument("--plot", required = TRUE)
parser$add_argument("--run_name", required = TRUE)
parser$add_argument("--max_iops", required = TRUE)
parser$add_argument("--max_throughput", required = TRUE)
parser$add_argument("--log", required = TRUE)
args <- parser$parse_args()

exp_name <- args$run_name
git_metadata <- args$git_metadata
job_log_path <- args$job_log
resources_log_path <- args$resources_log
max_iops <- as.integer(args$max_iops)
max_throughput <- as.integer(args$max_throughput)
log_path <- args$log
output_plot_path <- args$plot

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
             linewidth = 1, color = "steelblue") +
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
  mutate(time = as.POSIXct(time, tz = "UTC"),
         disk_space = disk_used_GB / (disk_used_GB + disk_avail_GB) * 100,
         disk_IOPS = (disk_IOPS / max_iops) * 100,
         disk_throughput = (disk_throughput_MiBs / max_throughput) * 100,
         mem = mem_used_GB / (mem_used_GB + mem_avail_GB) * 100,
         cpu = cpu_load / (cpu_load + cpu_avail) * 100) %>% 
  select(time, disk_space, disk_IOPS, disk_throughput, mem, cpu) %>% 
  pivot_longer(cols = c(disk_space, disk_IOPS, disk_throughput, mem, cpu),
               values_to = "pct_utilisation",
               names_to = "resource")

resources_plot <- ggplot(resources_utilised) +
  geom_line(aes(x = time, y = pct_utilisation, colour = resource), linewidth = 1) + 
  theme_bw() +
  scale_y_continuous(limits = c(0, 100)) +
  scale_x_datetime(limits = as.POSIXct(c(min(job_log$start_time), 
                                         max(job_log$finish_time)),
                                       tz = "UTC"),
                  name = NULL,
                  breaks = seq(min(job_log$start_time), 
                              max(job_log$finish_time),
                              (max(job_log$finish_time) - min(job_log$start_time)) / 6)) +
  theme(plot.caption = element_text(hjust = 0),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

timeline_plot <- ggarrange(jobs_plot, resources_plot, 
          nrow = 2,
          align = "v")

# Export pdf
ggsave(output_plot_path, timeline_plot, width = 25, height = 10)

# Release logging
message(sprintf("[INFO] Script finished at %s\n", Sys.time()))
sink(type = "message")
close(log_con)

