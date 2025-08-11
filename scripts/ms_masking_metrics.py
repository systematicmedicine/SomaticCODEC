"""
--- ms_masking_metrics.py ---

Calculates the percentage of the genome masked by each BED file. To be used with rule ms_masking_metrics.

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""

import sys
import subprocess
import json

def run_cmd(cmd):
    # Run shell command and return stdout
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"[ERROR] Command failed: {cmd}")
        print(result.stderr)
        sys.exit(1)
    return result.stdout.strip()

def main(snakemake):
    # Redirect stdout and stderr to log file
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting masking_metrics.py")

    # Map logical mask names to bed file paths
    mask_files = {
        "gnomAD": snakemake.input.gnomAD_bed,
        "GIAB": snakemake.input.GIAB_bed,
        "lowdepth": snakemake.input.ms_lowdepth_bed,
        "germ_deletions": snakemake.input.ms_germ_del_bed,
        "germ_insertions": snakemake.input.ms_germ_ins_bed,
        "germ_snvs": snakemake.input.ms_germ_snv_bed,
        "combined_mask": snakemake.input.combined_bed,
    }

    ref_index = snakemake.input.ref_index
    sample = snakemake.params.sample

    intermediate_sorted = snakemake.output.intermediate_sorted
    intermediate_merged = snakemake.output.intermediate_merged
    json_out_path = snakemake.output.mask_metrics

    # Calculate total genome size
    total_genome_bp = int(run_cmd(f"awk '{{sum += $2}} END {{print sum}}' {ref_index}"))

    results = {}

    for mask_name, bed_path in mask_files.items():
        # Sort BED
        run_cmd(f"bedtools sort -i {bed_path} > {intermediate_sorted}")
        # Merge BED
        run_cmd(f"bedtools merge -i {intermediate_sorted} > {intermediate_merged}")
        # Calculate masked bases
        masked_bp = int(run_cmd(f"awk '{{sum += $3 - $2}} END {{print sum}}' {intermediate_merged}"))
        pct = (masked_bp / total_genome_bp) * 100 if total_genome_bp else 0.0

        results[mask_name] = {
            "masked_bases": masked_bp,
            "percentage_of_ref_genome": round(pct, 2)
        }

    output_data = {
        "description": "Masking metrics per BED file.",
        "sample": sample,
        "total_genome_bases": total_genome_bp,
        "mask_files": results
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed masking_metrics.py")

if __name__ == "__main__":
    main(snakemake)

