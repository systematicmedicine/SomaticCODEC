"""
--- test_expected_files_nonempty.py ---

1. Tests that all expected files are created
2. Tests that all expected files contain atleast one datapoint

For each file, the file type is determined from the file extenstion

Authors:
    - Cameron Fraser
    - Joshua Johnstone

"""

import sys
import pytest
from pathlib import Path
from scripts.get_metadata import load_config, get_ms_sample_ids, get_ex_lane_ids, get_ex_sample_ids
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from utils.count_data_points import count_data_points

pytestmark = pytest.mark.order(7)

""" (1) Test that all expected files exist"""
def test_expected_outputs_exist(lightweight_test_run, expected_files_list):

    for path in expected_files_list:
        assert Path(path).exists(), f"{path} does not exist"


""" (2) Test that all expected files have a non zero size on disk """
def test_expected_outputs_nonzero_size(lightweight_test_run, expected_files_list):

    for path in expected_files_list:
        assert Path(path).stat().st_size > 0, f"File is empty: {path}"


""" (3) Test that all expected files contain atleast one datapoint """
def test_expected_outputs_have_datapoints(lightweight_test_run, expected_files_list):

    # Omit certain file types from this check
    file_exts_to_omit = [".amb", ".ann", ".pac", ".0123", ".64", ".fai", ".dict", ".html", ".pdf", ".json", ".zip", ".bai", ".tbi", ".png"]
    expected_files_list = [path for path in expected_files_list if not any(path.endswith(ext) for ext in file_exts_to_omit)]

    # For remaining files, check number of datapoints > 0
    for path in expected_files_list:
        datapoints = count_data_points(path)
        assert datapoints > 0, f"No data points found in: {path}"


""" (4) Test if any unexpected files were created in tmp, metrics or results """
def test_no_unexpected_outputs(lightweight_test_run, expected_files_list):

    # Normalize expected files as Path objects
    expected_set = {Path(f) for f in expected_files_list}

    # Output directories to check
    output_dirs = ["tmp", "metrics", "results"]

    actual_files = set()
    for base in output_dirs:
        for path in Path(base).rglob("*"):
            if path.is_file():
                # Skip files under tmp/downloads/
                if "tmp/downloads" in str(path):
                    continue
                # Skip .gitkeep files
                if path.name == ".gitkeep":
                    continue
                actual_files.add(path)

    # Find files that aren't expected
    unexpected = actual_files - expected_set

    assert not unexpected, (
        "Unexpected files were created:\n" +
        "\n".join(str(p) for p in sorted(unexpected))
    )


""" (Fixture) Load list of expected files, and expand with sample wildcards """
@pytest.fixture(scope="module")
def expected_files_list():
    
    # Load lists of expected files (generic wildcards)
    source_files = [
        "tests/expected/expected_tmp_files.txt",
        "tests/expected/expected_metrics_files.txt",
        "tests/expected/expected_results_files.txt"
    ]
    expected_files_generic = sum([Path(f).read_text().splitlines() for f in source_files], [])

    # Load sample IDs
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ms_samples = get_ms_sample_ids(config)
    ex_lanes = get_ex_lane_ids(config)
    ex_samples = get_ex_sample_ids(config)

    # Expand wildcards
    expected_files_expanded = []
    for path_str in expected_files_generic:
        if "{ms_sample}" in path_str:
            expected_files_expanded += [path_str.format(ms_sample=s) for s in ms_samples]
        elif "{ex_lane}" in path_str:
            expected_files_expanded += [path_str.format(ex_lane=s) for s in ex_lanes]
        elif "{ex_sample}" in path_str:
            expected_files_expanded += [path_str.format(ex_sample=s) for s in ex_samples]
        else:
            expected_files_expanded.append(path_str)
    
    return expected_files_expanded