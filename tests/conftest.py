"""
--- conftest.py ---

Functions and fixtures for pytest to use across test functions.

Authors: 
    - Joshua Johnstone
    - Cameron Fraser

"""
import pytest
from pathlib import Path
import shutil
import subprocess
from datetime import datetime
import yaml
import tempfile

# Deletes all files from metrics, results, logs, tmp and .snakemake directories
def clean_workspace():
    for folder in ["metrics", "results", "tmp", "logs", ".snakemake"]:
        path = Path(folder)
        # Skip if folder doesn't exist
        if not path.exists():
            continue  
        for item in path.iterdir():
            if item.name == ".gitkeep":
                continue
            try:
                if item.is_dir():
                    shutil.rmtree(item)
                else:
                    item.unlink()
            # Skip if item already deleted or missing
            except FileNotFoundError:
                pass

    # Delete .pytest_cache
    pytest_cache = Path(".pytest_cache")
    if pytest_cache.exists():
        shutil.rmtree(pytest_cache)

# Runs a small dataset through the snakemake pipeline to generate files for testing
@pytest.fixture(scope = "session")
def lightweight_test_run():
    
    # Clean test environment
    clean_workspace()
    
    # Copy test files to tmp/downloads
    src_dir = Path("tests/data/lightweight_test_run")
    dst_dir = Path("tmp/downloads")
    dst_dir.mkdir(exist_ok=True)

    files_to_copy = [
        "GRCh38_Chr21_plus_stubs.fa",
        "S004_Chr21_10000reads_r1.fastq.gz",
        "S004_Chr21_10000reads_r2.fastq.gz",
        "S005_Chr21_10000reads_r1.fastq.gz",
        "S005_Chr21_10000reads_r2.fastq.gz",
        "GRCh38_alldifficultregions_10lines.bed",
        "GRCh38-gnomad-variants-AF-0.01_10lines.bed",
        "GCRh38_repeat_masker_10lines.bed",
        "ex_lane1_Chr21_10000reads_r1.fastq.gz",
        "ex_lane1_Chr21_10000reads_r2.fastq.gz",
        "ex_lane2_Chr21_5000reads_r1.fastq.gz",
        "ex_lane2_Chr21_5000reads_r2.fastq.gz",
        "nanoseq_trinucleotide_contexts.csv",
        "gnomad-chr21-micro.vcf.bgz",
        "gnomad-chr21-micro.vcf.bgz.tbi"
        ]

    for filename in files_to_copy:
        shutil.copy2(src_dir / filename, dst_dir / filename)

    # Create modified config.yaml with test parameters and file paths
    config = Path("config/config.yaml")
    with config.open("r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f)

    config_data["experiment"]["name"] = "lightweight_test_run"

    config_data["resources"]["memory"]["heavy"] = 4
    config_data["resources"]["memory"]["moderate"] = 4
    config_data["resources"]["memory"]["light"] = 4
    config_data["resources"]["threads"]["heavy"] = 4
    config_data["resources"]["threads"]["moderate"] = 4
    config_data["resources"]["threads"]["light"] = 4

    config_data["chroms"]["variant_calling"] = ["chr21"]

    config_data["files"]["reference"] = "tmp/downloads/GRCh38_Chr21_plus_stubs.fa"
    config_data["files"]["common_masks"] = ["tmp/downloads/GRCh38_alldifficultregions_10lines.bed", 
                                            "tmp/downloads/GRCh38-gnomad-variants-AF-0.01_10lines.bed",
                                            "tmp/downloads/GCRh38_repeat_masker_10lines.bed"]
    config_data["files"]["ex_nanoseq_tri_contexts"] = "tmp/downloads/nanoseq_trinucleotide_contexts.csv"
    config_data["files"]["known_germline_variants"] = "tmp/downloads/gnomad-chr21-micro.vcf.bgz"

    config_data["rules"]["ms_low_depth_mask"]["threshold"] = 1

    test_config_file = tempfile.NamedTemporaryFile(delete=False, suffix=".yaml")
    with open(test_config_file.name, "w") as f:
        yaml.safe_dump(config_data, f)

    # Log file setup
    log_dir = Path("logs/pipeline")
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / f"pipeline_run_{datetime.now():%Y%m%d}.log"
    
    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "--snakefile", "Snakefile",
        "--configfile", test_config_file.name,
        "--cores", "all",
        "--notemp",
    ]

    try:
        with log_file.open("w", encoding="utf-8") as log:
            result = subprocess.run(
                snakemake_cmd,
                stdout=None,
                stderr=log, 
                text=True,
                check=False,
            )
    except FileNotFoundError as e:
        raise RuntimeError("Failed to launch Snakemake. Is it installed and on PATH?") from e

    if result.returncode != 0:
        raise RuntimeError(f"Pipeline failed — see log: {log_file}")

    # Yield control to the test
    yield

    # Cleanup test environment
    clean_workspace()

