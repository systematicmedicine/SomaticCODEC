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
from pathlib import Path
import pytest
import yaml
import tempfile

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(5)
]

def test_snakemake_dryrun():
     
    # Configure parameters
    project_root = Path(__file__).resolve().parent.parent
    snakefile = project_root / "Snakefile"

    # Create modified config.yaml with test parameters and file paths
    config = Path("config/config.yaml")
    with config.open("r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f)
    config_data["experiment_name"] = "dryrun"
    config_data["GRCh38_path"] = "tests/data/dryrun/GRCh38_Chr21_plus_stubs.fna"
    config_data["difficult_regions_path"] = "tests/data/dryrun/GRCh38_alldifficultregions_10lines.bed"
    config_data["common_variants_path"] = "tests/data/dryrun/nanoseq_trinucleotide_contexts.csv"
    config_data["ex_nanoseq_tri_contexts"] = "tests/data/dryrun/nanoseq_trinucleotide_contexts.csv"

    test_config_file = tempfile.NamedTemporaryFile(delete=False, suffix=".yaml")
    with open(test_config_file.name, "w") as f:
        yaml.safe_dump(config_data, f)
    
    # Create snakemake command
    cmd = [
        "snakemake",
        "--dryrun",
        "--quiet",
        "--snakefile", str(snakefile),
        "--configfile", test_config_file.name,
    ]

    # Run snakemake command
    result = subprocess.run(cmd, capture_output=True, text=True)

    # Assert dryrun was sucessful
    assert result.returncode == 0, (
        f"Snakemake dryrun failed:\n"
        f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
    )