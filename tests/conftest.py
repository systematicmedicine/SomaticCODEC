"""
--- conftest.py ---

Functions and fixtures for pytest to use across test functions.

Author: Joshua Johnstone

"""
from pathlib import Path
import shutil
import pytest

# Deletes all files except for .gitkeep from metrics, results, and tmp folders
def clean_workspace():
    for folder in ["metrics", "results", "tmp"]:
        path = Path(folder)
        for item in path.iterdir():
            if item.name != ".gitkeep":
                if item.is_dir():
                    shutil.rmtree(item)
                else:
                    item.unlink()

# Runs clean_workspace function before and after test
@pytest.fixture
def clean_workspace_fixture():

    clean_workspace()

    yield

    clean_workspace()   