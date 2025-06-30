"""
--- test_ex_fastq_to_bam.py ---

Functions for testing that an raw codecseq fastq files can be successfully demultiplexed and converted to a to an aligned bam with expected reads

Author: James Phie

"""

import subprocess
import json
from pathlib import Path
import pandas as pd

# Tests if raw codecseq fastq files can be converted to an aligned bam
def test_ex_fastq_to_bam_output(clean_workspace_fixture):
    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ex_fastq_to_bam",
        "--cores", "all",
        "--configfile", "tests/configs/test_ex_fastq_to_bam_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]
    subprocess.run(snakemake_cmd, check=True)

    # Load sample and lane info
    ex_samples_df = pd.read_csv("tests/configs/test_ex_fastq_to_bam_exsamples.csv")
    ex_lane_to_sample = ex_samples_df.groupby("lane")["ex_sample"].apply(list).to_dict()

    # Loop by lane → sample
    for lane, samples in ex_lane_to_sample.items():
        # Load demux metrics once per lane
        metrics_path = Path(f"metrics/{lane}/{lane}_demux_metrics.json")
        assert metrics_path.exists(), f"Demux metrics JSON not found: {metrics_path}"
        with open(metrics_path) as f:
            metrics = json.load(f)

        for sample in samples:
            # Check BAM file exists and is non-empty
            bam_path = Path("tmp") / sample / f"{sample}_map.bam"
            assert bam_path.exists(), f"ex_map.bam not found: {bam_path}"
            assert bam_path.stat().st_size > 0, f"ex_map.bam is empty: {bam_path}"
            num_lines = int(subprocess.check_output(["samtools", "view", "-c", str(bam_path)]))
            assert num_lines > 1, f"{bam_path} has too few alignments: {num_lines}"

            # Helper function to extract adapter matches
            def total_matches(adapter_list, sample_name):
                for a in adapter_list:
                    if a["name"] == sample_name:
                        return a["total_matches"]
                return 0

            # Check adapter matches
            read1_matches = total_matches(metrics["adapters_read1"], sample)
            read2_matches = total_matches(metrics["adapters_read2"], sample)

            assert read1_matches > 230, f"{sample} has too few read1 adapter matches: {read1_matches}"
            assert read2_matches > 230, f"{sample} has too few read2 adapter matches: {read2_matches}"
