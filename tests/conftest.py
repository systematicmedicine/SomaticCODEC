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

# Recursively update dict 'base' with values from dict 'override'. Nested dicts are merged; other values are replaced.
def deep_update(base: dict, override: dict) -> dict:
    if override is None:
        return base
    for k, v in override.items():
        if isinstance(v, dict) and isinstance(base.get(k), dict):
            deep_update(base[k], v)
        else:
            base[k] = v
    return base

# Deletes all files from metrics, results, logs, tmp and .snakemake directories
def clean_workspace():
    for folder in ["metrics", "results", "tmp", "logs", ".snakemake"]:
        root = Path(folder)
        if not root.exists():
            continue
        # Delete all files except .gitkeep
        for file in root.rglob("*"):
            if file.is_file() and file.name != ".gitkeep":
                try:
                    file.unlink()
                except FileNotFoundError:
                    pass
        # Remove directories that do not contain .gitkeep
        for dir_path in sorted(root.rglob("*"), key=lambda p: len(p.parts), reverse=True):
            if dir_path.is_dir():
                if not any(f.name == ".gitkeep" for f in dir_path.iterdir()):
                    try:
                        shutil.rmtree(dir_path)
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

    test_data_folder = Path("tests/data/lightweight_test_run")
    files_to_copy = [f for f in test_data_folder.glob("*") if f.name != ".gitkeep"]

    for file_path in files_to_copy:
        shutil.copy2(src_dir / file_path.name, dst_dir / file_path.name)

    # Load base config
    with Path("config/config.yaml").open("r", encoding="utf-8") as f:
        config_data = yaml.safe_load(f) or {}

    # Merge in config.dev.yaml (if present)
    dev_config = Path("config/config.dev.yaml")
    if dev_config.exists():
        with dev_config.open("r", encoding="utf-8") as f:
            dev_data = yaml.safe_load(f) or {}
        config_data = deep_update(config_data, dev_data)

    # Write merged config to temp file
    test_config_file = tempfile.NamedTemporaryFile(delete=False, suffix=".yaml")
    with open(test_config_file.name, "w") as f:
        yaml.safe_dump(config_data, f)

    # Log file setup
    log_dir = Path("logs/bin_scripts")
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "run_pipeline.log"
    
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

    # Run tests and pass test config path to test functions
    yield {"test_config_path": test_config_file.name}

    # Cleanup test environment
    clean_workspace()

