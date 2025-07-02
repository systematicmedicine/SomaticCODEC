"""
--- test_ex_call_somatic_variants.py ---

Tests the somatic variant calling module using a known input BAM and BED file.

Checks that the expected number of bases and SNVs are reported.

Author: James Phie
"""

import subprocess
from pathlib import Path
import pandas as pd
import os

def symlink_somatic_variant_bam():
    sample = "testvariants"
    src_bam = Path("tests/data/ex_somatic_variant_dsc.bam")
    src_bai = Path("tests/data/ex_somatic_variant_dsc.bam.bai")
    dest_dir = Path(f"tmp/{sample}")
    dest_dir.mkdir(parents=True, exist_ok=True)

    dest_bam = dest_dir / f"{sample}_map_dsc_anno_filtered.bam"
    dest_bai = dest_dir / f"{sample}_map_dsc_anno_filtered.bam.bai"

    if not dest_bam.exists():
        os.symlink(src_bam.resolve(), dest_bam)
    if not dest_bai.exists():
        os.symlink(src_bai.resolve(), dest_bai)

def symlink_include_bed():
    sample = "testvariants"
    src = Path("tests/data/ex_include_chr1_30k_1M.bed")
    dest = Path(f"tmp/{sample}/{sample}_include.bed")

    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        os.symlink(src.resolve(), dest)

# Tests if bcftools calls and somatic mutation rate script calls the correct results from supplied dsc bam and bed file
def test_ex_call_somatic_variants_output(clean_workspace_fixture):
    symlink_somatic_variant_bam()
    symlink_include_bed()

    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ex_call_somatic_variants",
        "--cores", "all",
        "--configfile", "tests/configs/test_ex_call_somatic_variants_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]
    subprocess.run(snakemake_cmd, check=True)

    metrics_path = "results/testvariants/testvariants_somatic_variant_rate.txt"
    metrics = pd.read_csv(metrics_path, sep="\t", index_col="metric")["value"]

    expected = {
        "starting_bases": 331,
        "filtered_bases": 142,
        "num_snv_bases": 4,
    }

    for metric, expected_value in expected.items():
        assert int(metrics[metric]) == expected_value, f"{metric} was {metrics[metric]}, expected {expected_value}"
