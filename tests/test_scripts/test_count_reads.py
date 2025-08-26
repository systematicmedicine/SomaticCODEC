"""
--- test_count_reads.py ---

    * Test that the script count_reads.py works correctly for synthetic FASTQ and BAM files with known numbers of reads

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import libraries
import shutil
from pathlib import Path
import pytest
import sys

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from scripts.count_reads import count_fastq_with_seqkit, count_bam_with_samtools

# Define hard coded parameters
TEST_FASTQ = PROJECT_ROOT / "tests" / "data" / "test_count_reads" / "r1.fq"
TEST_BAM = PROJECT_ROOT / "tests" / "data" / "test_count_reads" / "r1.bam"
EXPECTED_READS = 100

# Test FASTQ file gets correct number of reads and bases
def test_count_fastq_with_seqkit():
    if shutil.which("seqkit") is None:
        pytest.skip("seqkit not found on PATH")

    assert TEST_FASTQ.exists(), f"Missing test input: {TEST_FASTQ}"

    reads = count_fastq_with_seqkit(TEST_FASTQ)
    assert (reads) == (EXPECTED_READS)

# Test BAM file gets correct number of reads and bases
def test_count_bam_with_samtools():
    if shutil.which("samtools") is None:
        pytest.skip("samtools not found on PATH")

    assert TEST_BAM.exists(), f"Missing test input: {TEST_BAM}"

    reads = count_bam_with_samtools(TEST_BAM)
    assert (reads) == (EXPECTED_READS)
