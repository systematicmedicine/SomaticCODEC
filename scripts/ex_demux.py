"""
--- ex_demux.py ---

Demultiplex each lane specific FASTQ pair into sample specific FASTQ pairs

To be used exclusively with rule ex demux

Inputs:
  - Parameter inection from rule ex demux

Outputs:
  - Per sample FASTQ pairs (for all samples)
  - Metrics file showing number of reads demuxed for each sample

Author: James Phie
"""

# Import libraries
import subprocess
import pandas as pd
from pathlib import Path
import shutil
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]  # assumes scripts/ is directly under PROJECT_ROOT
sys.path.insert(0, str(PROJECT_ROOT))
import scripts.get_metadata as md

# Redirect stdout and stderr to the Snakemake log file
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")

# Loop over each lane
for lane in md.get_ex_lane_ids(snakemake.config):
    fastq1 = f"tmp/{lane}/{lane}_r1_umi_extracted.fastq.gz"
    fastq2 = f"tmp/{lane}/{lane}_r2_umi_extracted.fastq.gz"

    r1_fasta = f"tmp/{lane}/{lane}_r1_start.fasta"
    r2_fasta = f"tmp/{lane}/{lane}_r2_start.fasta"
    json_out = f"metrics/{lane}/{lane}_demux_metrics.json"

    cmd = [
        "cutadapt",
        "-j", str(snakemake.threads),
        "-e", "2",
        f"-g", f"^file:{r1_fasta}",
        f"-G", f"^file:{r2_fasta}",
        "--pair-adapters",
        "--json", json_out,
        "--action=none",
        "-o", "tmp/{name}_r1_demux.fastq.gz",
        "-p", "tmp/{name}_r2_demux.fastq.gz",
        fastq1,
        fastq2
    ]

    with open(snakemake.log[0], "a") as log_file:
        subprocess.run(cmd, check=True, stdout=log_file, stderr=log_file)

    # Move output files into per-sample folders
    for sample in md.get_ex_lane_samples(snakemake.config)[lane]:
        r1_src = f"tmp/{sample}_r1_demux.fastq.gz"
        r2_src = f"tmp/{sample}_r2_demux.fastq.gz"
        r1_dst = f"tmp/{sample}/{sample}_r1_demux.fastq.gz"
        r2_dst = f"tmp/{sample}/{sample}_r2_demux.fastq.gz"

        Path(f"tmp/{sample}").mkdir(parents=True, exist_ok=True)
        shutil.move(r1_src, r1_dst)
        shutil.move(r2_src, r2_dst)

# Clean up final unknown FASTQs (overwritten each lane, so only the final lane copy exists)
unknown_r1 = Path("tmp/unknown_r1_demux.fastq.gz")
unknown_r2 = Path("tmp/unknown_r2_demux.fastq.gz")

for f in [unknown_r1, unknown_r2]:
    if f.exists():
        f.unlink()