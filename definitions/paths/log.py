"""
--- paths.log ---

Defines path constants for logs

Authors: 
    - Cameron Fraser
    - Joshua Johnstone

"""

# ---------------------------------------------------------------------------------------------------------------
# Shared
# ---------------------------------------------------------------------------------------------------------------

# Setup

RUN_PIPELINE = "logs/bin_scripts/run_pipeline.log"
SYSTEM_RESOURCE_USAGE = "logs/shared_rules/system_resource_usage.csv"

ENSURE_PIPELINE_LOG_EXISTS = "logs/shared_rules/ensure_pipeline_log_exists.log"
LOG_SYSTEM_RESOURCE_USAGE = "logs/shared_rules/log_system_resource_usage.log"
CHECK_INCLUDED_CHROMOSOMES_PRESENT = "logs/shared_rules/check_included_chromosomes_present.log"
COMPLETE_SETUP = "logs/shared_rules/complete_setup.log"

SYS_RESOURCE_LOG_DONE = "logs/shared_rules/log_system_resource_usage.done"
INC_CHROM_PRESENT_DONE = "logs/shared_rules/check_included_chromosomes_present.done"
SETUP_DONE = "logs/shared_rules/setup.done"

# Processing

BWAMEM_INDEX_FILES = "logs/shared_rules/bwamem_index_files.log"
PICARD_SEQUENCE_DICT = "logs/shared_rules/picard_sequence_dict.log"
SAMTOOLS_INDEX_FILES = "logs/shared_rules/samtools_index_files.log"
TABIX_INDEX_FILES = "logs/shared_rules/tabix_index_files.log"

INCLUDED_EXCLUDED_CHROMOSOMES_BEDS = "logs/shared_rules/included_excluded_chromosomes_beds.log"

# Metrics
COLLATE_BENCHMARKS = "logs/shared_rules/collate_benchmarks.log"
COMBINED_BENCHMARKS = "logs/shared_rules/combined_benchmarks.csv"

CREATE_JOB_LOG = "logs/shared_rules/create_job_log.log"
JOB_LOG = "logs/shared_rules/job_log.csv"

CREATE_METRICS_REPORT = "logs/shared_rules/create_metrics_report.log"

CREATE_RUN_TIMELINE_PLOT = "logs/shared_rules/create_run_timeline_plot.log"
RUN_TIMELINE_PLOT = "logs/shared_rules/run_timeline.pdf"

WRITE_GIT_METADATA = "logs/shared_rules/write_git_metadata.log"
GIT_METADATA = "logs/shared_rules/git_metadata.json"
