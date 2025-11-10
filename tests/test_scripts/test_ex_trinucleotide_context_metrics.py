# =========================================================================
# test_ex_trinucleotide_context_metrics.py
#
# Tests the script ex_trinucleotide_context_metrics.py
#   - Tests that trinucleotide contexts are corectly calculated for a sample
#
# Authors:
#   - Chat-GPT
#   - Cameron Fraser
# =========================================================================

# Import libraries

import pandas as pd
from scripts.ex.variant_analysis.ex_trinucleotide_context_metrics import get_sample_trinuc_context, get_contexts
from pyfaidx import Fasta
from pathlib import Path

# Define hard coded variables
VCF_PATH = "tests/data/test_ex_trinucleotide_context_metrics/S00X_variants.vcf"
REF_GENOME_PATH = Path("tests/data/lightweight_test_run/GRCh38_Chr21_plus_stubs.fa")
EXPECTED_CONTEXT = "tests/expected/ex_trinuc_contexts/S00X_expected_context.csv"

def test_get_sample_trinuc_context(tmp_path):
    """
    Unit test for get_sample_trinuc_context:
    - Loads a tiny test VCF (1–2 SNVs)
    - Uses a micro reference FASTA
    - Asserts that returned trinucleotide proportions match expected
    """
    # --- Setup test data ---
    ref_genome = Fasta(REF_GENOME_PATH, rebuild=False)
    contexts = get_contexts()
    expected_df = pd.read_csv(EXPECTED_CONTEXT).sort_values("Context").reset_index(drop=True)

    # --- Call function under test ---
    df = get_sample_trinuc_context(VCF_PATH, ref_genome, contexts).sort_values("Context").reset_index(drop=True)

    # --- Assertions ---
    # Ensure schema matches
    pd.testing.assert_index_equal(df.columns, expected_df.columns)

    # Ensure proportions match expected (tolerate tiny floating error)
    pd.testing.assert_series_equal(
        df["Proportion"],
        expected_df["Proportion"],
        check_names=False,
        atol=1e-8
    )

    # --- Clean up generated .fai index ---
    fai_path = REF_GENOME_PATH.with_suffix(REF_GENOME_PATH.suffix + ".fai")
    if fai_path.exists():
        fai_path.unlink()
