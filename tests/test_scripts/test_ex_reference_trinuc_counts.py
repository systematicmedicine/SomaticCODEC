"""
--- test_ex_reference_trinuc_counts.py ---

Tests the script test_ex_reference_trinuc_counts.py

Authors:
  - Chat-GPT
  - Joshua Johnstone
"""

from scripts.ex.variant_analysis.ex_reference_trinuc_counts import main
import pytest
import types
import pandas as pd

@pytest.mark.parametrize("ref_fasta_path, expected_counts_csv", [
    # 
    ("tests/data/test_ex_reference_trinuc_counts/ref.fa",
     "tests/data/test_ex_reference_trinuc_counts/expected_counts.csv")
])
def test_ex_reference_trinuc_counts(tmp_path, ref_fasta_path, expected_counts_csv):
  
  # Define tmp output paths
  output_csv_path = tmp_path / "counts.csv"
  log = tmp_path / "test_ex_reference_trinuc_counts.log"

  # Pass test arguments
  args = types.SimpleNamespace(
        ref_fasta = str(ref_fasta_path),
        output_csv = str(output_csv_path),
        log = str(log)
    )
  
  # Run script with test data
  main(args=args)

  # Assert that output counts match expected counts
  counts_df = pd.read_csv(output_csv_path)
  expected_counts_df = pd.read_csv(expected_counts_csv)
  pd.testing.assert_index_equal(counts_df.columns, expected_counts_df.columns)