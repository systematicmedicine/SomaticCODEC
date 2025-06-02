import json
from Bio import SeqIO

# Inputs from Snakemake
json_path = snakemake.input.json
output_path = snakemake.output.readcounts
fasta_path = snakemake.params.fasta
used_samples = set(snakemake.params.used)

# Load demux JSON
with open(json_path) as f:
    report = json.load(f)

# Total read pairs (before processing)
total_reads = report["read_counts"]["input"]

# Demuxed read pairs = those with adapters in both read1 and read2
demuxed_read_pairs = min(report["read_counts"]["read1_with_adapter"],
                         report["read_counts"]["read2_with_adapter"])

# Count read pairs per sample
match_counts = {}

# Sum up matches from R1 and R2
for entry in report["adapters_read1"] + report["adapters_read2"]:
    name = entry["name"]
    if name in used_samples:
        matches = entry["total_matches"]
        match_counts[name] = match_counts.get(name, 0) + matches

# Convert raw matches (read count) to read pairs by dividing by 2
for name in match_counts:
    match_counts[name] = match_counts[name] // 2

# Write output
with open(output_path, "w") as out:
    out.write("Sample\tRead pairs per sample\tPercentage of demuxed\tPercentage of raw reads\n")
    for name, count in sorted(match_counts.items(), key=lambda x: -x[1]):
        pct_demuxed = 100 * count / demuxed_read_pairs if demuxed_read_pairs > 0 else 0
        pct_total = 100 * count / total_reads if total_reads > 0 else 0
        out.write(f"{name}\t{count}\t{pct_demuxed:.4f}%\t{pct_total:.4f}%\n")