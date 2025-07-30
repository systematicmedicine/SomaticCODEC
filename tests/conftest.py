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
    
    # Setup test environment
    clean_workspace()
    
    src_dir = Path("tests/data/lightweight_test_run")
    dst_dir = Path("tmp/downloads")
    dst_dir.mkdir(exist_ok=True)

    files_to_copy = [
        "GRCh38_Chr21_plus_stubs.fna",
        "S004_Chr21_10000reads_r1.fastq.gz",
        "S004_Chr21_10000reads_r2.fastq.gz",
        "S005_Chr21_10000reads_r1.fastq.gz",
        "S005_Chr21_10000reads_r2.fastq.gz",
        "GRCh38_alldifficultregions_10lines.bed",
        "gnomad_common_af01_merged_10lines.bed",
        "ex_lane1_Chr21_10000reads_r1.fastq.gz",
        "ex_lane1_Chr21_10000reads_r2.fastq.gz",
        "ex_lane2_Chr21_5000reads_r1.fastq.gz",
        "ex_lane2_Chr21_5000reads_r2.fastq.gz",
        "nanoseq_trinucleotide_contexts.csv"
        ]

    for filename in files_to_copy:
        shutil.copy2(src_dir / filename, dst_dir / filename)

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "--snakefile", "Snakefile",
        "--configfile", "tests/configs/lightweight_test_run/config.yaml",
        "--cores", "all",
        "--notemp",
    ]

    result = subprocess.run(snakemake_cmd, capture_output = True)
    if result.returncode != 0:
        raise RuntimeError("Pipeline failed:\n" + result.stderr.decode())

    # Yield control to the test
    yield

    # Cleanup test environmnt
    clean_workspace()

