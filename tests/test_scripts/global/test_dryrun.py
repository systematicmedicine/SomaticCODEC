"""
--- test_dryrun.py

Runs a snakemake dry run

Authors:
    - Cameron Fraser
    - Chat-GPT
    - Joshua Johnstone
"""

# Import libraries
import subprocess
import pytest
import yaml
import tempfile
from pathlib import Path

from conftest import PROJECT_ROOT, clean_workspace, deep_update

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(6)
]


def test_snakemake_dryrun():
    # Clean test environment
    clean_workspace()

    # PSnakefile path
    snakefile = PROJECT_ROOT / "Snakefile"

    # Create empty test files in tmp/downloads
    src_dir = PROJECT_ROOT / "tests" / "data" / "lightweight_test_run" / "downloads"
    dst_dir = PROJECT_ROOT / "tmp" / "downloads"
    dst_dir.mkdir(exist_ok=True, parents=True)

    files_to_create = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]
    for src in files_to_create:
        (dst_dir / src.name).touch()

    # Load base config
    with Path(PROJECT_ROOT, "config/config.yaml").open("r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f) or {}

    # Merge in config.dev.yaml (if present)
    dev_config = PROJECT_ROOT / "config/config.dev.yaml"
    if dev_config.exists():
        with dev_config.open("r", encoding="utf-8") as f:
            dev_data = yaml.safe_load(f) or {}
        config_data = deep_update(config_data, dev_data)

    # Write merged config to temp file
    with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".yaml") as tf:
        yaml.safe_dump(config_data, tf, sort_keys=False)
        test_config_path = tf.name
    
    try:
        # Create snakemake command
        cmd = [
            "snakemake",
            "--dryrun",
            "--quiet",
            "--snakefile", str(snakefile),
            "--configfile", test_config_path,
        ]

        # Run snakemake command from repo root (more deterministic)
        result = subprocess.run(cmd, cwd=str(PROJECT_ROOT), capture_output=True, text=True)

        # Assert dryrun was successful
        assert result.returncode == 0, (
            f"Snakemake dryrun failed:\n"
            f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        )
    finally:
        Path(test_config_path).unlink(missing_ok=True)
        clean_workspace()
