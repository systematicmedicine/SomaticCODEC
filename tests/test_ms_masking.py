
"""
--- test_ms_masking.py ---

Functions for testing if BED files can be:
    - Created from ms BAM and VCF files
    - Combined with pre-made BEDs

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil

# Tests if non-empty BED files can be created from ms BAM and VCF files
def test_ms_bed_output_exists(clean_workspace_fixture):

    # Copy BAM and VCF files into S001/tmp directory
    ms_sample = pd.read_csv("tests/configs/test_ms_bed_output_exists_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:

        target_dir = Path("tmp") / sample
        target_dir.mkdir(exist_ok=True)

        files_to_copy = [f"{sample}_markdup.bam",
                         f"{sample}_markdup.bai",
                         f"{sample}_ms_filter_pass_variants.vcf.gz"]

        for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_bed_output_exists",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_bed_output_exists_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    

    for sample in ms_sample:
        # Define low depth BED path
        lowdepth_bed_path = Path("tmp") / sample / f"{sample}_lowdepth.bed"

        # Check if low depth BED exists
        assert lowdepth_bed_path.exists(), f"_lowdepth.bed not found: {lowdepth_bed_path}"

        # Check that low depth BED is not empty
        assert lowdepth_bed_path.stat().st_size > 0, f"_lowdepth.bed is empty: {lowdepth_bed_path}"

        # Define germline SNV BED path
        GL_SNV_bed_path = Path("tmp") / sample / f"{sample}_GL_variants_snv.bed"

        # Check if germline SNV BED exists
        assert GL_SNV_bed_path.exists(), f"GL_variants_snv.bed not found: {GL_SNV_bed_path}"

        # Check that germline SNV BED is not empty
        assert GL_SNV_bed_path.stat().st_size > 0, f"GL_variants_snv.bed is empty: {GL_SNV_bed_path}"


# # Tests if BED files can be combined
# def test_ms_bed_combination(clean_workspace_fixture):

#     # Copy BAM and VCF files into S001/tmp directory
#     ms_sample = pd.read_csv("tests/configs/test_ms_bed_combination_samples.csv")["ms_sample"].to_list()

#     for sample in ms_sample:

#         target_dir = Path("tmp") / sample
#         target_dir.mkdir(exist_ok=True)

#         files_to_copy = [f"{sample}_markdup.bam",
#                          f"{sample}_markdup.bai",
#                          f"{sample}_ms_filter_pass_variants.vcf.gz",
#                          f"{sample}_ms_filter_pass_variants.vcf.gz.tbi"]

#         for filename in files_to_copy:
#             source = Path("tests/data") / filename
#             dest = target_dir / filename
#             shutil.copy(source, dest)

#     # Copy pre-made bed files into tmp/downloads
#     target_dir = Path("tmp/downloads")
#     target_dir.mkdir(exist_ok=True)

#     files_to_copy = [f"GRCh38_alldifficultregions_10lines.bed",
#                     f"gnomad_common_af01_merged_10lines.bed"]

#     for filename in files_to_copy:
#             source = Path("tests/data") / filename
#             dest = target_dir / filename
#             shutil.copy(source, dest)

#     # Run snakemake
#     snakemake_cmd = [
#         "snakemake",
#         "-s", "tests/snakefiles/Snakefile_test_ms_bed_creation",
#         "--cores", "all",
#         "--configfile", "tests/configs/test_ms_bed_creation_config.yaml",
#         "--notemp",
#         "--forceall",
#         "--rerun-incomplete"
#     ]

#     subprocess.run(snakemake_cmd)

#     # Check for expected output
    

#     for sample in ms_sample:      
#         # Define mask metrics path
#         mask_metrics_path = Path("tmp") / sample / f"{sample}_mask_metrics.txt"

#         # Check if mask metrics file exists
#         assert mask_metrics_path.exists(), f"mask_metrics.txt not found: {mask_metrics_path}"

#         # Check that mask metrics file is not empty
#         assert mask_metrics_path.stat().st_size > 0, f"mask_metrics.txt is empty: {mask_metrics_path}"

#         # Check that low depth bed masks >0 bases

#         # Check that germline SNV bed masks >0 bases

#         # Check that combined bed masks >0 bases
