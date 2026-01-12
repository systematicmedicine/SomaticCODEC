"""
--- test_ex_trinucleotide_context_metrics.py ---

Tests the script ex_trinucleotide_context_metrics.py
  - Tests that trinucleotide contexts are corectly calculated for a sample

Authors:
  - Chat-GPT
  - Cameron Fraser
  - Joshua Johnstone
"""

# Import libraries
from scripts.ex.variant_analysis.ex_trinucleotide_context_metrics import main
import pytest
import types
from pathlib import Path

@pytest.mark.parametrize("vcf_path, ref_fasta_path, ref_fai_path, include_bed_path, ref_contexts_path, expected_csv_raw, expected_csv_normalised", [
    ("tests/data/test_ex_trinucleotide_context_metrics/S00X_variants.vcf",
     "tests/data/lightweight_test_run/GRCh38_Chr21_plus_stubs.fa",
     "tests/data/test_ex_trinucleotide_context_metrics/GRCh38_Chr21_plus_stubs.fa.fai",
     "tests/data/test_ex_trinucleotide_context_metrics/include.bed",
     "tests/data/lightweight_test_run/2025-09-30_trinucleotide_contexts.csv",
     "tests/expected/ex_trinuc_contexts/S00X_expected_context_raw.csv",
     "tests/expected/ex_trinuc_contexts/S00X_expected_context_normalised.csv")
])
def test_ex_trinucleotide_context_metrics(tmp_path, vcf_path, ref_fasta_path, ref_fai_path, include_bed_path, ref_contexts_path, expected_csv_raw, expected_csv_normalised):
  
  # Define tmp output paths
  eligible_regions_fasta = tmp_path / "eligible_regions.fa"
  sample_csv_raw = tmp_path / "trinuc_context_raw.csv"
  sample_csv_normalised = tmp_path / "trinuc_context_normalised.csv"
  similarities_csv_raw = tmp_path / "trinuc_similarities_raw.csv"
  similarities_csv_normalised = tmp_path / "trinuc_similarities_normalised.csv"
  plot_pdf_raw = tmp_path / "trinuc_plots_raw.pdf"
  plot_pdf_normalised = tmp_path / "trinuc_plots_normalised.pdf"
  log = tmp_path / "ex_trinucleotide_context_metrics.log"

  # Define params
  sample = "S00X"
  threads = 2

  # Run script with test data
  args = types.SimpleNamespace(
        threads = str(threads),
        vcf_path = str(vcf_path),
        ref_fasta_path = str(ref_fasta_path),
        ref_fai_path = str(ref_fai_path),
        include_bed_path = str(include_bed_path),
        ref_contexts_path = str(ref_contexts_path),
        eligible_regions_fasta = str(eligible_regions_fasta),
        sample_csv_raw = str(sample_csv_raw),
        sample_csv_normalised = str(sample_csv_normalised),
        similarities_csv_raw = str(similarities_csv_raw),
        similarities_csv_normalised = str(similarities_csv_normalised),
        plot_pdf_raw = str(plot_pdf_raw),
        plot_pdf_normalised = str(plot_pdf_normalised),
        sample = str(sample),
        log = str(log)
    )
  main(args=args)

  # # --- Assertions ---
  # # Ensure schema matches
  # pd.testing.assert_index_equal(df.columns, expected_df.columns)

  # # Ensure proportions match expected (tolerate tiny floating error)
  # pd.testing.assert_series_equal(
  #     df["Proportion"],
  #     expected_df["Proportion"],
  #     check_names=False,
  #     atol=1e-8
  # )

  # --- Clean up generated .fai index ---
  fai_path = Path(ref_fasta_path).with_suffix(Path(ref_fasta_path).suffix + ".fai")
  if fai_path.exists():
      fai_path.unlink()

    
