"""
--- check_download_list_S3.py ---

Checks that the download list is configured correctly and that all files exist on S3

Authors:
  - Cameron Fraser
  - Joshua Johnstone

"""
# --------------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------------

# Load libraries
import sys
import subprocess
import pandas as pd
from pathlib import Path
import yaml

# Define reference files (dotted keys into config)
REFERENCE_FILES = [
    "sci_params.reference_files.genome",
    "sci_params.reference_files.precomputed_masks",
    "sci_params.reference_files.tri_contexts",
    "sci_params.reference_files.genome_trinuc_counts",
    "sci_params.reference_files.germline_variants", # list-valued
]

# Define sample FASTQ files from metadata tables
SAMPLE_FILES = {
    "ex_lanes_metadata": ["fastq1", "fastq2"],
    "ms_samples_metadata": ["fastq1", "fastq2"],
}

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

# --------------------------------------------------------------------------------
# Main logic
# --------------------------------------------------------------------------------
if __name__ == "__main__":

    # EnsureCheck script is run from project root
    if not Path("tmp/runtime_config/merged_config.yaml").is_file():
        sys.exit("[ERROR] tmp/runtime_config/merged_config.yaml not found. " \
        "Run this script from the project root, and ensure bin/create_runtime_config.py has been run first")
    
    # Load config.yaml
    with open("tmp/runtime_config/merged_config.yaml") as f:
        config = yaml.safe_load(f)

    if config is None:
        sys.exit("[ERROR] tmp/runtime_config/merged_config.yaml is empty or invalid")

    # Load metadata tables
    metadata_tables = load_metadata_tables(config)

    # Check download list contains required files 
    check_download_list(config, metadata_tables)

    # Check that checksums are valid md5sums
    check_download_list_md5sums(metadata_tables)

    # Check that all S3 URIs in download_list.csv exist
    check_s3_files_exist(metadata_tables)
