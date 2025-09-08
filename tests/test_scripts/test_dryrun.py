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
import shutil
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from tests.conftest import clean_workspace

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(5)
]

def test_snakemake_dryrun():
    
    # Clean test environment
    clean_workspace()

    # Configure parameters
    snakefile = project_root / "Snakefile"

    # Copy test files to tmp/downloads
    src_dir = Path("tests/data/dryrun")
    dst_dir = Path("tmp/downloads")
    dst_dir.mkdir(exist_ok=True)

    files_to_copy = [
        "GRCh38_Chr21_plus_stubs.fa",
        "S004_Chr21_10000reads_r1_umi.fastq.gz",
        "S004_Chr21_10000reads_r2_umi.fastq.gz",
        "S005_Chr21_10000reads_r1_umi.fastq.gz",
        "S005_Chr21_10000reads_r2_umi.fastq.gz",
        "GRCh38_alldifficultregions_10lines.bed",
        "GRCh38-gnomad-variants-AF-0.01_10lines.bed",
        "GCRh38_repeat_masker_10lines.bed",
        "ex_lane1_Chr21_10000reads_r1.fastq.gz",
        "ex_lane1_Chr21_10000reads_r2.fastq.gz",
        "ex_lane2_Chr21_5000reads_r1.fastq.gz",
        "ex_lane2_Chr21_5000reads_r2.fastq.gz",
        "nanoseq_trinucleotide_contexts.csv",
        "gnomad-chr21-micro.vcf.bgz"
        ]

    for filename in files_to_copy:
        shutil.copy2(src_dir / filename, dst_dir / filename)

    # Create modified config.yaml with test parameters and file paths
    config = project_root / "config/config.yaml"
    with config.open("r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f)
    config_data["experiment"]["name"] = "dryrun"
    config_data["files"]["reference_genome"] = "tmp/downloads/GRCh38_Chr21_plus_stubs.fa"
    config_data["files"]["precomputed_masks"] = [
    "tmp/downloads/GRCh38_alldifficultregions_10lines.bed",
    "tmp/downloads/GRCh38-gnomad-variants-AF-0.01_10lines.bed",
    "tmp/downloads/GCRh38_repeat_masker_10lines.bed"]
    config_data["files"]["ex_nanoseq_tri_contexts"] = "tmp/downloads/nanoseq_trinucleotide_contexts.csv"
    config_data["files"]["known_germline_variants"] = "tmp/downloads/gnomad-chr21-micro.vcf.bgz"

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

    clean_workspace()