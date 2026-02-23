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
from collections import Counter
import numpy as np
from helpers.get_metadata import load_config

# Integration test - Tests that output CSVs with the correct columns are created from input files
@pytest.mark.parametrize("vcf_path, vcf_all_path, expected_props_csv, expected_similarities_csv", [
    # Variant call eligible regions contain only one trinucleotide
    ("tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_variants.vcf",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_all_positions.vcf",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_expected_props.csv",
     "tests/data/test_ex_trinucleotide_context_metrics/var_call_eligible_one_trinuc_only/S00X_expected_similarities.csv")
])
def test_ex_trinucleotide_context_metrics(lightweight_test_run, tmp_path, vcf_path, vcf_all_path, expected_props_csv, expected_similarities_csv):
  
  # Load reference file paths from config
  config = load_config(lightweight_test_run["test_config_path"])
  ref_fasta_path = config["sci_params"]["global"]["reference_genome"]
  ref_contexts_path = config["sci_params"]["global"]["reference_tri_contexts"]
  ref_trinuc_counts_path = config["sci_params"]["global"]["reference_genome_trinuc_counts"]

  # Define tmp output paths
  proportions_csv = tmp_path / "trinuc_proportions.csv"
  similarities_csv = tmp_path / "trinuc_similarities.csv"
  plot_pdf_raw = tmp_path / "trinuc_plots_raw.pdf"
  plot_pdf_normalised = tmp_path / "trinuc_plots_normalised.pdf"
  log = tmp_path / "ex_trinucleotide_context_metrics.log"

  # Define params
  sample = "S00X"

  # Pass test arguments
  args = types.SimpleNamespace(
        vcf_path = str(vcf_path),
        vcf_all_path = str(vcf_all_path),
        ref_fasta_path = str(ref_fasta_path),
        ref_contexts_path = str(ref_contexts_path),
        ref_trinuc_counts_path = str(ref_trinuc_counts_path),
        proportions_csv = str(proportions_csv),
        similarities_csv = str(similarities_csv),
        plot_pdf_raw = str(plot_pdf_raw),
        plot_pdf_normalised = str(plot_pdf_normalised),
        sample = str(sample),
        log = str(log)
    )
  
  # Mock PDF generation to reduce test time
  with patch.object(tcm, "generate_comparison_plots"):
        # Run script with test data
        tcm.main(args=args)

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
    ref_trinuc_counts_path = "tests/data/test_ex_trinucleotide_context_metrics/test_get_genome_trinuc_counts_props/trinuc_genome_counts.csv"
    expected_counts_props = "tests/data/test_ex_trinucleotide_context_metrics/test_get_genome_trinuc_counts_props/expected_counts_props.csv"
    CONTEXTS = tcm.get_contexts()

    # Define output
    output_counts_proportions_csv = tmp_path / "counts_proportions.csv"

    # Run function with test data
    ref_trinuc_counts, ref_trinuc_proportions = tcm.get_genome_trinuc_counts_props(ref_trinuc_counts_path)

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

# Tests that the function normalise_sample_trinuc_context_counts returns the expected output
def test_normalise_sample_trinuc_context_counts():
    # Define inputs
    ref_genome_trinuc_proportions = {
        "ACA": 0.1,
        "ACG": 0.4,
        "TCA": 0.5
    }
    variant_call_eligible_trinuc_proportions = {
        "ACA": 0.2,
        "ACG": 0.4,
        "TCA": 0.4
    }
    sample_counts_raw = Counter({
        "ACA>T": 10,
        "ACG>A": 10,
        "TCA>G": 10
    })

    # Define expected output
    expected_sample_counts_norm = {
        "ACA>T": 5,
        "ACG>A": 10,
        "TCA>G": 12.5
    }

    # Run function with test data
    sample_counts_norm = tcm.normalise_sample_trinuc_context_counts(ref_genome_trinuc_proportions, variant_call_eligible_trinuc_proportions, sample_counts_raw)

    # Assert that output data matches expected data
    assert sample_counts_norm == expected_sample_counts_norm, "Output data does not match expected data"

# Tests that the function get_sample_trinuc_context_proportions returns the expected output
def test_get_sample_trinuc_context_proportions():
    # Define inputs
    sample_context_counts = {
        "ACA>T": 2,
        "ACG>A": 3,
        "TCA>G": 5
    }
    CONTEXTS = tcm.get_contexts()

    # Define expected output data
    expected_context_props = pd.read_csv("tests/data/test_ex_trinucleotide_context_metrics/test_get_sample_trinuc_context_proportions/expected_context_props.csv")

    # Run function with test data
    context_props = tcm.get_sample_trinuc_context_proportions(sample_context_counts, CONTEXTS)

    # Assert that output data matches expected data
    pd.testing.assert_series_equal(
        context_props["Proportion"],
        expected_context_props["Proportion"],
        check_names=False,
        atol=1e-8
    )

# Tests that the function calculate_cosine_similarities correctly calculates cosine similarity
@pytest.mark.parametrize("sample_proportions_csv, expected_cosine_sim", [
    # Sample proportions the same as reference context proportions
    ("tests/data/test_ex_trinucleotide_context_metrics/test_calculate_cosine_similarities/sample_proportions_matched.csv",
     1),
     # Sample proportions opposite to reference context proportions
    ("tests/data/test_ex_trinucleotide_context_metrics/test_calculate_cosine_similarities/sample_proportions_opposite.csv",
     0),
     # Sample proportions similar but not the same as reference context proportions
    ("tests/data/test_ex_trinucleotide_context_metrics/test_calculate_cosine_similarities/sample_proportions_similar.csv",
     0.980581)
])
def test_calculate_cosine_similarities(tmp_path, sample_proportions_csv, expected_cosine_sim):
    # Define inputs
    ref_contexts = pd.read_csv("tests/data/test_ex_trinucleotide_context_metrics/test_calculate_cosine_similarities/ref_contexts.csv")
    profiles = ref_contexts["Profile"].unique()
    CONTEXTS = ["ACA>A", "ACC>A", "ACG>A", "ACT>A"]
    sample_proportions_df = pd.read_csv(sample_proportions_csv)

    # Run function with test data
    cosine_similarities, _ = tcm.calculate_cosine_similarities(sample_proportions_df, profiles, ref_contexts, CONTEXTS, "norm")

    calculated_cosine_sim = cosine_similarities["cosine_sim_norm"][0]

    # Assert that the correct cosine similarity is calculated
    assert np.isclose(calculated_cosine_sim, expected_cosine_sim, rtol=0.001), \
    f"Calculated cosine similarity {calculated_cosine_sim} does not match expected {expected_cosine_sim}"
