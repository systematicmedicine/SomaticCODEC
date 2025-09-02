"""
--- check_included_chromosomes_present.py

Checks that chromosomes included for variant calling are present in reference and common BEDs

Designed to be used exclusively with the rule "check_included_chromosomes_present"

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import sys

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting check_included_chromosomes_present.py", flush=True)

    # Load inputs
    reference_fai = Path(snakemake.input.fai)
    precomputed_masks = [Path(p) for p in snakemake.input.precomputed_masks]
    included_chromosomes = set(snakemake.params.included_chromosomes)

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
    with open(snakemake.output[0], "w") as f:
        f.write("✅ All chromosomes included for variant calling are present in reference FAI and common BEDs.\n")

    print(f"✅ All chromosomes included for variant calling are present in reference FAI and common BEDs.", flush=True)

    print("[INFO] Completed check_included_chromosomes_present.py", flush=True)

if __name__ == "__main__":
    main(snakemake)