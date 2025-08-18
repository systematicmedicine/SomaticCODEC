"""
--- percent_reads_bases_lost.py ---

Calculates the percentage of reads and bases lost between sets of two FASTQ or BAM files.

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import sys
from pathlib import Path

def main(snakemake):
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting percent_reads_bases_lost.py")

    # Look for the file path in the read_base_counts.json and return (reads, bases)
    def find_counts_in_json(json_data, file_path: Path):
        for file_entry in json_data.get("files", []):
            if Path(file_entry["path"]).resolve() == file_path.resolve():
                return file_entry["reads"], file_entry["bases"]
        raise RuntimeError(f"File {file_path} not found in read_base_counts.json")

    # Get inputs and output from snakemake
    counts_json_path = Path(snakemake.input.counts_json)
    pre_files = [Path(f) for f in snakemake.input.pre_files]
    post_files = [Path(f) for f in snakemake.input.post_files]
    output_json_path = Path(snakemake.output.json)

    with counts_json_path.open("r") as fh:
        metrics_data = json.load(fh)

    # Collect counts for each file in each comparison
    comparisons = []
    total_pre_reads, total_post_reads = 0, 0
    total_pre_bases, total_post_bases = 0, 0

    for pre_file, post_file in zip(pre_files, post_files):
        pre_reads, pre_bases = find_counts_in_json(metrics_data, pre_file)
        post_reads, post_bases = find_counts_in_json(metrics_data, post_file)

        comparisons.append({
            "pre_file": str(pre_file),
            "post_file": str(post_file),
            "pre_reads": pre_reads,
            "post_reads": post_reads,
            "pre_bases": pre_bases,
            "post_bases": post_bases
        })

        total_pre_reads += pre_reads
        total_post_reads += post_reads
        total_pre_bases += pre_bases
        total_post_bases += post_bases

    # Use total read and base values to calculates losses
    reads_lost = total_pre_reads - total_post_reads
    pct_reads_lost = round(100 * reads_lost / total_pre_reads, 2) if total_pre_reads else None
    
    bases_lost = total_pre_bases - total_post_bases
    pct_bases_lost = round(100 * bases_lost / total_pre_bases, 2) if total_pre_bases else None

    # Output results
    result = {
        "counts_json": str(counts_json_path),
        "comparisons": comparisons,
        "total_pre_reads": total_pre_reads,
        "total_post_reads": total_post_reads,
        "reads_lost": reads_lost, 
        "pct_reads_lost": pct_reads_lost,
        "total_pre_bases": total_pre_bases,
        "total_post_bases": total_post_bases,
        "bases_lost": bases_lost,
        "pct_bases_lost": pct_bases_lost
    }

    with output_json_path.open("w") as fh:
        json.dump(result, fh, indent=2)

    print("[INFO] Completed percent_reads_bases_lost.py")

if __name__ == "__main__":
    main(snakemake)
