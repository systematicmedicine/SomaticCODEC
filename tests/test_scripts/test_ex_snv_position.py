# =======================================================================================
# test_ex_snv_position.py
#
# Tests the ex_snv_position.R script against 3 VCF cases:
#   - zero_mad: one chromosome, uniform distribution
#   - fifty_mad: one chromosome, 50 deviation
#   - multi_chrom: multiple chromosomes
#
# Authors:
#   - Chat-GPT 
#   - Cameron Fraser
# =======================================================================================

# --------------------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------------------

import json
import subprocess
import tempfile
from pathlib import Path
import pytest
import os

# Setup paths
TEST_DATA = Path("tests/data/test_ex_snv_position")
SCRIPT_PATH = Path("scripts/ex_snv_position.R")

FAI_PATH = TEST_DATA / "GRCh38_mock.fa.fai"
VCF_CASES = {
    "zero_mad": TEST_DATA / "vcf_case1_zero_mad.vcf",
    "fifty_mad": TEST_DATA / "vcf_case2_fifty_mad.vcf",
    "multi_chrom": TEST_DATA / "vcf_case3_multiple_chroms.vcf",
}


# --------------------------------------------------------------------------------------
# R Snakemake S4 object preamble template
# --------------------------------------------------------------------------------------

R_WRAPPER_TEMPLATE = """
methods::setClass("Snakemake", slots = c(input = "list", output = "list", log = "list", config = "list", params = "list"))
snakemake <- methods::new("Snakemake",
    input = list(
        index_path = "{fai}",
        vcf_path = "{vcf}"
    ),
    output = list(
        metrics_json = "{metrics_json}",
        metrics_plot = "{metrics_plot}"
    ),
    log = list("{log}"),
    config = jsonlite::fromJSON("{config_json}"),
    params = list(
        included_chroms = c("chr21", "chr22")
    )
)
source("{script_path}", echo = TRUE, max.deparse.length = Inf)
"""

# --------------------------------------------------------------------------------------
# Tests
# --------------------------------------------------------------------------------------

@pytest.mark.parametrize("case_name, vcf_path", VCF_CASES.items())
def test_ex_snv_position(case_name, vcf_path):
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        metrics_json = tmpdir / f"{case_name}_metrics.json"
        plot_path = tmpdir / f"{case_name}_plot.pdf"
        log_path = tmpdir / f"{case_name}_log.txt"

        # Minimal config
        config = {
            "run_name": "test-exp",
            "sci_params": {
                "global": {
                    "included_chromosomes": ["chr21", "chr22"]
                }
            }
        }

        # Fill in the R wrapper script
        r_code = R_WRAPPER_TEMPLATE.format(
            fai=FAI_PATH.as_posix(),
            vcf=vcf_path.as_posix(),
            metrics_json=metrics_json.as_posix(),
            metrics_plot=plot_path.as_posix(),
            log=log_path.as_posix(),
            config_json=json.dumps(config).replace('"', '\\"'),
            script_path=SCRIPT_PATH.as_posix()
        )

        # Run the R script
        result = subprocess.run(
            ["Rscript", "--vanilla", "-e", r_code],
            capture_output=True,
            text=True,
        )

        # Print stdout/stderr if test fails
        if result.returncode != 0:
            print(f"[STDOUT]:\n{result.stdout}")
            print(f"[STDERR]:\n{result.stderr}")

        # --- Assertions ---

        # R script should succeed
        assert result.returncode == 0, f"Script failed: {result.stderr}"

        # Output file should exist
        assert metrics_json.exists(), "metrics.json not created"

        # Validate JSON structure
        with open(metrics_json) as f:
            data = json.load(f)

        assert "description" in data
        assert "chromosomes_MAD" in data
        assert "max_MAD" in data

        # Case-specific expectations
        if case_name == "zero_mad":
            assert data["max_MAD"] == 0, "Expected max_MAD = 0"
        elif case_name == "fifty_mad":
            assert data["max_MAD"] == 50, "Expected max_MAD = 50"
        elif case_name == "multi_chrom":
            assert len(data["chromosomes_MAD"]) > 1, "Expected multiple chromosomes"

        # Plot file should exist
        assert plot_path.exists(), "Plot PDF was not created"
