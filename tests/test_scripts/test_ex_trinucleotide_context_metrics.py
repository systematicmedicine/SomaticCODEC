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
import scripts.ex.variant_analysis.ex_trinucleotide_context_metrics as tcm
import pytest
import types
from pathlib import Path
from unittest.mock import patch
import pandas as pd
from pyfaidx import Fasta

# Tests that output CSVs with the correct structure are created
@pytest.mark.parametrize("vcf_path, vcf_all_path, ref_fasta_path, ref_fai_path, ref_contexts_path, expected_props_csv, expected_similarities_csv", [
    # Variant call eligible regions contain only one trinucleotide
    ("tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_variants.vcf",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_all_positions.vcf",
     "tests/data/lightweight_test_run/GRCh38_Chr21_plus_stubs.fa",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/GRCh38_Chr21_plus_stubs.fa.fai",
     "tests/data/lightweight_test_run/2025-09-30_trinucleotide_contexts.csv",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_expected_props.csv",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_expected_similarities.csv")
])
def test_ex_trinucleotide_context_metrics(tmp_path, vcf_path, vcf_all_path, ref_fasta_path, ref_fai_path, ref_contexts_path, expected_props_csv, expected_similarities_csv):
  
  # Define tmp output paths
  proportions_csv = "trinuc_proportions.csv"
  similarities_csv = "trinuc_similarities.csv"
  plot_pdf_raw = tmp_path / "trinuc_plots_raw.pdf"
  plot_pdf_normalised = tmp_path / "trinuc_plots_normalised.pdf"
  log = tmp_path / "ex_trinucleotide_context_metrics.log"

  # Define params
  sample = "S00X"
  threads = 2

  # Pass test arguments
  args = types.SimpleNamespace(
        threads = str(threads),
        vcf_path = str(vcf_path),
        vcf_all_path = str(vcf_all_path),
        ref_fasta_path = str(ref_fasta_path),
        ref_fai_path = str(ref_fai_path),
        ref_contexts_path = str(ref_contexts_path),
        proportions_csv = str(proportions_csv),
        similarities_csv = str(similarities_csv),
        plot_pdf_raw = str(plot_pdf_raw),
        plot_pdf_normalised = str(plot_pdf_normalised),
        sample = str(sample),
        log = str(log)
    )
  
  # Mock PDF generation to reduce test time
  with patch(
        "scripts.ex.variant_analysis.ex_trinucleotide_context_metrics.generate_comparison_plots"
    ):
        # Run script with test data
        tcm.main(args=args)

  # Clean up generated .fai index
  fai_path = Path(ref_fasta_path).with_suffix(Path(ref_fasta_path).suffix + ".fai")
  if fai_path.exists():
      fai_path.unlink()

  # Clean up generated .jf file
  jf_path = Path(ref_fasta_path).with_suffix(Path(ref_fasta_path).suffix + ".jf")
  if jf_path.exists():
      jf_path.unlink()

  # --- Assertions ---
  # Ensure CSV schema match expected
  props_df = pd.read_csv(proportions_csv)
  expected_props_df = pd.read_csv(expected_props_csv)
  pd.testing.assert_index_equal(props_df.columns, expected_props_df.columns)

  similarities_df = pd.read_csv(similarities_csv)
  expected_similarities_df = pd.read_csv(expected_similarities_csv)
  pd.testing.assert_index_equal(similarities_df.columns, expected_similarities_df.columns)

# Tests that the get_genome_trinuc_counts_props function returns the expected output
def test_get_genome_trinuc_counts_props(tmp_path):
    # Define inputs
    ref_fasta_path = "tests/data/test_ex_trinucleotide_context_metrics/test_get_genome_trinuc_counts_props/ref.fa"
    genome_length = 1e6
    expected_counts_props = "tests/data/test_ex_trinucleotide_context_metrics/test_get_genome_trinuc_counts_props/expected_counts_props.csv"
    THREADS = 1
    CONTEXTS = tcm.get_contexts()

    # Define output
    output_counts_proportions_csv = tmp_path / "counts_proportions.csv"

    # Run function with test data
    ref_trinuc_counts, ref_trinuc_proportions = tcm.get_genome_trinuc_counts_props(ref_fasta_path, genome_length, THREADS)

    # Collate output data
    counts_proportions_rows = []

    for context in CONTEXTS:
        trinuc = context.split(">")[0]
        genome_count = ref_trinuc_counts.get(trinuc, 0)
        genome_prop = round(ref_trinuc_proportions.get(trinuc, 0), ndigits = 2)

        counts_proportions_rows.append({
            "trinucleotide": trinuc,
            "trinuc_genome_count": genome_count,
            "trinuc_genome_prop": genome_prop
        })

    counts_proportions_csv = pd.DataFrame(counts_proportions_rows)
    counts_proportions_csv.to_csv(output_counts_proportions_csv, index=False)

    counts_proportions_df = pd.read_csv(output_counts_proportions_csv)
    expected_df = pd.read_csv(expected_counts_props)

    # Clean up generated .jf file
    jf_path = Path(ref_fasta_path).with_suffix(Path(ref_fasta_path).suffix + ".jf")
    if jf_path.exists():
        jf_path.unlink()

    # Assert that output data matches expected data
    pd.testing.assert_series_equal(
        counts_proportions_df["trinuc_genome_count"],
        expected_df["trinuc_genome_count"],
        check_names=False,
        atol=1e-8
    )

    pd.testing.assert_series_equal(
        counts_proportions_df["trinuc_genome_prop"],
        expected_df["trinuc_genome_prop"],
        check_names=False,
        atol=1e-8
    )
    
