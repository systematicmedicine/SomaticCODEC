# ================================================================================
# check_configs.py
#
# Checks that the pipeline configs are formatted correctly
#
# Authors:
#   - Cameron Fraser
#   - Chat-GPT
#
# ================================================================================

# --------------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------------

# Load libraries
from pathlib import Path
import pandas as pd
import yaml
import sys
import subprocess

# Define reference files (dotted keys into config)
REFERENCE_FILES = [
    "sci_params.global.reference_genome",
    "sci_params.global.reference_tri_contexts",
    "sci_params.global.known_germline_variants",
    "sci_params.global.precomputed_masks",  # list-valued
]

# Define sample FASTQ files from metadata tables
SAMPLE_FILES = {
    "ex_lanes_metadata": ["fastq1", "fastq2"],
    "ms_samples_metadata": ["fastq1", "fastq2"],
}

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

# Check download list contains required files
def check_download_list(config: dict, metadata: dict):
    """Check that all required files are listed in download_list.csv."""
    expected = set()

    # FASTQs from metadata
    for table, cols in SAMPLE_FILES.items():
        for col in cols:
            expected |= set(metadata[table][col])

    # Reference files from config
    for key in REFERENCE_FILES:
        val = get_config_value(config, key)
        expected |= set(val) if isinstance(val, list) else {val}

    # Files listed for download
    dl_df = metadata["download_list"]
    listed = set(dl_df["destination_dir"].str.rstrip("/") + "/" + dl_df["file_name"])

    missing = expected - listed
    if missing:
        sys.exit(f"[ERROR] Missing files in download_list.csv:\n" + "\n".join(sorted(missing)))

    print("[INFO] All required files are present in download_list.csv")

# Check that checksums are valid md5sums
def check_download_list_md5sums(metadata: dict):
    
    dl_df = metadata["download_list"]
    if "expected_md5sum" not in dl_df.columns:
        sys.exit("[ERROR] expected_md5sum column missing from download_list.csv")

    invalid = dl_df["expected_md5sum"].isna() | ~dl_df["expected_md5sum"].astype(str).str.match(r"^[0-9a-f]{32}$")
    if invalid.any():
        bad = dl_df.loc[invalid, ["destination_dir", "file_name", "expected_md5sum"]]
        sys.exit("[ERROR] Invalid or missing MD5 checksums:\n" + bad.to_string(index=False))

    print("[INFO] All expected_md5sum entries are present and valid")

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

# Check each ex_sample and ex_technical_control has a valid ex_lane defined in ex_lanes.csv
def check_ex_lane_mapping(metadata: dict):

    ex_sample_lanes = set(metadata["ex_samples_metadata"]["ex_lane"])
    ex_tc_lanes = set(metadata["ex_technical_controls_metadata"]["ex_lane"])
    valid_lanes = set(metadata["ex_lanes_metadata"]["ex_lane"])

    missing = (ex_sample_lanes | ex_tc_lanes) - valid_lanes
    if missing:
        sys.exit(f"[ERROR] ex_lane(s) in ex_samples.csv or ex_technical_controls.csv not found in ex_lanes.csv:\n"
                 + "\n".join(sorted(missing)))

    print("[INFO] All ex_samples and ex_technical_controls map to valid ex_lanes")

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

# Check that all S3 URIs in download_list.csv exist
def check_s3_files_exist(metadata: dict):
    dl = metadata["download_list"]

    for _, row in dl.iterrows():
        s3_uri = row["source_dir"].rstrip("/") + "/" + row["file_name"]

        if not s3_uri.startswith("s3://"):
            sys.exit(f"[ERROR] Invalid S3 URI (must start with s3://): {s3_uri}")

        try:
            bucket, key = s3_uri[5:].split("/", 1)  # strip "s3://", split once
        except ValueError:
            sys.exit(f"[ERROR] Malformed S3 URI: {s3_uri}")

        try:
            subprocess.run(
                ["aws", "s3api", "head-object", "--bucket", bucket, "--key", key],
                check=True, capture_output=True
            )
        except subprocess.CalledProcessError:
            sys.exit(f"[ERROR] Missing S3 object: {s3_uri}")

    print("[INFO] All S3 objects in download_list.csv exist")

# Check that run_name has been set
def check_run_name_set(config: dict):
    if config["run_name"] == "experiment_1":
        sys.exit(f"[ERROR] run_name has not been set, currently default value")

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
    
    # Check download list contains required files 
    check_download_list(config, metadata_tables)

    # Check that checksums are valid md5sums
    check_download_list_md5sums(metadata_tables)

    # Check each ex_sample is mapped to an ms_sample with the same donor_id
    check_ex_ms_mapping(metadata_tables)

    # Check each ex_adapter in ex_samples exists in ex_adapters
    check_ex_adapters_exist(metadata_tables)

    # Check ex_adapter sequences contain only A/T/C/G and have expected length
    check_ex_adapter_sequences(metadata_tables, EXPECTED_ADAPTER_LENGTHS)

    # Check each ex_sample and ex_technical_control has a valid ex_lane defined in ex_lanes.csv
    check_ex_lane_mapping(metadata_tables)

    # Check that input FASTQs are globally unique
    check_input_fastqs_unique(metadata_tables)

    # Check that all S3 URIs in download_list.csv exist
    check_s3_files_exist(metadata_tables)

    # Check that run_name has been set
    check_run_name_set(config)