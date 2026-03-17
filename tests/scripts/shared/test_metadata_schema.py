"""
--- test_metadata_schema.py ---

Check that the schema (header row) of the user-facing metadata templates
matches the schema used in CI metadata.

Authors:
    - Cameron Fraser
"""

from pathlib import Path
import csv
import pytest

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(5)
]

# Adjust these two roots to match your repo layout
TEMPLATE_DIR = Path("config")          
CI_METADATA_DIR = Path("tests/data/lightweight_test_run/config")

# List the 5 metadata filenames (must exist in both dirs)
METADATA_FILES = [
    "download_list.csv",
    "ex_samples.csv",
    "ex_lanes.csv",
    "ex_adapters.csv",
    "ms_samples.csv"
]

def read_header_row(csv_path: Path) -> list[str]:
    """
    Return the header row exactly as stored, but normalized slightly:
    - strip whitespace around column names
    - preserve order
    """
    with csv_path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader, None)
    if header is None:
        raise AssertionError(f"{csv_path} is empty (no header row).")
    return [h.strip() for h in header]

@pytest.mark.parametrize("filename", METADATA_FILES)
def test_check_metadata_schema(filename):
    template_path = TEMPLATE_DIR / filename
    ci_path = CI_METADATA_DIR / filename

    assert template_path.exists(), f"Missing template CSV: {template_path}"
    assert ci_path.exists(), f"Missing CI CSV: {ci_path}"

    template_header = read_header_row(template_path)
    ci_header = read_header_row(ci_path)

    assert template_header == ci_header, (
        f"Metadata schema mismatch for {filename}\n\n"
        f"Template: {template_path}\n"
        f"CI:       {ci_path}\n\n"
        f"Template header ({len(template_header)}): {template_header}\n"
        f"CI header       ({len(ci_header)}): {ci_header}\n"
    )
