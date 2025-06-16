"""
--- samplenames.py ---

Renames index adapter FASTA headers based on ex_sample names from ex_samples.csv,
**restricted to the current lane** (passed in via Snakemake params).

Author: James Phie
"""

import pandas as pd

# Load ex_samples.csv
df = pd.read_csv(snakemake.input.mapping)

# Filter by current lane
lane = snakemake.params.lane
df = df[df["lane"] == lane]

# Create adapter → ex_sample mapping (only for current lane)
name_map = dict(zip(df["adapter"], df["ex_sample"]))

def rename(infasta, outfasta):
    with open(infasta) as fin, open(outfasta, 'w') as fout:
        for line in fin:
            if line.startswith('>'):
                old = line.strip()[1:]
                new = name_map.get(old, old)  # Replace only if adapter found
                fout.write(f">{new}\n")
            else:
                fout.write(line)

# Apply renaming to all four FASTA files
rename(snakemake.input.r1start, snakemake.output.r1start_out)
rename(snakemake.input.r1end,   snakemake.output.r1end_out)
rename(snakemake.input.r2start, snakemake.output.r2start_out)
rename(snakemake.input.r2end,   snakemake.output.r2end_out)