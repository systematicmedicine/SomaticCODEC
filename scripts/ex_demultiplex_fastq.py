"""
--- ex_demultiplex_fastq.py ---

Demultiplex each lane specific FASTQ pair into sample and technical control FASTQ pairs

To be used exclusively with rule ex_demultiplex_fastq

Inputs:
  - Raw lane FASTQ files

Outputs:
  - FASTQ pairs for each sample and technical control
  - Metrics file

Authors:
    - Joshua Johnstone
"""

# Import libraries
import subprocess
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]  # assumes scripts/ is directly under PROJECT_ROOT
sys.path.insert(0, str(PROJECT_ROOT))
import helpers.get_metadata as md

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_demultiplex.py")

    # Define inputs
    raw_r1_files = {Path(file).parent.name: file for file in snakemake.input.raw_r1}
    raw_r2_files = {Path(file).parent.name: file for file in snakemake.input.raw_r2}
    r1_start_files = {Path(file).parent.name: file for file in snakemake.input.r1_start}
    r2_start_files = {Path(file).parent.name: file for file in snakemake.input.r2_start}

    # Define params
    lane_ids = snakemake.params.lane_ids
    max_error_rate = snakemake.params.max_error_rate
    min_adapter_overlap = snakemake.params.min_adapter_overlap
    suffix_r1 = snakemake.params.suffix_r1
    suffix_r2 = snakemake.params.suffix_r2
    out_dir = snakemake.params.out_dir
    threads = snakemake.threads

    # Define outputs
    metrics_files = {Path(file).parent.name: file for file in snakemake.output.metrics}

    # Loop over each lane
    for lane in lane_ids:
        raw_r1 = raw_r1_files[lane]
        raw_r2 = raw_r2_files[lane]
        r1_fasta = r1_start_files[lane]
        r2_fasta = r2_start_files[lane]
        metrics_file = metrics_files[lane]

        cmd = [
            "cutadapt",
            "-j", str(threads),
            "--error-rate", str(max_error_rate),
            "--overlap", str(min_adapter_overlap),
            f"-g", f"^file:{r1_fasta}",
            f"-G", f"^file:{r2_fasta}",
            "--pair-adapters",
            "--report=full",
            "--action=none",
            "--discard-untrimmed",
            "-o", f"{out_dir}/{{name}}/{{name}}_{suffix_r1}",
            "-p", f"{out_dir}/{{name}}/{{name}}_{suffix_r2}",
            raw_r1,
            raw_r2
        ]

        with open(metrics_file, "w") as report_file, open(snakemake.log[0], "a") as log_file:
            subprocess.run(cmd, stdout=report_file, stderr=log_file, text=True, check=True)

    print("[INFO] Completed ex_demultiplex.py")

if __name__ == "__main__":
    main(snakemake) 

