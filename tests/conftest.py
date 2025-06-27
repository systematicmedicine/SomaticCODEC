"""
--- conftest.py ---

Functions and fixtures for pytest to use across test functions.

Author: Joshua Johnstone

"""
from pathlib import Path
import shutil
import pytest

# Deletes all files except for .gitkeep from metrics, results, tmp and .snakemake folders
def clean_workspace():
    for folder in ["metrics", "results", "tmp", ".snakemake"]:
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

# Runs clean_workspace function before and after test
@pytest.fixture
def clean_workspace_fixture():

    clean_workspace()

    yield

    #clean_workspace()