import subprocess
from pathlib import Path
import shutil
import pytest

def clean_workspace():
    for folder in ["metrics", "results", "tmp"]:
        path = Path(folder)
        for item in path.iterdir():
            if item.name != ".gitkeep":
                if item.is_dir():
                    shutil.rmtree(item)
                else:
                    item.unlink()

@pytest.fixture
def clean_workspace_fixture():
    # Run cleanup before the test
    clean_workspace()

    # Run test
    yield

    # Run cleanup after the test
    clean_workspace()                   

def test_ms_alignment_output_exists(clean_workspace_fixture):

    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_fastq2alignment",
        "--cores", "all",
        "--configfile", "tests/configs/ms_test_config.yaml",
        "--notemp"
    ]

    subprocess.run(snakemake_cmd, capture_output=True, text=True)

    # Check for expected output
    sample = "S001"
    bam_path = Path("tmp") / sample / f"{sample}_markdup.bam"

    # Check if markdup bam exists
    assert bam_path.exists(), f"BAM file not found: {bam_path}"

    # Check if markdup bam is empty
    assert bam_path.stat().st_size > 0, f"BAM file is empty: {bam_path}"
