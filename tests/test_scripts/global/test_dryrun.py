"""
--- test_dryrun.py

Runs a snakemake dry run
    - Uses the Snakefile located in project root
    - Uses the config files defined in /tests/configs/dryrun
    - Config files point to dummy files located in /tests/data/dryrun

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

from conftest import PROJECT_ROOT, clean_workspace

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(5)
]


def test_snakemake_dryrun():
    # Clean test environment
    clean_workspace()

    # Paths
    snakefile = PROJECT_ROOT / "Snakefile"

    # Create empty test files in tmp/downloads
    dst_dir = PROJECT_ROOT / "tmp" / "downloads"
    dst_dir.mkdir(exist_ok=True, parents=True)

    test_data_folder = PROJECT_ROOT / "tests" / "data" / "lightweight_test_run"
    files_to_create = [f for f in test_data_folder.glob("*") if f.name != ".gitkeep"]

    for src in files_to_create:
        (dst_dir / src.name).touch()

    # Create modified config.yaml with test parameters and file paths
    config_path = PROJECT_ROOT / "config" / "config.yaml"
    with config_path.open("r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f) or {}

    config_data["run_name"] = "dryrun"
    config_data["sci_params"]["global"]["reference_genome"] = "tmp/downloads/GRCh38_Chr21_plus_stubs.fa"
    config_data["sci_params"]["global"]["precomputed_masks"] = [
        "tmp/downloads/GRCh38_alldifficultregions_10lines.bed",
        "tmp/downloads/GRCh38-gnomad-variants-AF-0.01_10lines.bed",
        "tmp/downloads/GCRh38_repeat_masker_10lines.bed",
    ]
    config_data["sci_params"]["global"]["known_germline_variants"] = "tmp/downloads/gnomad-chr21-micro.vcf.bgz"

    # Write to temp config file
    test_config_file = tempfile.NamedTemporaryFile(delete=False, suffix=".yaml")
    try:
        Path(test_config_file.name).write_text(yaml.safe_dump(config_data), encoding="utf-8")

        # Create snakemake command
        cmd = [
            "snakemake",
            "--dryrun",
            "--quiet",
            "--snakefile", str(snakefile),
            "--configfile", test_config_file.name,
        ]

        # Run snakemake command from repo root (more deterministic)
        result = subprocess.run(cmd, cwd=str(PROJECT_ROOT), capture_output=True, text=True)

        # Assert dryrun was successful
        assert result.returncode == 0, (
            f"Snakemake dryrun failed:\n"
            f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
        )
    finally:
        Path(test_config_file.name).unlink(missing_ok=True)
        clean_workspace()
