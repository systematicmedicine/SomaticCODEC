#!/usr/bin/env python3
"""
--- check_included_chromosomes_present.py

Checks that chromosomes included for variant calling are present in reference and common BEDs

Designed to be used exclusively with the rule "check_included_chromosomes_present"

Authors:
    - Joshua Johnstone
"""
from pathlib import Path
import sys
import argparse

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting check_included_chromosomes_present.py", flush=True)

    # Load inputs
    reference_fai = Path(args.fai)
    precomputed_masks = [Path(p) for p in args.precomputed_masks]
    included_chromosomes = set(args.included_chromosomes)

    errors = False

    # --- Check reference FAI ---
    with open(reference_fai) as f:
        ref_chroms = {line.split()[0] for line in f}
    missing_in_ref = included_chromosomes - ref_chroms
    if missing_in_ref:
        print(
            f"[ERROR] Missing chromosomes included for variant calling in FAI file ({reference_fai}): "
            + ", ".join(sorted(missing_in_ref)),
            file=sys.stderr, flush=True
            )
        errors = True

    # --- Check each BED file ---
    for bed_file in precomputed_masks:
        with open(bed_file) as f:
            bed_chroms = {line.strip().split()[0] for line in f}
        missing_in_bed = included_chromosomes - bed_chroms
        if missing_in_bed:
            print(
                f"[ERROR] Missing chromosomes included for variant calling in BED file ({bed_file}): "
                + ", ".join(sorted(missing_in_bed)),
                file=sys.stderr, flush=True
                )
            errors = True

    if errors:
        sys.exit(1)

    # --- All checks passed, create done file ---
    with open(args.done_file, "w") as f:
        f.write("✅ All chromosomes included for variant calling are present in reference FAI and common BEDs.\n")

    print(f"✅ All chromosomes included for variant calling are present in reference FAI and common BEDs.", flush=True)

    print("[INFO] Completed check_included_chromosomes_present.py", flush=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--fai", required=True)
    parser.add_argument("--precomputed_masks", required=True, nargs = "+")
    parser.add_argument("--included_chromosomes", required=True, nargs = "+")
    parser.add_argument("--done_file", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)