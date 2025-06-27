"""
--- generatefastas.py ---

Generate per-lane codec index adapter FASTA files for demultiplexing and trimming from the sequences provided in ex_adapters.csv

Inputs:
  - ex_adapters.csv
  - ex_samples (as snakemake.params.samples)

Outputs:
  - FASTA files with only adapters used in the ex_sample column (no generic Quadruplex labels)

Author: James Phie
"""

import pandas as pd
from pathlib import Path
import re

# Load sample metadata and adapter sequences
samples = snakemake.params.samples
adapters = pd.read_csv(snakemake.input.adapters).set_index("ex_adapter")

# Map output paths back to (lane, region) using the filename
output_map = {}
pattern = re.compile(r"(?P<lane>[^_/]+)_(?P<region>r[12]_(start|end))\.fasta")

for path in snakemake.output:
    match = pattern.search(Path(path).name)
    if match:
        lane = match.group("lane")
        region = match.group("region")
        output_map[(lane, region)] = path

# Write each output FASTA
for (lane, region), output_path in output_map.items():
    lane_samples = samples[samples["lane"] == lane]
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        for _, row in lane_samples.iterrows():
            adapter_seq = adapters.loc[row["adapter"], region]
            f.write(f">{row['ex_sample']}\n{adapter_seq}\n")

    print(f"[INFO] Wrote: {output_path}")