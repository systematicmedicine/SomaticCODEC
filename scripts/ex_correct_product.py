"""
--- ex_correct_product.py ---

To be considered a CODECseq correct product, the following criteria must be met:
1. Read 1 and read 2 both present at >minimum insert size (typically 70bp, set in ex_preprocess_fastq.smk, rule ex_filter)
2. Read 1 and read 2 align to the same chromosome, with the start of read 1 being within ~500 base pairs of the end of read 2
    * The ~500bp acceptable distance is determined by bwa-mem2 during alignment in rule ex_map, 'properly paired' 0x2 flag)
3. Read 1 and read 2 are read in the expected direction

A large proportion (>20%) of CODECseq byproducts are expected to be intermolecular byproducts, where a different dsDNA molecule binds to each end of the adapter quadruplex.
These byproducts should mainly be filtered in step 2 above. 

The correct product is calculated as number of properly paired read pairs in the aligned bam for all samples in the lane divided by total reads in the lane

Number filtered as singleton reads (filtered_missingread), and filtered for small insert size (filtered_smallinsertsize) are already factored into the above calculation.
 
Author: James Phie
"""
import json
import pandas as pd

# Inputs from Snakemake
demux_json = snakemake.input.demux_json
trim_reports = snakemake.input.trim_reports
flagstats = snakemake.input.flagstats
samples = snakemake.params.samples
output_file = snakemake.output[0] 
lane = snakemake.wildcards.ex_lane

# Load global adapter match stats from demux_report
with open(demux_json) as f:
    demux_data = json.load(f)

total_read_pairs = demux_data["read_counts"]["input"]
matched_adapter_pairs = demux_data["read_counts"]["read1_with_adapter"]
global_match_fraction = matched_adapter_pairs / total_read_pairs if total_read_pairs > 0 else 0
global_match_pct = round(global_match_fraction * 100, 2)

# Derive per-sample read pair counts directly from the JSON
sample_pair_counts = {}
for r1_entry, r2_entry in zip(demux_data["adapters_read1"], demux_data["adapters_read2"]):
    assert r1_entry["name"] == r2_entry["name"], f"Sample mismatch: {r1_entry['name']} != {r2_entry['name']}"
    paired_count = min(r1_entry["total_matches"], r2_entry["total_matches"])
    sample_pair_counts[r1_entry["name"]] = paired_count

# Initialize totals
total_missing_adapter = total_read_pairs - matched_adapter_pairs
total_too_short = 0
total_filtered_mapping = 0
total_correct = 0

# Iterate using explicit sample order
for sample, trim_path, flagstat_path in zip(samples, trim_reports, flagstats):
    sample_matched_pairs = sample_pair_counts.get(sample, 0)

    # Too short filter
    with open(trim_path) as f:
        trim_data = json.load(f)
    too_short = trim_data["read_counts"]["filtered"]["too_short"] or 0
    total_too_short += too_short

    # Properly paired reads
    with open(flagstat_path) as f:
        lines = f.readlines()
    properly_paired_line = next(line for line in lines if "properly paired" in line)
    properly_paired_reads = int(properly_paired_line.strip().split()[0])
    properly_paired_pairs = properly_paired_reads // 2
    total_correct += properly_paired_pairs

    # Filtered mapping
    filtered_mapping = sample_matched_pairs - properly_paired_pairs
    total_filtered_mapping += filtered_mapping

# Final percent is properly paired pairs / total input
correct_product_pct = 100 * total_correct / total_read_pairs if total_read_pairs > 0 else 0

# Build output
df = pd.DataFrame([[  
    total_read_pairs,
    total_missing_adapter,
    global_match_pct,
    total_too_short,
    total_filtered_mapping,
    total_correct,
    round(correct_product_pct, 4)
]], columns=[
    "raw_reads_total", "filtered_missingread", "R1R2_present_%",
    "filtered_smallinsertsize", "filtered_mapping",
    "correct_aligned_total", "correct_aligned_%"
])

df.to_csv(output_file, sep="\t", index=False)