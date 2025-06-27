import subprocess
import pandas as pd

samples_df = pd.DataFrame(snakemake.params.samples)
lanes_df = pd.DataFrame(snakemake.params.lanes)

# Loop over each lane
for lane in lanes_df["ex_lane"].unique():
    fastq1 = lanes_df.loc[lanes_df["ex_lane"] == lane, "fastq1"].values[0]
    fastq2 = lanes_df.loc[lanes_df["ex_lane"] == lane, "fastq2"].values[0]

    r1_fasta = f"tmp/adapter_fastas/{lane}_r1_start.fasta"
    r2_fasta = f"tmp/adapter_fastas/{lane}_r2_start.fasta"
    json_out = f"metrics/{lane}/{lane}_demux_metrics.json"

    cmd = [
        "cutadapt",
        "-j", str(snakemake.threads),
        "--no-indels",
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