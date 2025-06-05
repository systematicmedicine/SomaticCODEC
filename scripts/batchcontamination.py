"""
--- batchcontamination.py ---

Calculates the number and percentage of reads that map to sample indices that were not used in the current experiment.

Previous tests on sample indices that have never been used suggest that unused sample indices should account for <0.0001% of total reads if no contamination has taken place. 

Author: James Phie
"""

import json
from Bio import SeqIO

# Inputs from Snakemake
json_path = snakemake.input.json
output_path = snakemake.output.contamination
fasta_path = snakemake.params.fasta
used_samples = set(snakemake.params.used)

# Parse all known barcodes from the FASTA
all_index_names = {record.id for record in SeqIO.parse(fasta_path, "fasta")}
unused_indexes = sorted(all_index_names - used_samples)

# Load demux JSON
with open(json_path) as f:
    report = json.load(f)

total_reads = report["read_counts"]["input"]
demuxed_read_pairs = min(report["read_counts"]["read1_with_adapter"],
                         report["read_counts"]["read2_with_adapter"])

# Collect matches from unused barcodes
contam_counts = {}
for entry in report["adapters_read1"] + report["adapters_read2"]:
    name = entry["name"]
    if name in unused_indexes:
        matches = entry["total_matches"]
        contam_counts[name] = contam_counts.get(name, 0) + matches

# Convert to read pairs
for name in contam_counts:
    contam_counts[name] //= 2

# Write output
with open(output_path, "w") as out:
    out.write("Sample\tRead pairs (contaminant)\tPercentage of demuxed\tPercentage of raw reads\n")
    for name, count in sorted(contam_counts.items(), key=lambda x: -x[1]):
        pct_demuxed = 100 * count / demuxed_read_pairs if demuxed_read_pairs > 0 else 0
        pct_total = 100 * count / total_reads if total_reads > 0 else 0
        out.write(f"{name}\t{count}\t{pct_demuxed:.4f}%\t{pct_total:.4f}%\n")