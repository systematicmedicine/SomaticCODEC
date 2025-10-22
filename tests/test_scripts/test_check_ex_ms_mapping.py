"""
--- test_check_ex_ms_mapping.py ---

Test that the script test_check_ex_ms_mapping.py can detect mismatches in donor ID between EX and MS metadata

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import pytest
from pathlib import Path
import sys
import yaml

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.check_ex_ms_mapping import main

@pytest.mark.parametrize(
    "config_file, expect_exit, expect_done, mismatch_ms_sample",
    [
        # All correct mapping
        ("tests/data/test_check_ex_ms_mapping/match_config.yaml", None, True, None),
        # Introduce a mismatch
        ("tests/data/test_check_ex_ms_mapping/mismatch_config.yaml", ValueError, False, "S004"),
    ]
)
def test_check_ex_ms_mapping(tmp_path, config_file, expect_exit, expect_done, mismatch_ms_sample):
    config_path = Path(config_file)

    # Temporary output and log files
    done_file = tmp_path / "check.done"
    log_file = tmp_path / "log.log"

    # Load YAML config
    with open(config_path) as f:
        config_data = yaml.safe_load(f)

    # Mock Snakemake object
    class FakeSnakemake:
        config = config_data
        output = [str(done_file)]
        log = [str(log_file)]

    # Run the script
    if expect_exit:
        with pytest.raises(expect_exit) as e:
            main(FakeSnakemake())
        # Check that the mismatched MS sample appears in the error message
        if mismatch_ms_sample:
            assert mismatch_ms_sample in str(e.value)
            assert "Metadata mismatches found" in str(e.value)
    else:
        main(FakeSnakemake())

    # Check done file existence
    assert done_file.exists() == expect_done

    # Check log contents in success case
    if expect_done:
        log_text = log_file.read_text()
        assert "All donor_id values match" in log_text
