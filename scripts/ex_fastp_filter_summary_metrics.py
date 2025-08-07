"""
--- ex_fastp_filter_summary_metrics.py ---

Generates a summary file with reads filtered by fastp in ex_filter_fastq

To be used with rule ex_fastp_filter_summary_metrics

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json

# Initiate logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_fastp_filter_summary_metrics.py")

# Load fastp report paths
json_length_path = snakemake.input.json_length
json_meanquality_path = snakemake.input.json_meanquality

# Load sample name
sample = snakemake.params.sample

# Define output JSON path
json_out_path = snakemake.output.filter_summary_metrics

# Load input JSON files
with open(json_length_path, "r") as f:
    json_length = json.load(f)

with open(json_meanquality_path, "r") as f:
    json_meanquality = json.load(f)

# Calculate reads filtered
reads_filtered_length = round(100 * (json_length["summary"]["before_filtering"]["total_reads"] - 
                             json_length["summary"]["after_filtering"]["total_reads"]) / json_length["summary"]["before_filtering"]["total_reads"], 1)

reads_filtered_meanquality = round(100 * (json_meanquality["summary"]["before_filtering"]["total_reads"] - 
                             json_meanquality["summary"]["after_filtering"]["total_reads"]) / json_meanquality["summary"]["before_filtering"]["total_reads"], 1)

# Output data to JSON
output_data = {
    "description": (
    "Summary of reads filtered with fastp in ex_filter_fastq"
    ),
    "sample": sample,
    "reads_filtered_length": reads_filtered_length,
    "reads_filtered_meanquality": reads_filtered_meanquality
}

# Write to JSON
with open(json_out_path, "w") as out_f:
    json.dump(output_data, out_f, indent=4)

print("[INFO] Completed ex_fastp_filter_summary_metrics.py")
