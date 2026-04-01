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
import yaml
from tests.conftest import PROJECT_ROOT, TEST_CONFIG
from tests.helpers.clean_workspace import clean_workspace

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(7)
]

def test_snakemake_dryrun(tmp_path_factory):
    # Clean test environment
    clean_workspace(PROJECT_ROOT)

    # Snakefile path
    snakefile = PROJECT_ROOT / "Snakefile"

    # Create empty test files in tmp/downloads
    src_dir = PROJECT_ROOT / "tests" / "data" / "lightweight_test_run" / "downloads"
    dst_dir = PROJECT_ROOT / "tmp" / "downloads"
    dst_dir.mkdir(exist_ok=True, parents=True)

    files_to_create = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]
    for src in files_to_create:
        (dst_dir / src.name).touch()

    # Write merged config to temp file
    test_tmp_dir = tmp_path_factory.mktemp("test_dir")
    test_config_file = test_tmp_dir / "merged_config.yaml"
    with open(test_config_file, "w", encoding="utf-8") as f:
        yaml.safe_dump(TEST_CONFIG, f)

    try:
        # Create snakemake command
        cmd = [
            "snakemake",
            "--dryrun",
            "--quiet",
            "--snakefile", str(snakefile),
            "--configfile", test_config_file,
        ]

        # Run snakemake command from repo root (more deterministic)
        result = subprocess.run(cmd, cwd=str(PROJECT_ROOT), capture_output=True, text=True)

        # Assert dryrun was successful
        assert result.returncode == 0, (
            f"Snakemake dryrun failed:\n"
            f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        )
    finally:
        clean_workspace(PROJECT_ROOT)
