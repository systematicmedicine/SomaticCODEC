"""
--- test_ex_generate_adapter_fastas.py

Tests the rule ex_generate_adapter_fastas

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import glob
from utils.fasta_utils import count_fasta_data_points, check_fasta_structure
import pandas as pd
from pathlib import Path

# Tests that FASTA files have correct structure
def test_fasta_structure_correct(lightweight_test_run):
    # Locate all FASTA files
    fasta_files = glob.glob("tmp/*/*.fasta")

    # Check for correct structure in each FASTA file
    for fasta in fasta_files:
        check_fasta_structure(fasta)

# Tests that that there are 4 FASTA entries per sample (r1 start/end, r2 start/end)
def test_fasta_entries_per_sample(lightweight_test_run):
    # Locate all FASTA files
    fasta_files = glob.glob("tmp/*/*.fasta")

    # Count number of entries in FASTA files
    fasta_entries = {Path(f).name: count_fasta_data_points(f) for f in fasta_files}
    total_fasta_entries = sum(fasta_entries.values())

    # Get number of ex samples
    ex_samples = pd.read_csv("tests/configs/lightweight_test_run/ex_samples.csv")["ex_sample"].to_list()
    ex_sample_count = len(ex_samples)

    # Assert that there are 4 FASTA entries per sample (r1 start/end, r2 start/end)
    assert total_fasta_entries / ex_sample_count == 4, (
    f"Expected 4 FASTA entries per sample, actual entries per sample: {total_fasta_entries / ex_sample_count}"
    )

