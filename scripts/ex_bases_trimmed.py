#!/usr/bin/env python3
"""
ex_bases_trimmed.py

Calculates the count and percentage of bases lost during ex_trim_fastq

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import subprocess
import sys
from pathlib import Path

def main(snakemake):
    # Redirect stdout/stderr
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_bases_trimmed.py")

    # Inputs
    pre_files = [snakemake.input["pre_r1"], snakemake.input["pre_r2"]]
    post_files = [snakemake.input["post_r1"], snakemake.input["post_r2"]]
    json_out_path = snakemake.output["json"]
    sample = snakemake.params["sample"]

    def count_bases(fastq_path: str):
        result = subprocess.run(
            ["seqkit", "stats", "-Ta", fastq_path],
            stdout=subprocess.PIPE,
            stderr=open(snakemake.log[0], "a"),
            text=True,
            check=True
        )
        lines = [ln for ln in result.stdout.splitlines() if ln.strip()]
        header = lines[0].split("\t")
        row = lines[1].split("\t")
        idx_sum = header.index("sum_len")
        return int(row[idx_sum])

    pre_total = sum(count_bases(f) for f in pre_files)
    post_total = sum(count_bases(f) for f in post_files)

    trimmed_bases = pre_total - post_total
    percent_trimmed = round(trimmed_bases / pre_total * 100, 2) if pre_total > 0 else 0.0

    output_data = {
        "description": "Count and percentage of bases lost during ex_trim_fastq.",
        "sample": sample,
        "pre_trim_bases": pre_total,
        "post_trim_bases": post_total,
        "trimmed_bases": trimmed_bases,
        "percent_bases_trimmed": percent_trimmed
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_bases_trimmed.py")

if __name__ == "__main__":
    main(snakemake)