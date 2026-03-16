"""
--- check_sample_metadata.py ---

Checks that the sample metadata sheets are configured correctly

Authors:
  - Cameron Fraser
  - Joshua Johnstone
  - Chat-GPT

"""

# --------------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------------

# Load libraries
from pathlib import Path
import pandas as pd
import yaml
import sys

# Define expected adapter lengths
EXPECTED_ADAPTER_LENGTHS = [18, 19]

# --------------------------------------------------------------------------------
# Helper functions
# --------------------------------------------------------------------------------

# Load metadata CSVs defined in config['metadata']
def load_metadata_tables(config: dict) -> dict[str, pd.DataFrame]:
    tables = {}
    for name, path in config.get("metadata", {}).items():
        path = Path(path)
        if path.suffix != ".csv":
            continue
        try:
            tables[name] = pd.read_csv(path, encoding="utf-8")
        except UnicodeDecodeError:
            tables[name] = pd.read_csv(path, encoding="latin1")
    return tables

# Helper function for getting values from config
def get_config_value(config: dict, dotted_key: str):
    val = config
    for key in dotted_key.split("."):
        val = val[key]
    return val

# Check that all sample-like IDs are globally unique
def check_sample_ids_unique(metadata: dict):
    """
    Ensures that all sample identifiers across the following fields are globally unique:
      - ex_samples_metadata["ex_sample"]
      - ex_lanes_metadata["ex_lane"]
      - ex_adapters_metadata["ex_adapter"]
      - ms_samples_metadata["ms_sample"]

    Exits with an error if any duplicates are found.
    """
    try:
        all_ids = pd.concat([
            metadata["ex_samples_metadata"]["ex_sample"],
            metadata["ex_lanes_metadata"]["ex_lane"],
            metadata["ex_adapters_metadata"]["ex_adapter"],
            metadata["ms_samples_metadata"]["ms_sample"],
        ], ignore_index=True).dropna()
    except KeyError as e:
        sys.exit(f"[ERROR] Missing key or column while checking sample ID uniqueness: {e}")

    duplicated = all_ids[all_ids.duplicated(keep=False)].unique()

    if len(duplicated) > 0:
        dup_list = "\n".join(sorted(duplicated))
        sys.exit(f"[ERROR] Duplicate sample identifiers found across metadata:\n{dup_list}")

    print("[INFO] All sample identifiers are globally unique")


# Check each ex_sample is mapped to an ms_sample with the same donor_id
def check_ex_ms_mapping(metadata: dict):
    ex = metadata["ex_samples_metadata"].set_index("ms_sample")
    ms = metadata["ms_samples_metadata"].set_index("ms_sample")

    merged = ex.join(ms["donor_id"], how="left", rsuffix="_ms")
    mismatched = merged["donor_id"] != merged["donor_id_ms"]

    if mismatched.any():
        bad = merged.loc[mismatched, ["donor_id", "donor_id_ms"]]
        sys.exit("[ERROR] ex_sample → ms_sample donor_id mismatch:\n" + bad.to_string())

    print("[INFO] ex_samples correctly map to ms_samples with matching donor_id")

# Check each ex_adapter in ex_samples exists in ex_adapters
def check_ex_adapters_exist(metadata: dict):
   
    sample_adapters = metadata["ex_samples_metadata"]["ex_adapter"].unique()
    defined_adapters = metadata["ex_adapters_metadata"]["ex_adapter"].unique()

    missing = set(sample_adapters) - set(defined_adapters)
    if missing:
        sys.exit(f"[ERROR] ex_adapter(s) not found in ex_adapters.csv:\n" + "\n".join(sorted(missing)))

    print("[INFO] All ex_adapters in ex_samples are defined in ex_adapters.csv")

# Check ex_adapter sequences contain only A/T/C/G and have expected length
def check_ex_adapter_sequences(metadata: dict, expected_lengths: list[int]):
    adapters = metadata["ex_adapters_metadata"]
    cols = ["r1_start", "r1_end", "r2_start", "r2_end"]

    for col in cols:
        seqs = adapters[col].dropna().astype(str)

        if not seqs.str.fullmatch(r"[ATCG]+").all():
            sys.exit(f"[ERROR] Invalid bases in {col}")

        if not seqs.str.len().isin(expected_lengths).all():
            sys.exit(f"[ERROR] Invalid lengths in {col} (allowed {expected_lengths})")

    print("[INFO] ex_adapter sequences are valid (A/T/C/G only, expected lengths)")

