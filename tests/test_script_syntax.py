"""
--- test_script_syntax.py

Tests scripts in the /scripts directory for syntax errors
    - Tests .py, .R and .sh scripts
    - Test fails if any scripts have other file extenstions

Authors:
    - Chat-GPT
    - Cameron Fraser

"""
import subprocess
import pytest
from pathlib import Path

# Allowed extensions
ALLOWED_EXTS = {".py", ".sh", ".R"}
EXEMPT_FILES = {".gitkeep"}

scripts_dir = Path(__file__).resolve().parent.parent / "scripts"

# Test for scripts with invalid exetnsions
def test_scripts_have_valid_extensions():
    for script_path in scripts_dir.rglob("*"):
        if script_path.is_file():
            if "__pycache__" in script_path.parts:
                continue  # skip all __pycache__ contents
            ext = script_path.suffix
            name = script_path.name
            if ext not in ALLOWED_EXTS and name not in EXEMPT_FILES:
                pytest.fail(f"Unexpected file in scripts/: {script_path}")

# Test Python scipts
@pytest.mark.parametrize("script_path", list(scripts_dir.rglob("*.py")))
def test_python_syntax(script_path):
    result = subprocess.run(
        ["python3", "-m", "py_compile", str(script_path)],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"Python syntax error in {script_path}:\n{result.stderr}"

# Test bash scripts
@pytest.mark.parametrize("script_path", list(scripts_dir.rglob("*.sh")))
def test_bash_syntax(script_path):
    result = subprocess.run(
        ["bash", "-n", str(script_path)],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"Bash syntax error in {script_path}:\n{result.stderr}"

# Test R scripts
@pytest.mark.parametrize("script_path", list(scripts_dir.rglob("*.R")))
def test_r_syntax(script_path):
    result = subprocess.run(
        ["Rscript", "-e", f"parse(file = '{script_path}')"],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"R syntax error in {script_path}:\n{result.stderr}"