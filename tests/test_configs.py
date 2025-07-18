"""
--- test_configs.py ---

Tests config files
    - Searches for all files named config.yaml
    - Checks that they all contain the same parameters
    - Checks that they have key values (e.g. metadata CSVs)

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

import pytest
import yaml
from pathlib import Path

# --- CONFIG ---

PROJECT_ROOT = Path(__file__).resolve().parent.parent
EXPECTED_KEYS = [
    "ex_samples_path",
    "ex_lanes_path",
    "ex_adapters_path",
    "ms_samples_path"
]

def get_all_config_paths():
    """Find all config.yaml files under PROJECT_ROOT."""
    config_paths = list(PROJECT_ROOT.rglob("config.yaml"))
    if not config_paths:
        pytest.fail("No config.yaml files found under project root.")
    return config_paths


# --- TESTS ---

@pytest.mark.parametrize("config_path", get_all_config_paths())
def test_config_is_valid_yaml(config_path):
    """Test that each config file is valid YAML."""
    try:
        with config_path.open() as f:
            yaml.safe_load(f)
    except yaml.YAMLError as e:
        pytest.fail(f"{config_path} is not valid YAML:\n{e}")


def test_config_keys_are_consistent():
    """Test that all config files contain the same keys."""
    config_paths = get_all_config_paths()
    key_sets = []

    for path in config_paths:
        with path.open() as f:
            config = yaml.safe_load(f)
            key_sets.append(set(config.keys()))

    first = key_sets[0]
    for i, key_set in enumerate(key_sets[1:], start=1):
        missing = first.symmetric_difference(key_set)
        assert not missing, (
            f"Mismatch in config keys between files:\n"
            f"{config_paths[0]} vs {config_paths[i]}\n"
            f"Differences: {missing}"
        )


@pytest.mark.parametrize("config_path", get_all_config_paths())
def test_config_required_paths_exist(config_path):
    """Test that expected path parameters are present and resolve to existing files."""
    with config_path.open() as f:
        config = yaml.safe_load(f)

    for key in EXPECTED_KEYS:
        assert key in config, f"{key} missing from config file: {config_path}"

        file_path = PROJECT_ROOT / config[key]
        assert file_path.exists(), f"File path for {key} does not exist: {file_path}"
