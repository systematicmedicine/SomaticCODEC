#!/usr/bin/env python3
"""
--- included_excluded_chromosomes_beds.py

Creates a mask for chromosomes that will be excluded for variant calling 

Designed to be used exclusively with the rule "included_excluded_chromosomes_beds"

Authors:
    - Cameron Fraser
    - Joshua Johnstone
"""

import argparse
import sys

def main(args):

    # Redirect stdout/stderr
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting included_excluded_chromosomes_beds.py")

    # Define chromosomes included for variant calling
    included_chromosomes = set(args.included_chromosomes)

    # Define inputs
    fai = args.fai

    # Define outputs
    exclude_bed = args.exclude_bed
    include_bed = args.include_bed

    # Load the .fai and filter
    with open(fai) as fai_in, open(exclude_bed, "w") as bed_out:
        for line in fai_in:
            chrom, length, *_ = line.strip().split("\t")
            if chrom not in included_chromosomes:
                bed_out.write(f"{chrom}\t0\t{length}\n")

    with open(fai) as fai_in, open(include_bed, "w") as bed_out:
        for line in fai_in:
            chrom, length, *_ = line.strip().split("\t")
            if chrom in included_chromosomes:
                bed_out.write(f"{chrom}\t0\t{length}\n") 

    print("[INFO] Completed included_excluded_chromosomes_beds.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--fai", required=True)
    parser.add_argument("--exclude_bed", required=True)
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--included_chromosomes", required=True, nargs = "+")
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)

