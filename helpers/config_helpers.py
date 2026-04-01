"""
--- config_helpers.py ---

Helpers for loading and combining pipeline configuration.

Authors:
    - Cameron Fraser
"""

from __future__ import annotations

from pathlib import Path
from copy import deepcopy
import yaml


def load_yaml(path: Path) -> dict:
    """
    Load a YAML file and return its contents as a dictionary.

    Empty YAML files are treated as empty dictionaries.
    """
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def deep_update(base: dict, override: dict) -> dict:
    """
    Recursively update dict 'base' with values from dict 'override'.

    Nested dictionaries are merged recursively.
    All other values are replaced by the override value.

    Returns the mutated 'base' dict.
    """
    if override is None:
        return base

    for key, value in override.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_update(base[key], value)
        else:
            base[key] = deepcopy(value)

    return base


def build_config(project_root: Path, environment_name: str, profile_name: str) -> dict:
    """
    Build the runtime config by merging an environment config and a profile config.

    Merge order:
        1. environments/<environment_name>/environment.yaml
        2. profiles/<profile_name>/profile.yaml

    Later values override earlier values.
    """
    environment_config = load_yaml(
        project_root / "environments" / environment_name / "environment.yaml"
    )
    profile_config = load_yaml(
        project_root / "profiles" / profile_name / "profile.yaml"
    )

    return deep_update(environment_config, profile_config)