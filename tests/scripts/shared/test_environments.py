"""
--- test_environments.py

Tests that all environment.yaml files have the same keys.

Authors:
    - Joshua Johnstone
"""

import pytest
from pathlib import Path
from tests.conftest import PROJECT_ROOT
from helpers.config_helpers import load_yaml, flatten_yaml_keys

pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(5)
]

def test_environment_yaml_keys():

    ENVIRONMENTS_DIR = Path(PROJECT_ROOT / "environments")
    environment_yaml_paths = [p / "environment.yaml" for p in ENVIRONMENTS_DIR.iterdir() if p.is_dir()]

    all_keys = [flatten_yaml_keys(load_yaml(f)) for f in environment_yaml_paths]

    # Assert that all environment.yaml files have the same keys
    first_yaml_keys = set(all_keys[0])
    for i, keys in enumerate(all_keys[1:], start=1):
        assert set(keys) == first_yaml_keys, "environment.yaml files have different keys:"
