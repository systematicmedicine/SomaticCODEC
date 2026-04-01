"""
--- conftest.py ---

Functions and fixtures for pytest to use across test functions.

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

# ------------------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------------------
import sys
from pathlib import Path

def find_project_root(start: Path) -> Path:
    start = start.resolve()
    for p in [start, *start.parents]:
        # Use multiple sentinels to avoid false-positives
        if (p / "profiles").is_dir() and (p / "helpers").is_dir() and (p / "rule_scripts").is_dir():
            return p
    raise RuntimeError("Could not find repo root (profiles/, helpers/, rule_scripts/).")

# Insert PROJECT_ROOT into path
PROJECT_ROOT = find_project_root(Path(__file__))
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from helpers.config_helpers import build_config

# Build config
TEST_CONFIG = build_config(PROJECT_ROOT, "local-test", "test")

# ------------------------------------------------------------------------------------------
# Export variables
# ------------------------------------------------------------------------------------------

# Explicit public API of PROJECT_ROOT
__all__ = ["PROJECT_ROOT", "TEST_CONFIG"]

# ------------------------------------------------------------------------------------------
# Import fixtures
# ------------------------------------------------------------------------------------------

pytest_plugins = [
    "tests.fixtures.lightweight_test_run"
]