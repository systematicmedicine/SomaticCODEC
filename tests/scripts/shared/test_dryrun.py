"""
--- test_dryrun.py

Runs a snakemake dry run

Authors:
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import libraries
import subprocess
import pytest
import shutil
from tests.conftest import PROJECT_ROOT, TEST_CONFIG_PATH
from tests.helpers.clean_workspace import clean_workspace
from tests.helpers.build_test_config import build_test_config

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(8)
]

# Bin script path
DRYRUN_BIN_SCRIPT = "bin/dryrun.sh"

def test_snakemake_dryrun():
    # Clean test environment
    clean_workspace(PROJECT_ROOT)

    # Create empty test files in tmp/downloads
    src_dir = PROJECT_ROOT / "tests" / "data" / "lightweight_test_run" / "downloads"
    dst_dir = PROJECT_ROOT / "tmp" / "downloads"
    dst_dir.mkdir(exist_ok=True, parents=True)

    files_to_create = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]
    for src in files_to_create:
        (dst_dir / src.name).touch()

    # Copy experiment metadata sheets to experiment/
    exp_src_dir = PROJECT_ROOT / "tests/data/lightweight_test_run/experiment"
    exp_dst_dir = PROJECT_ROOT / "experiment/"
    exp_dst_dir.mkdir(exist_ok=True)

    files_to_copy = [f for f in exp_src_dir.glob("*") if f.name != ".gitkeep"]

    for file_path in files_to_copy:
        shutil.copy2(exp_src_dir / file_path.name, exp_dst_dir / file_path.name)

    # Build test config using bin script
    build_test_config(PROJECT_ROOT, TEST_CONFIG_PATH)

    try:
        # Run dryrun bin script from repo root (more deterministic)
        cmd = ["bash", DRYRUN_BIN_SCRIPT]
        result = subprocess.run(cmd, cwd=str(PROJECT_ROOT), capture_output=True, text=True)

        # Assert dryrun was successful
        assert result.returncode == 0, (
            f"Snakemake dryrun failed:\n"
            f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        )
    finally:
        clean_workspace(PROJECT_ROOT)