# Tests that the get_variant_call_eligible_trinuc_counts_props function returns the expected output
def test_get_variant_call_eligible_trinuc_counts_props(tmp_path):
    # Define inputs
    ref_fasta_path = "tests/data/test_ex_trinucleotide_context_metrics/test_get_variant_call_eligible_trinuc_counts_props/ref.fa"
    ref_genome = Fasta(ref_fasta_path, rebuild=False)
    vcf_all = "tests/data/test_ex_trinucleotide_context_metrics/test_get_variant_call_eligible_trinuc_counts_props/all_positions.vcf"
    expected_vce_counts_props = "tests/data/test_ex_trinucleotide_context_metrics/test_get_variant_call_eligible_trinuc_counts_props/expected_vce_counts_props.csv"
    CONTEXTS = tcm.get_contexts()

    # Define output path
    vce_counts_proportions = tmp_path / "vce_counts_proportions"

    # Run function with test data
    variant_call_eligible_trinuc_counts, variant_call_eligible_trinuc_proportions = tcm.get_variant_call_eligible_trinuc_counts_props(ref_genome, vcf_all)

    # Collate output data
    vce_counts_proportions_rows = []

    for context in CONTEXTS:
        trinuc = context.split(">")[0]
        eligible_count = variant_call_eligible_trinuc_counts.get(trinuc, 0)
        eligible_prop = round(variant_call_eligible_trinuc_proportions.get(trinuc, 0), ndigits = 2)

        vce_counts_proportions_rows.append({
            "trinucleotide": trinuc,
            "trinuc_var_call_eligible_count": eligible_count,
            "trinuc_var_call_eligible_prop": eligible_prop,
        })

    vce_counts_proportions_csv = pd.DataFrame(vce_counts_proportions_rows)
    vce_counts_proportions_csv.to_csv(vce_counts_proportions, index=False)

    vce_counts_proportions_df = pd.read_csv(vce_counts_proportions)
    expected_df = pd.read_csv(expected_vce_counts_props)

    # Clean up generated .fai index
    fai_path = Path(ref_fasta_path).with_suffix(Path(ref_fasta_path).suffix + ".fai")
    if fai_path.exists():
        fai_path.unlink()

    # Assert that output data matches expected data
    pd.testing.assert_series_equal(
        vce_counts_proportions_df["trinuc_var_call_eligible_count"],
        expected_df["trinuc_var_call_eligible_count"],
        check_names=False,
        atol=1e-8
    )

    pd.testing.assert_series_equal(
        vce_counts_proportions_df["trinuc_var_call_eligible_prop"],
        expected_df["trinuc_var_call_eligible_prop"],
        check_names=False,
        atol=1e-8
    )

# Tests that the get_sample_trinuc_context_counts function returns the expected output
def test_get_sample_trinuc_context_counts(tmp_path):
    # Define inputs
    vcf_path = "tests/data/test_ex_trinucleotide_context_metrics/test_get_sample_trinuc_context_counts/snvs.vcf"
    ref_fasta_path = "tests/data/test_ex_trinucleotide_context_metrics/test_get_sample_trinuc_context_counts/ref.fa"
    ref_genome = Fasta(ref_fasta_path, rebuild=False)
    expected_snv_counts = "tests/data/test_ex_trinucleotide_context_metrics/test_get_sample_trinuc_context_counts/expected_snv_counts.csv"
    CONTEXTS = tcm.get_contexts()

    # Define output path
    output_snv_count_csv = tmp_path / "snv_counts.csv"

    # Run function with test data
    sample_counts_raw = tcm.get_sample_trinuc_context_counts(vcf_path, ref_genome)

    # Collate output data
    snv_count_csv_rows = []

    for context in CONTEXTS:
        snv_count_raw = sample_counts_raw.get(context, 0)

        snv_count_csv_rows.append({
            "context": context,
            "snv_count_raw": snv_count_raw,
        })

    snv_count_csv = pd.DataFrame(snv_count_csv_rows)
    snv_count_csv.to_csv(output_snv_count_csv, index=False)

    snv_counts_df = pd.read_csv(output_snv_count_csv)
    expected_df = pd.read_csv(expected_snv_counts)

    # Clean up generated .fai index
    fai_path = Path(ref_fasta_path).with_suffix(Path(ref_fasta_path).suffix + ".fai")
    if fai_path.exists():
        fai_path.unlink()

    # Assert that output data matches expected data
    pd.testing.assert_series_equal(
        snv_counts_df["snv_count_raw"],
        expected_df["snv_count_raw"],
        check_names=False,
        atol=1e-8
    )

    