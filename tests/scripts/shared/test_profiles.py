"""
--- test_profiles.py

Tests that all profile.yaml files have the same keys.

Authors:
    - Joshua Johnstone
"""

import pytest
from pathlib import Path
from tests.conftest import PROJECT_ROOT
from helpers.config_helpers import load_yaml, flatten_yaml_keys

pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(6)
]

def test_profile_yaml_keys():

    PROFILE_DIR = Path(PROJECT_ROOT / "profiles")
    profile_yaml_paths = [p / "profile.yaml" for p in PROFILE_DIR.iterdir() if p.is_dir()]

    all_keys = [flatten_yaml_keys(load_yaml(f)) for f in profile_yaml_paths]

    # Assert that all profile.yaml files have the same keys
    first_yaml_keys = set(all_keys[0])
    for i, keys in enumerate(all_keys[1:], start=1):
        assert set(keys) == first_yaml_keys, "profile.yaml files have different keys:"
