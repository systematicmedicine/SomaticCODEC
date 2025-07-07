
"""
--- test_ms_fastq_vcf.py ---

Function for testing the ms pipeline from raw FASTQs to a combined mask BED file

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil

# Tests if non-empty BED and metrics files can be created from raw ms FASTQ files
def test_ms_outputs(clean_workspace_fixture):

# Copy files into tmp/downloads
    target_dir = Path("tmp/downloads")
    target_dir.mkdir(exist_ok=True)

    files_to_copy = [f"micro_GRCh38_Chr1_1Mbp.fna",
                     f"ms_Chr1_100reads_r1.fastq.gz",
                     f"ms_Chr1_100reads_r2.fastq.gz",
                     f"GRCh38_alldifficultregions_10lines.bed",
                     f"gnomad_common_af01_merged_10lines.bed"
                     ]

    for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_outputs",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_outputs_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected outputs
    ms_sample = pd.read_csv("tests/configs/test_ms_outputs_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:
        files_to_check = [
            ("combined_mask.bed", Path("tmp") / sample / f"{sample}_combined_mask.bed"),
            ("r1_raw_fastqc.html", Path("metrics") / sample / f"{sample}_r1_raw_fastqc.html"),
            ("r2_raw_fastqc.html", Path("metrics") / sample / f"{sample}_r2_raw_fastqc.html"),
            ("trimfilter_metrics.tsv", Path("metrics") / sample / f"{sample}_trimfilter_metrics.tsv"),
            ("trimfilter_r1_fastqc.html", Path("metrics") / sample / f"{sample}_trimfilter_r1_fastqc.html"),
            ("trimfilter_r2_fastqc.html", Path("metrics") / sample / f"{sample}_trimfilter_r2_fastqc.html"),
            ("markdup_metrics.txt", Path("metrics") / sample / f"{sample}_markdup_metrics.txt"),
            ("alignment_stats.txt", Path("metrics") / sample / f"{sample}_alignment_stats.txt"),
            ("insert_size_metrics.txt", Path("metrics") / sample / f"{sample}_insert_size_metrics.txt"),
            ("insert_size_histogram.pdf", Path("metrics") / sample / f"{sample}_insert_size_histogram.pdf"),
            ("variantCall_summary.txt", Path("metrics") / sample / f"{sample}_variantCall_summary.txt"),
            ("ms_het_hom_ratio.txt", Path("metrics") / sample / f"{sample}_ms_het_hom_ratio.txt"),
            ("depth_histogram.txt", Path("metrics") / sample / f"{sample}_depth_histogram.txt"),
            ("mask_metrics.txt", Path("metrics") / sample / f"{sample}_mask_metrics.txt"),
            ("component_metrics_report.csv", Path("metrics/component_metrics_report.csv"))
    ]

    for desc, path in files_to_check:
        # Check that file exists
        assert path.exists(), f"File not found ({desc}, sample {sample}): {path}"
        # Check that file is not empty
        assert path.stat().st_size > 0, f"File is empty ({desc}, sample {sample}): {path}"

        # Check that files have rows below header
        if path.suffix in [".csv", ".tsv", ".txt"]:
            # Determine separator
            sep = "\t" if path.suffix == ".tsv" or desc.endswith("metrics.txt") else ","
            try:
                df = pd.read_csv(path, sep=sep, comment="#")
                assert len(df) > 0, f"File has header but no data rows ({desc}, sample {sample}): {path}"
            except pd.errors.EmptyDataError:
                assert False, f"File has header but no data rows ({desc}, sample {sample}): {path}"
        