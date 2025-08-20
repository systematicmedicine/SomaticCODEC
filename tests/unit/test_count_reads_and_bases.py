"""
--- test_count_reads_and_bases.py ---

    * Test that the script count_reads_and_bases works correctly for a synthetic FASTQ file with known number of reads and bases
    * Does not test BAM files are counted correctly

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import libraries
import shutil
from pathlib import Path
import pytest
from scripts.count_reads_and_bases import count_fastq_with_seqkit, count_bam_with_samtools

# Define hard coded parameters
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
TEST_FASTQ = PROJECT_ROOT / "tests" / "data" / "test_count_reads_and_bases" / "r1.fq"
TEST_BAM = PROJECT_ROOT / "tests" / "data" / "test_count_reads_and_bases" / "r1.bam"
EXPECTED_READS = 100
EXPECTED_BASES = 15000

# Test FASTQ file gets correct number of reads and bases
def test_count_fastq_with_seqkit():
    if shutil.which("seqkit") is None:
        pytest.skip("seqkit not found on PATH")

    assert TEST_FASTQ.exists(), f"Missing test input: {TEST_FASTQ}"

    reads, bases = count_fastq_with_seqkit(TEST_FASTQ)
    assert (reads, bases) == (EXPECTED_READS, EXPECTED_BASES)

# Test BAM file gets correct number of reads and bases
def test_count_bam_with_samtools():
    if shutil.which("samtools") is None:
        pytest.skip("samtools not found on PATH")

    assert TEST_BAM.exists(), f"Missing test input: {TEST_BAM}"

    reads, bases = count_bam_with_samtools(TEST_BAM)
    assert (reads, bases) == (EXPECTED_READS, EXPECTED_BASES)
