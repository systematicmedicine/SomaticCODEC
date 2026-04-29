"""
--- dryrun.py ---

Snakemake dryrun fixture

Authors:
    - Cameron Fraser
"""

import shutil
import subprocess

import pytest

from tests.conftest import PROJECT_ROOT, TEST_CONFIG_PATH
from helpers.test_helpers import clean_workspace, build_test_config

DRYRUN_BIN_SCRIPT = "bin/dryrun.sh"


@pytest.fixture
def dryrun_fixture():
    """
    Prepare a clean test workspace, run a Snakemake dry run, and return the
    subprocess result.

    Fails the test immediately if the dry run is unsuccessful.
    """
    clean_workspace(PROJECT_ROOT)

    # Create empty test files in tmp/downloads
    src_dir = PROJECT_ROOT / "tests" / "data" / "lightweight_test_run" / "downloads"
    dst_dir = PROJECT_ROOT / "tmp" / "downloads"
    dst_dir.mkdir(exist_ok=True, parents=True)

    files_to_create = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]
    for src in files_to_create:
        (dst_dir / src.name).touch()

    # Copy experiment metadata sheets to experiment/
    exp_src_dir = PROJECT_ROOT / "tests" / "data" / "lightweight_test_run" / "experiment"
    exp_dst_dir = PROJECT_ROOT / "experiment"
    exp_dst_dir.mkdir(exist_ok=True, parents=True)

    files_to_copy = [f for f in exp_src_dir.glob("*") if f.name != ".gitkeep"]
    for file_path in files_to_copy:
        shutil.copy2(file_path, exp_dst_dir / file_path.name)

    # Build test config
    build_test_config(PROJECT_ROOT, TEST_CONFIG_PATH)

    # Run dryrun bin script from repo root
    cmd = ["bash", DRYRUN_BIN_SCRIPT]
    result = subprocess.run(
        cmd,
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, (
        f"Snakemake dryrun failed:\n"
        f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
    )

    yield result

    clean_workspace(PROJECT_ROOT)