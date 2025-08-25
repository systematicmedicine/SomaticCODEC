"""
--- check_ex_ms_mapping.py

Checks mapping of MS and EX samples in ms_samples.csv and ex_samples.csv

Designed to be used exclusively with the rule "check_ex_ms_mapping"

Authors:
    - Chat-GPT
    - Joshua Johnstone

"""
# Load libraries
import sys
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parents[1]  # assumes scripts/ is directly under PROJECT_ROOT
sys.path.insert(0, str(PROJECT_ROOT))
import scripts.get_metadata as md

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting check_ex_ms_mapping.py", flush=True)

    # Load config data
    config = snakemake.config
    ex_ms_sample_map = md.get_ex_to_ms_sample_map(config)
    ex_donor_id_map = md.get_ex_to_donor_id_map(config)
    ms_donor_id_map = md.get_ms_to_donor_id_map(config)

    mismatches = {
        "donor_id": {},
        "age": {},
        "ms_sample_type": {}
    }

    for ex_sample, ms_sample in ex_ms_sample_map.items():
        # Look up values from both metadata tables
        donor_ex = ex_donor_id_map[ex_sample]
        donor_ms = ms_donor_id_map[ms_sample]

        # Check each field and record mismatches
        if donor_ex != donor_ms:
            mismatches["donor_id"][ms_sample] = (donor_ex, donor_ms)

    # After checking all samples, report any mismatches
    errors = {k: v for k, v in mismatches.items() if v}
    if errors:
        raise ValueError(f"Metadata mismatches found: {errors}")
    else:
        print("✅ All donor_id values match in sample metadata files.", flush=True)

    with open(snakemake.output[0], "w") as f:
        f.write("✅ All donor_id values match in sample metadata files.\n")

    print("[INFO] Completed check_ex_ms_mapping.py", flush=True)

if __name__ == "__main__":
    main(snakemake)