# Check each ex_sample has a valid ex_lane defined in ex_lanes.csv
def check_ex_lane_mapping(metadata: dict):

    ex_sample_lanes = set(metadata["ex_samples_metadata"]["ex_lane"])
    valid_lanes = set(metadata["ex_lanes_metadata"]["ex_lane"])

    missing = ex_sample_lanes - valid_lanes
    if missing:
        sys.exit(f"[ERROR] ex_lane(s) in ex_samples.csv not found in ex_lanes.csv:\n"
                 + "\n".join(sorted(missing)))

    print("[INFO] All ex_samples map to valid ex_lanes")

# Check that all input FASTQ paths are globally unique
def check_input_fastqs_unique(metadata: dict):
    """
    Ensures that all FASTQ paths across:
      - ms_samples_metadata: fastq1, fastq2
      - ex_lanes_metadata:   fastq1, fastq2
    are globally unique. Exits with an error if duplicates are found.
    """
    try:
        all_fastqs = pd.concat([
            metadata["ms_samples_metadata"]["fastq1"],
            metadata["ms_samples_metadata"]["fastq2"],
            metadata["ex_lanes_metadata"]["fastq1"],
            metadata["ex_lanes_metadata"]["fastq2"],
        ], ignore_index=True).dropna()
    except KeyError as e:
        sys.exit(f"[ERROR] Missing key or column while checking FASTQ uniqueness: {e}")

    duplicated = all_fastqs[all_fastqs.duplicated(keep=False)].unique()

    if len(duplicated) > 0:
        dup_list = "\n".join(sorted(duplicated))
        sys.exit(f"[ERROR] Duplicate FASTQ file paths found:\n{dup_list}")

    print("[INFO] All input FASTQ file paths are unique")

# Check that run_name has been set
def check_run_name_set(config: dict):
    if config["run_name"] == "experiment_1":
        sys.exit(f"[ERROR] run_name has not been set, currently default value")

# Check that ex_adapters are used only once per ex_lane
def check_adapters_used_once_per_lane(metadata: dict):

    df = metadata["ex_samples_metadata"]
    duplicates = df[df.duplicated(subset=["ex_lane", "ex_adapter"], keep=False)]
    
    if not duplicates.empty:
        msg_lines = [
            "[ERROR] The following ex_adapter(s) are used more than once within the same ex_lane:"
        ]
        for lane, group in duplicates.groupby("ex_lane"):
            adapters = ", ".join(sorted(group["ex_adapter"].unique()))
            msg_lines.append(f" Lane {lane}: {adapters}")
        sys.exit("\n".join(msg_lines))
    
    print("[INFO] Each ex_adapter is used only once per ex_lane")


# --------------------------------------------------------------------------------
# Main logic
# --------------------------------------------------------------------------------
if __name__ == "__main__":

    # EnsureCheck script is run from project root
    if not Path("config/config.yaml").is_file():
        sys.exit("[ERROR] Run this script from the project root (config/config.yaml not found)")
    
    # Load config.yaml
    with open("config/config.yaml") as f:
        config = yaml.safe_load(f)

    if config is None:
        sys.exit("[ERROR] config/config.yaml is empty or invalid")

    # Load metadata tables
    metadata_tables = load_metadata_tables(config)

    # Check that all sample IDs are globally unique
    check_sample_ids_unique(metadata_tables)

    # Check each ex_sample is mapped to an ms_sample with the same donor_id
    check_ex_ms_mapping(metadata_tables)

    # Check each ex_adapter in ex_samples exists in ex_adapters
    check_ex_adapters_exist(metadata_tables)

    # Check ex_adapter sequences contain only A/T/C/G and have expected length
    check_ex_adapter_sequences(metadata_tables, EXPECTED_ADAPTER_LENGTHS)

    # Check each ex_sample has a valid ex_lane defined in ex_lanes.csv
    check_ex_lane_mapping(metadata_tables)

    # Check that input FASTQs are globally unique
    check_input_fastqs_unique(metadata_tables)

    # Check that run_name has been set
    check_run_name_set(config)

    # Check that ex_adapters are used only once per ex_lane
    check_adapters_used_once_per_lane(metadata_tables)