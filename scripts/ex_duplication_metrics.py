"""
--- ex_duplication_metrics.py ---

Duplication rate calculated from umihistogram data, an output from ex_annotate_bam from ex_create_dsc.smk. 

Duplicates are caused by:
1. Library preparation PCR duplication
2. Flow cell 'PCR' duplication (when both the p5 and p7 strands of the original double stranded molecule bind to different regions of the flow cell)
3. Optical duplicates (optical cross-talk/signal bleed from adjacent spots on the flow cell)

The BAM used for this calculation is the aligned BAM with byproducts removed (correct product only).

The calculation is 1 - (unique reads/total reads). Unique reads are the number of reads with a unique UMI. 

Author: James Phie
"""

import pandas as pd
import sys
import json

def main(snakemake):
    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_duplication_metrics.py")

    # Define inputs
    hist_file = snakemake.input.umi_metrics
    sample = snakemake.params.sample

    # Define output
    output_json = snakemake.output.json

    rows = []
    df = pd.read_csv(hist_file, sep="\t")
    unique_reads = int((df["count"] * 2).sum())
    total_reads = int((df["family_size"] * df["count"] * 2).sum())
    duplication_rate = round(100 * (1 - unique_reads / total_reads), 2)
    pct_unique_reads = round(100 * (unique_reads / total_reads), 2)

    # Create output JSON object
    output_data = {
        "description": "Duplication rates calculated from umihistogram data",
        "sample": sample,
        "unique_reads": unique_reads,
        "total_reads": total_reads,
        "duplication_rate": duplication_rate,
        "pct_unique_reads": pct_unique_reads
        }

    # Write JSON output
    with open(output_json, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    # Print script completion message to log
    print("[INFO] Completed ex_duplication_metrics.py")

if __name__ == "__main__":
    main(snakemake)