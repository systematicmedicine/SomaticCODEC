
"""
--- test_mask_creation.py ---

Function for testing if BED files can be:
    - Created from ms BAM and VCF files
    - Combined with pre-made BEDs

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil

# Tests Tests if non-empty BED files can be created and combined with pre-made BEDs
def test_bed_output(clean_workspace_fixture):

    # Copy BAM and VCF files into S001/tmp directory
    ms_sample = pd.read_csv("tests/configs/test_bed_output_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:

        metrics_dir = Path("metrics") / sample
        metrics_dir.mkdir(exist_ok=True)

        target_dir = Path("tmp") / sample
        target_dir.mkdir(exist_ok=True)

        files_to_copy = [f"{sample}_markdup_map.bam",
                         f"{sample}_markdup_map.bai",
                         f"{sample}_ms_candidate_variants.vcf.gz",
                         f"{sample}_ms_candidate_variants.vcf.gz.tbi"]

        for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

    # Copy pre-made bed files into tmp/downloads
    target_dir = Path("tmp/downloads")
    target_dir.mkdir(exist_ok=True)

    files_to_copy = [f"GRCh38_alldifficultregions_10lines.bed",
                    f"gnomad_common_af01_merged_10lines.bed"]

    for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_bed_output",
        "--cores", "all",
        "--configfile", "tests/configs/test_bed_output_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    for sample in ms_sample:      
        # Define mask metrics path
        mask_metrics_path = Path("metrics") / sample / f"{sample}_mask_metrics.txt"

        # Check if mask metrics file exists
        assert mask_metrics_path.exists(), f"mask_metrics.txt not found: {mask_metrics_path}"

        # Check that mask metrics file is not empty
        assert mask_metrics_path.stat().st_size > 0, f"mask_metrics.txt is empty: {mask_metrics_path}"

        # Check that each bed masks >0 bases
        df = pd.read_csv(mask_metrics_path, sep="\t")
        for idx, row in df.iterrows():
            assert int(row["Masked bases"]) > 0, f"{row['Mask File']} is masking 0 bases"
