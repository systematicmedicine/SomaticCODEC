"""
--- test_dryrun.py

Runs a snakemake dry run
    - Uses the Snakefile located in project root
    - Uses the config files defined in /tests/configs/dryrun
    - Config files point to dummy files located in /tests/data/dryrun

Authors:
    - Cameron Fraser
    - Chat-GPT
"""

# Import libraries
import subprocess
from pathlib import Path
import pytest

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(4)
]

def test_snakemake_dryrun():
     
    # Configure parameters
    project_root = Path(__file__).resolve().parent.parent
    snakefile = project_root / "Snakefile"
    configfile = project_root / "tests" / "configs" / "dryrun" / "config.yaml"
    
    # Create snakemake command
    cmd = [
        "snakemake",
        "--dryrun",
        "--quiet",
        "--snakefile", str(snakefile),
        "--configfile", str(configfile),
    ]

    # Run snakemake command
    result = subprocess.run(cmd, capture_output=True, text=True)

    # Assert dryrun was sucessful
    assert result.returncode == 0, (
        f"Snakemake dryrun failed:\n"
        f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}"
    )