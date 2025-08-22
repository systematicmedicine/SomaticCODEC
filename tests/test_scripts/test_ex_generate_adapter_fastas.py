"""
--- test_ex_generate_adapter_fastas.py

Tests the rule ex_generate_adapter_fastas

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import glob
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from tests.utils.fasta_utils import count_fasta_data_points, check_fasta_structure
from scripts.get_metadata import load_config, get_ex_sample_ids

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
    config = load_config("config/config.yaml")
    ex_samples = get_ex_sample_ids(config)
    ex_sample_count = len(ex_samples)

    # Assert that there are 4 FASTA entries per sample (r1 start/end, r2 start/end)
    assert total_fasta_entries / ex_sample_count == 4, (
    f"Expected 4 FASTA entries per sample, actual entries per sample: {total_fasta_entries / ex_sample_count}"
    )

