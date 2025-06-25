"""
--- generatefastas.py ---

Generate by lane codec index adapter fasta files for demultiplexing and trimming from the sequences provided in ex_adapters.csv

Input: ex_adapters.csv
Output: Four fasta files (start and end of R1 and R2)

Author: James Phie
"""

import pandas as pd
from pathlib import Path
import re

samples = snakemake.params.samples
adapters = pd.read_csv(snakemake.input.adapters).set_index("adapter")

# Map output paths back to (lane, region) using the filename
output_map = {}
pattern = re.compile(r"(?P<lane>[^_/]+)_(?P<region>r[12](start|end))\.fasta")

for path in snakemake.output:
    match = pattern.search(Path(path).name)
    if match:
        lane = match.group("lane")
        region = match.group("region")
        output_map[(lane, region)] = path

# Write each output FASTA using snakemake.output
for (lane, region), output_path in output_map.items():
    lane_samples = samples[samples["ex_lane"] == lane]
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        for _, row in lane_samples.iterrows():
            f.write(f">{row['ex_sample']}\n{adapters.loc[row['adapter'], region]}\n")

        for adapter_name, adapter_row in adapters.iterrows():
            if adapter_name not in lane_samples["adapter"].values:
                f.write(f">{adapter_name}\n{adapter_row[region]}\n")

    print(f"[INFO] Wrote: {output_path}")