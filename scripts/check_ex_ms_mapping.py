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
    print("[INFO] Starting check_ex_ms_mapping.py")

    # Load config data
    config = snakemake.config
    ex_ms_sample_map = md.get_ex_to_ms_sample_map(config)
    ex_donor_id_map = md.get_ex_to_donor_id_map(config)
    ms_donor_id_map = md.get_ms_to_donor_id_map(config)
    ex_age_map = md.get_ex_to_age_map(config)
    ms_age_map = md.get_ms_to_age_map(config)
    ms_sample_type_map = md.get_ms_to_sample_type_map(config)
    ms_sample_type_in_ex_samples_csv_map = md.get_ms_to_sample_type_in_ex_samples_csv_map(config)

    mismatches = {
        "donor_id": {},
        "age": {},
        "ms_sample_type": {}
    }

    for ex_sample, ms_sample in ex_ms_sample_map.items():
        # Look up values from both metadata tables
        donor_ex = ex_donor_id_map[ex_sample]
        donor_ms = ms_donor_id_map[ms_sample]

        age_ex = ex_age_map[ex_sample]
        age_ms = ms_age_map[ms_sample]

        sample_type_ms = ms_sample_type_map[ms_sample]
        sample_type_ms_in_ex_samples_csv = ms_sample_type_in_ex_samples_csv_map[ms_sample]

        # Check each field and record mismatches
        if donor_ex != donor_ms:
            mismatches["donor_id"][ms_sample] = (donor_ex, donor_ms)

        if age_ex != age_ms:
            mismatches["age"][ms_sample] = (age_ex, age_ms)

        if sample_type_ms != sample_type_ms_in_ex_samples_csv:
            mismatches["ms_sample_type"][ms_sample] = (sample_type_ms, sample_type_ms_in_ex_samples_csv)

    # After checking all samples, report any mismatches
    errors = {k: v for k, v in mismatches.items() if v}
    if errors:
        raise ValueError(f"Metadata mismatches found: {errors}")
    else:
        print("✅ All donor_id, age, and sample_type values match in config files.")

    with open(snakemake.output[0], "w") as f:
        f.write("check_ex_ms_mapping completed successfully\n")

    print("[INFO] Completed check_ex_ms_mapping.py")

if __name__ == "__main__":
    main(snakemake)