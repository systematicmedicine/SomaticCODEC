"""
--- test_check_configs.py ---

Test that the script test_check_configs.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import sys
from pathlib import Path
import pytest
import yaml
import copy
from unittest.mock import patch

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

import bin.check_configs as cc

# Load defined expected adapter lengths
EXPECTED_ADAPTER_LENGTHS = cc.EXPECTED_ADAPTER_LENGTHS

# Load the config file and metadata tables yielded by lightweight test run
def load_test_config_metadata(lightweight_test_run):
     # Load test config
    with open(lightweight_test_run["test_config_path"]) as f:
            config = yaml.safe_load(f)

    # Load metadata tables
    metadata_tables = cc.load_metadata_tables(config)

    # Return a deep copy of metadata tables for modification
    return config, copy.deepcopy(metadata_tables)
    

# Tests the function check_download_list()
def test_check_download_list(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_download_list() passes with valid metadata
    assert cc.check_download_list(config, valid_metadata_tables) is None

    # Assertion 2: check_download_list() fails when a file is removed from the download list
    metadata_tables_incomplete_download_list = copy.deepcopy(valid_metadata_tables)
    metadata_tables_incomplete_download_list["download_list"] = metadata_tables_incomplete_download_list["download_list"].iloc[1:]
    with pytest.raises(SystemExit):
        cc.check_download_list(config, metadata_tables_incomplete_download_list)


# Tests the function check_download_list_md5sums()
def test_check_download_list_md5sums(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_download_list_md5sums() passes with valid metadata
    assert cc.check_download_list_md5sums(valid_metadata_tables) is None

    # Assertion 2: check_download_list_md5sums() fails when md5sum column is missing from download list
    metadata_tables_no_md5_column = copy.deepcopy(valid_metadata_tables)
    metadata_tables_no_md5_column["download_list"] = metadata_tables_no_md5_column["download_list"].drop(columns=["expected_md5sum"])
    with pytest.raises(SystemExit):
        cc.check_download_list_md5sums(metadata_tables_no_md5_column)

    # Assertion 3: check_download_list_md5sums() fails when an md5sum is missing
    metadata_tables_missing_md5 = copy.deepcopy(valid_metadata_tables)
    metadata_tables_missing_md5["download_list"].loc[0, "expected_md5sum"] = None
    with pytest.raises(SystemExit):
        cc.check_download_list_md5sums(metadata_tables_missing_md5)
    
    # Assertion 4: check_download_list_md5sums() fails when an md5sum is a non-hex string
    metadata_tables_non_hex_md5 = copy.deepcopy(valid_metadata_tables)
    metadata_tables_non_hex_md5["download_list"].loc[0, "expected_md5sum"] = "NONHEXMD5"
    with pytest.raises(SystemExit):
        cc.check_download_list_md5sums(metadata_tables_non_hex_md5)

    # Assertion 5: check_download_list_md5sums() fails when an md5sum is too short
    metadata_tables_short_md5 = copy.deepcopy(valid_metadata_tables)
    metadata_tables_short_md5["download_list"].loc[0, "expected_md5sum"] = "123abc"
    with pytest.raises(SystemExit):
        cc.check_download_list_md5sums(metadata_tables_short_md5)


# Tests the function check_ex_ms_mapping()
def test_check_ex_ms_mapping(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_ex_ms_mapping() passes with valid metadata
    assert cc.check_ex_ms_mapping(valid_metadata_tables) is None

    # Assertion 2: check_ex_ms_mapping() fails when the donor ID is incorrectly mapped
    metadata_tables_donor_mismap = copy.deepcopy(valid_metadata_tables)
    metadata_tables_donor_mismap["ex_samples_metadata"].loc[0, "donor_id"] = "R9999"
    with pytest.raises(SystemExit):
        cc.check_ex_ms_mapping(metadata_tables_donor_mismap)
    

# Tests the function check_ex_adapters_exist()
def test_check_ex_adapters_exist(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_ex_adapters_exist() passes with valid metadata
    assert cc.check_ex_adapters_exist(valid_metadata_tables) is None

    # Assertion 2: check_ex_adapters_exist() fails when an adapter is missing from ex_adapters.csv
    metadata_tables_missing_adapter = copy.deepcopy(valid_metadata_tables)
    metadata_tables_missing_adapter["ex_adapters_metadata"] = metadata_tables_missing_adapter["ex_adapters_metadata"].iloc[1:]
    with pytest.raises(SystemExit):
        cc.check_ex_adapters_exist(metadata_tables_missing_adapter)


# Tests the function check_ex_adapter_sequences()
def test_check_ex_adapter_sequences(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_ex_adapter_sequences() passes with valid metadata
    assert cc.check_ex_adapter_sequences(valid_metadata_tables, EXPECTED_ADAPTER_LENGTHS) is None

    # Assertion 2: check_ex_adapter_sequences() fails when adapters contain characters other than A/T/C/G
    metadata_tables_non_ATCG_adapter = copy.deepcopy(valid_metadata_tables)
    metadata_tables_non_ATCG_adapter["ex_adapters_metadata"].loc[0, "r1_start"] = "XYZGAACGGACTGTCCAC"
    with pytest.raises(SystemExit):
        cc.check_ex_adapter_sequences(metadata_tables_non_ATCG_adapter, EXPECTED_ADAPTER_LENGTHS)

    # Assertion 3: check_ex_adapter_sequences() fails when adapter lengths are invalid
    metadata_tables_short_adapter = copy.deepcopy(valid_metadata_tables)
    metadata_tables_short_adapter["ex_adapters_metadata"].loc[0, "r1_start"] = "CAC"
    with pytest.raises(SystemExit):
        cc.check_ex_adapter_sequences(metadata_tables_short_adapter, EXPECTED_ADAPTER_LENGTHS)


# Tests the function check_ex_lane_mapping()
def test_check_ex_lane_mapping(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_ex_lane_mapping() passes with valid metadata
    assert cc.check_ex_lane_mapping(valid_metadata_tables) is None

    # Assertion 2: check_ex_lane_mapping() fails when an ex_lane is missing from ex_lanes.csv
    metadata_tables_missing_lane = copy.deepcopy(valid_metadata_tables)
    metadata_tables_missing_lane["ex_lanes_metadata"] = metadata_tables_missing_lane["ex_lanes_metadata"].iloc[1:]
    with pytest.raises(SystemExit):
        cc.check_ex_lane_mapping(metadata_tables_missing_lane)


# Tests the function check_s3_files_exist()
# Mock subprocess.run to simulate S3 objects existing
def test_check_s3_files_exist(lightweight_test_run):
    config, valid_metadata_tables = load_test_config_metadata(lightweight_test_run)

    # Assertion 1: check_s3_files_exist() passes with valid metadata
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = None
        assert cc.check_s3_files_exist(valid_metadata_tables) is None

    # Assertion 2: check_s3_files_exist() fails when the S3 URI prefix is invalid
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = None
        metadata_tables_invalid_URI_prefix = copy.deepcopy(valid_metadata_tables)
        metadata_tables_invalid_URI_prefix["download_list"].loc[0, "source_dir"] = "http://not-s3-bucket"
        with pytest.raises(SystemExit):
            cc.check_s3_files_exist(metadata_tables_invalid_URI_prefix)

    # Assertion 3: check_s3_files_exist() fails when the S3 URI has no bucket
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = None
        metadata_tables_invalid_URI_no_bucket = copy.deepcopy(valid_metadata_tables)
        metadata_tables_invalid_URI_no_bucket["download_list"].loc[0, "source_dir"] = "s3://"
        with pytest.raises(SystemExit):
            cc.check_s3_files_exist(metadata_tables_invalid_URI_no_bucket)

    # Assertion 4: check_s3_files_exist() fails when the S3 URI is missing
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = None
        metadata_tables_no_URI = copy.deepcopy(valid_metadata_tables)
        metadata_tables_no_URI["download_list"].loc[0, "source_dir"] = ""
        with pytest.raises(SystemExit):
            cc.check_s3_files_exist(metadata_tables_no_URI)
