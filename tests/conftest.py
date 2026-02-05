"""
--- conftest.py ---

Functions and fixtures for pytest to use across test functions.

Authors: 
    - Joshua Johnstone
    - Cameron Fraser

"""
import pytest
import sys
from pathlib import Path
import shutil
import subprocess
import yaml
import tempfile

# Find the root directory of the project
def find_project_root(start: Path) -> Path:
    start = start.resolve()
    for p in [start, *start.parents]:
        # Use multiple sentinels to avoid false-positives
        if (p / "config").is_dir() and (p / "helpers").is_dir() and (p / "scripts").is_dir():
            return p
    raise RuntimeError("Could not find repo root (config/, helpers/, scripts/).")

# Insert PROJECT_ROOT into path
PROJECT_ROOT = find_project_root(Path(__file__))
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

# Explicit public API of PROJECT_ROOT
__all__ = ["PROJECT_ROOT"]

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
        root = PROJECT_ROOT / folder
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
    pytest_cache = PROJECT_ROOT / ".pytest_cache"
    if pytest_cache.exists():
        shutil.rmtree(pytest_cache)

# Runs a small dataset through the snakemake pipeline to generate files for testing
@pytest.fixture(scope = "session")
def lightweight_test_run():
    
    # Clean test environment
    clean_workspace()
    
    # Copy test files to tmp/downloads
    src_dir = PROJECT_ROOT / "tests/data/lightweight_test_run/downloads"
    dst_dir = PROJECT_ROOT /"tmp/downloads"
    dst_dir.mkdir(exist_ok=True)

    files_to_copy = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]

    for file_path in files_to_copy:
        shutil.copy2(src_dir / file_path.name, dst_dir / file_path.name)

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
    test_config_file = tempfile.NamedTemporaryFile(delete=False, suffix=".yaml")
    with open(test_config_file.name, "w") as f:
        yaml.safe_dump(config_data, f)

    # Log file setup
    log_dir = PROJECT_ROOT / "logs/bin_scripts"
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "run_pipeline.log"
    
    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "--snakefile", str(PROJECT_ROOT / "Snakefile"),
        "--configfile", test_config_file.name,
        "--cores", "all",
        "--notemp",
    ]

    try:
        with log_file.open("w", encoding="utf-8") as log:
            result = subprocess.run(
                snakemake_cmd,
                cwd=str(PROJECT_ROOT),
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

    # Temp file cleanup
    Path(test_config_file.name).unlink(missing_ok=True)

    # Cleanup test environment
    clean_workspace()