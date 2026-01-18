#!/usr/bin/env python3
"""
--- ex_reference_trinuc_counts.py ---

Counts trinucleotides in a reference genome FASTA file using a 3bp sliding window approach.

Authors:
  - Chat-GPT
  - Cameron Fraser
  - Joshua Johnstone
"""

import sys
import argparse
from collections import Counter
from Bio import SeqIO
from Bio.Seq import Seq
from datetime import datetime
import pandas as pd

def main(args):

    # Start logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_reference_trinuc_counts.py")

    # Define inputs
    ref_fasta_path = args.ref_fasta

    # Define output path
    output_csv_path = args.output_csv

    # Initialise trinucleotide counter
    counts = Counter()

    # Initialise progress counter
    bases_processed = 0
    progress_step = 10e6

    # Slide 3bp window across sequence to count trinucleotides
    for record in SeqIO.parse(ref_fasta_path, "fasta"):
        seq = str(record.seq).upper()
        for position in range(1, len(seq) - 1): # Skip positions at ends of sequence (no flanking bases)
            trinuc = seq[position-1:position+2]

            # Skip trinucleotides containing N
            if "N" in trinuc:
                continue

            # Convert to pyrimidine-centered
            center = trinuc[1]
            if center in "AG":
                trinuc = str(Seq(trinuc).reverse_complement())
                center = trinuc[1]

            # Add to trinucleotide count
            counts[trinuc] += 1

            # Print progress update
            bases_processed += 1
            if bases_processed >= progress_step:
                time_now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(f"[{time_now}] [INFO] Processed {bases_processed / 1e6} million bases", flush = True)
                progress_step += 10e6

    # Output counts as CSV
    counts_df = (
        pd.DataFrame.from_dict(counts, orient="index", columns=["trinuc_genome_count"])
        .reset_index()
        .rename(columns={"index": "trinucleotide"})
        .sort_values("trinucleotide"))
    
    counts_df.to_csv(output_csv_path, index=False)

    print("[INFO] Finished ex_reference_trinuc_counts.py")

if __name__ == "__main__":
    # Parameter injection
    parser = argparse.ArgumentParser()
    parser.add_argument("--ref_fasta", required=True)
    parser.add_argument("--output_csv", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
