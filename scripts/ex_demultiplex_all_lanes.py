"""
--- ex_demultiplex_all_lanes.py ---

Demultiplex each lane specific fastq read pairs into sample specific fastq read pairs

Inputs:
  - All fastq pairs (for all lanes)
  - Codec quadruplex adapter sequences
  - ex_lanes and ex_samples data frames

Outputs:
  - Per sample fastq pairs (for all samples)
  - Metrics file showing number of reads demuxed for each sample

Author: James Phie
"""

import subprocess
import pandas as pd
from pathlib import Path
import shutil

samples_df = pd.DataFrame(snakemake.params.samples)
lanes_df = pd.DataFrame(snakemake.params.lanes)

# Loop over each lane
for lane in lanes_df["ex_lane"].unique():
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

    subprocess.run(cmd, check=True)

    # Move output files into per-sample folders
    for sample in samples_df.loc[samples_df["lane"] == lane, "ex_sample"]:
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