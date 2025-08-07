"""
--- ex_call_dsc_metrics.py ---

Generates a summary file with the percentage of reads lost during ex_call_dsc

To be used with rule ex_call_dsc_metrics

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess
import json

# Initiate logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_call_dsc_metrics.py")

# Get BAM file paths
pre_call_bam_path = snakemake.input.pre_call_bam
post_call_bam_path = snakemake.input.post_call_bam

# Define output JSON path
json_out_path = snakemake.output.call_dsc_metrics

# Define sample name
sample = snakemake.params.sample

# Function to count primarily alignment reads in a BAM file
def count_reads(bam_path):
    with open(snakemake.log[0], "a") as log_file:
        result = subprocess.run(
            ["samtools", "view", "-c", "-F", "0x900", bam_path],
            stdout=subprocess.PIPE,
            stderr=log_file,
            text=True,
            check=True
            )
    return int(result.stdout.strip())

pre_reads = count_reads(pre_call_bam_path)
post_reads = count_reads(post_call_bam_path)

reads_lost = round(100 * (pre_reads - post_reads) / pre_reads, 1)

output_data = {
     "description": (
    "Percentage of reads lost during ex_call_dsc."
    ),
    "sample": sample,
    "reads_lost": reads_lost
}

# Write to JSON
with open(json_out_path, "w") as out_f:
    json.dump(output_data, out_f, indent=4)

print("[INFO] Completed ex_call_dsc_metrics.py")








