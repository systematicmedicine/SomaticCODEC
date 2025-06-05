"""
--- duplication.py ---

Duplication rate calculated from umihistogram data, an output from ex_groupbyumi. 

Duplicates are caused by:
1. Library preparation PCR duplication
2. Flow cell 'PCR' duplication (when both the p5 and p7 strands of the original double stranded molecule bind to different regions of the flow cell)
3. Optical duplicates (optical cross-talk/signal bleed from adjacent spots on the flow cell)

The calculation is 1 - (unique reads/total reads). Unique reads are the number of reads with a unique UMI. 

Author: James Phie
"""

import pandas as pd

hist_files = snakemake.input
output_file = snakemake.output[0]

rows = []
for path in hist_files:
    sample = path.split("/")[-1].split(".")[0]  # extracts {sample} from filename
    df = pd.read_csv(path, sep="\t")
    
    unique_reads = (df["count"] * 2).sum()
    total_reads = (df["family_size"] * df["count"] * 2).sum()
    duplication_rate = 1 - (unique_reads / total_reads) if total_reads > 0 else 0

    rows.append([sample, unique_reads, total_reads, round(duplication_rate, 6)])

# Save output table
result_df = pd.DataFrame(rows, columns=["Sample", "Unique reads", "Total reads", "Duplication rate"])
result_df.to_csv(output_file, sep="\t", index=False)