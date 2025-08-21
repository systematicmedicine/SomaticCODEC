"""
--- test_ex_trim_fastq.py

Tests the rule ex_filter_fastq

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

import glob
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from tests.utils.fastq_utils import count_fastq_data_points

# Test that filtering decreases the number of reads
def test_filtering_decreases_reads(lightweight_test_run):
    # Find input and output FASTQ files
    input_files = sorted(glob.glob("tmp/*/*_r1_trim.fastq.gz"))
    output_files = sorted(glob.glob("tmp/*/*_r1_filter.fastq.gz"))

    # Map sample names to file paths
    input_map = {Path(f).stem.replace("_r1_trim", ""): f for f in input_files}
    output_map = {Path(f).stem.replace("_r1_filter", ""): f for f in output_files}

    assert input_map.keys() == output_map.keys(), "Mismatch between input and output files"

    for sample_id in input_map:
        in_path = input_map[sample_id]
        out_path = output_map[sample_id]

        in_reads = count_fastq_data_points(in_path)
        out_reads = count_fastq_data_points(out_path)

        assert out_reads < in_reads, (
            f"Filtering did not reduce the number of reads for {sample_id}: "
            f"{in_reads} in vs {out_reads} out"
        )