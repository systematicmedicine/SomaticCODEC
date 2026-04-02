"""
--- lightweight_test_run.py ---

Runs a small dataset through the snakemake pipeline to generate files for testing.

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import pytest
import subprocess
import shutil
from tests.helpers.clean_workspace import clean_workspace
from tests.helpers.build_test_config import build_test_config
from tests.conftest import PROJECT_ROOT, TEST_CONFIG_PATH

# Bin script path
RUN_PIPELINE_BIN_SCRIPT = "bin/run_pipeline.py"

@pytest.fixture(scope="session")
def lightweight_test_run():

    # Clean test environment
    clean_workspace(PROJECT_ROOT)

    # Copy test files to tmp/downloads
    src_dir = PROJECT_ROOT / "tests/data/lightweight_test_run/downloads"
    dst_dir = PROJECT_ROOT / "tmp/downloads"
    dst_dir.mkdir(exist_ok=True)

    files_to_copy = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]

    for file_path in files_to_copy:
        shutil.copy2(src_dir / file_path.name, dst_dir / file_path.name)

    # Log file setup
    log_dir = PROJECT_ROOT / "logs/bin_scripts"
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "run_pipeline.log"

    # Build test config using bin script
    build_test_config(PROJECT_ROOT, TEST_CONFIG_PATH)
    
    # Run pipeline with bin script
    cmd = ["python3", RUN_PIPELINE_BIN_SCRIPT]
    with log_file.open("w", encoding="utf-8") as log:
        result = subprocess.run(
            cmd,
            cwd=str(PROJECT_ROOT),
            stdout=None,
            stderr=log,
            text=True,
            check=False,
        )

    if result.returncode != 0:
        raise RuntimeError(f"Pipeline failed — see log: {log_file}")

    # Run tests and pass test config to test functions
    yield {"test_config_path": str(TEST_CONFIG_PATH)}

    # Cleanup test environment
    clean_workspace(PROJECT_ROOT)
