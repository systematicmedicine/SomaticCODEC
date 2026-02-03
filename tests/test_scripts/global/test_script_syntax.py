"""
--- test_script_syntax.py

Tests scripts in the /scripts directory for syntax errors
    - Tests .py, .R and .sh scripts
    - Test fails if any scripts have other file extenstions

Authors:
    - Chat-GPT
    - Cameron Fraser

"""
# Import libraries
import subprocess
import pytest
from pathlib import Path
import pytest
from conftest import PROJECT_ROOT

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(2)
]

# Allowed extensions
ALLOWED_EXTS = {".py", ".sh", ".R"}
EXEMPT_FILES = {".gitkeep"}

# Directories to check
check_dirs = [
    PROJECT_ROOT / "scripts",
    PROJECT_ROOT / "helpers",
    PROJECT_ROOT / "tests/test_scripts",
    PROJECT_ROOT / "bin"
]

# Helper to collect files with optional extension filter
def collect_files(ext=None):
    files = []
    for base_dir in check_dirs:
        if base_dir.name == "tests":
            # Only top-level files in /tests
            contents = base_dir.glob(f"*{ext}" if ext else "*")
        else:
            contents = base_dir.rglob(f"*{ext}" if ext else "*")
        files.extend([f for f in contents if f.is_file() and "__pycache__" not in f.parts])
    return files

# Check for unexpected extensions
def test_scripts_have_valid_extensions():
    for path in collect_files():
        ext = path.suffix
        name = path.name
        if ext not in ALLOWED_EXTS and name not in EXEMPT_FILES:
            pytest.fail(f"Unexpected file type: {path}")

@pytest.mark.parametrize("script_path", collect_files(".py"))
def test_python_syntax(script_path):
    result = subprocess.run(
        ["python3", "-m", "py_compile", str(script_path)],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"Python syntax error in {script_path}:\n{result.stderr}"

@pytest.mark.parametrize("script_path", collect_files(".sh"))
def test_bash_syntax(script_path):
    result = subprocess.run(
        ["bash", "-n", str(script_path)],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"Bash syntax error in {script_path}:\n{result.stderr}"

@pytest.mark.parametrize("script_path", collect_files(".R"))
def test_r_syntax(script_path):
    result = subprocess.run(
        ["Rscript", "-e", f"parse(file = '{script_path}')"],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"R syntax error in {script_path}:\n{result.stderr}"
