#!/usr/bin/env python3
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
from pathlib import Path
import argparse

def main(args):
    # Redirect stdout/stderr to log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting masking_metrics.py")

    def run_cmd(cmd):
        """Run shell command and return stdout"""
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"[ERROR] Command failed: {cmd}")
            print(result.stderr)
            sys.exit(1)
        return result.stdout.strip()

    sample = args.sample
    ref_index = args.ref_index
    intermediate_sorted = args.intermediate_sorted
    intermediate_merged = args.intermediate_merged
    json_out_path = args.mask_metrics

    # Total genome size
    total_genome_bp = int(run_cmd(f"awk '{{sum += $2}} END {{print sum}}' {ref_index}"))

    # Map mask names to BED files
    mask_files = {}

    # Name precomputed masks by file basename (without extension)
    for bed_file in args.precomputed_masks:
        name = Path(bed_file).stem
        mask_files[name] = bed_file

    # Add other masks
    mask_files.update({
        "lowdepth": args.ms_lowdepth_bed,
        "ms_germ_risk_individual": args.ms_germ_risk_bed,
        "ms_germ_risk_all_samples": args.ms_germ_risk_all_samples,
        "combined_mask": args.combined_bed,
    })

    results = {}

    for mask_name, bed_path in mask_files.items():
        # Sort and merge each BED
        run_cmd(f"bedtools sort -i {bed_path} > {intermediate_sorted}")
        run_cmd(f"bedtools merge -i {intermediate_sorted} > {intermediate_merged}")

        # Compute masked bases
        masked_bp = int(run_cmd(f"awk '{{sum += $3 - $2}} END {{print sum}}' {intermediate_merged}"))
        pct = (masked_bp / total_genome_bp) * 100 if total_genome_bp else 0.0

        results[mask_name] = {
            "masked_bases": masked_bp,
            "percentage_of_ref_genome": round(pct, 2)
        }

    # Write JSON output
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
    parser = argparse.ArgumentParser()
    parser.add_argument("--precomputed_masks", required=True, nargs = "+")
    parser.add_argument("--ms_lowdepth_bed", required=True)
    parser.add_argument("--ms_germ_risk_bed", required=True)
    parser.add_argument("--ms_germ_risk_all_samples", required=True)
    parser.add_argument("--combined_bed", required=True)
    parser.add_argument("--ref_index", required=True)
    parser.add_argument("--mask_metrics", required=True)
    parser.add_argument("--intermediate_sorted", required=True)
    parser.add_argument("--intermediate_merged", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)

