"""
--- lightweight_test_run.py ---

Runs a small dataset through the snakemake pipeline to generate files for testing.

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import pytest
import subprocess
import yaml
import shutil
from tests.helpers.clean_workspace import clean_workspace
from tests.conftest import PROJECT_ROOT, TEST_CONFIG

@pytest.fixture(scope="session")
def lightweight_test_run(tmp_path_factory):

    # Clean test environment
    clean_workspace(PROJECT_ROOT)

    # Copy test files to tmp/downloads
    src_dir = PROJECT_ROOT / "tests/data/lightweight_test_run/downloads"
    dst_dir = PROJECT_ROOT / "tmp/downloads"
    dst_dir.mkdir(exist_ok=True)

    files_to_copy = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]

    for file_path in files_to_copy:
        shutil.copy2(src_dir / file_path.name, dst_dir / file_path.name)

    # Write merged config to temp file
    test_tmp_dir = tmp_path_factory.mktemp("test_dir")
    test_config_file = test_tmp_dir / "merged_config.yaml"
    with open(test_config_file, "w", encoding="utf-8") as f:
        yaml.safe_dump(TEST_CONFIG, f)

    # Log file setup
    log_dir = PROJECT_ROOT / "logs/bin_scripts"
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "run_pipeline.log"

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "--snakefile", str(PROJECT_ROOT / "Snakefile"),
        "--configfile", test_config_file,
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
    yield {"test_config_path": test_config_file}

    # Cleanup test environment
    clean_workspace(PROJECT_ROOT)
