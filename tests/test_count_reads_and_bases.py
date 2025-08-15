"""
--- test_count_reads_and_bases.py ---

    * Test that the script count_reads_and_bases works correctly for a synthetic FASTQ file with known number of reads and bases
    * Does not test BAM files are counted correctly

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
import sys
import shutil
from pathlib import Path
import pytest

# Define hard coded parameters
PROJECT_ROOT = Path(__file__).resolve().parents[1]
TEST_FASTQ = PROJECT_ROOT / "tests" / "data" / "test_count_reads_and_bases" / "r1.fq"
EXPECTED_READS = 100
EXPECTED_BASES = 15000

# Test FASTQ file gets correct number of reads and bases
def test_count_fastq_with_seqkit():
    if shutil.which("seqkit") is None:
        pytest.skip("seqkit not found on PATH")

    scripts_dir = PROJECT_ROOT / "scripts"
    sys.path.insert(0, str(scripts_dir))

    from count_reads_and_bases import count_fastq_with_seqkit  # import after path tweak

    assert TEST_FASTQ.exists(), f"Missing test input: {TEST_FASTQ}"

    reads, bases = count_fastq_with_seqkit(TEST_FASTQ)
    assert (reads, bases) == (EXPECTED_READS, EXPECTED_BASES)
