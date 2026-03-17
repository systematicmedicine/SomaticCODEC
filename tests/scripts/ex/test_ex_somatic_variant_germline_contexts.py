"""
--- test_ex_somatic_variant_germline_contexts.py

Tests the script ex_somatic_variant_germline_contexts.py

Authors:
    - Joshua Johnstone
"""

from rule_scripts.ex.variant_analysis.ex_somatic_variant_germline_contexts import main
import types

# Tests that germline records are correctly extracted at somatic variant positions
def test_germline_records_extracted_correctly(tmp_path):

    # Define helper function
    def get_vcf_records(path):
        with open(path) as f:
            return [line.rstrip("\n") for line in f if not line.startswith("#")]

    # Define inputs and outputs
    germline_bcf = "tests/data/test_ex_somatic_variant_germline_contexts/germline.bcf"
    somatic_vcf = "tests/data/test_ex_somatic_variant_germline_contexts/somatic.vcf"
    output_germ_context_vcf = tmp_path / "germ_context.vcf"
    log_file = tmp_path / "ex_somatic_variant_germline_contexts.log"

    # Define expected output
    expected_germ_context_vcf = "tests/data/test_ex_somatic_variant_germline_contexts/expected_germ_context.vcf"

    # Run script with test data
    args = types.SimpleNamespace(
        ms_pileup_bcf = germline_bcf,
        ex_somatic_vcf = somatic_vcf,
        contexts_vcf = output_germ_context_vcf,
        threads = 1,
        log=log_file
        )
    main(args=args)

    # Assert that output VCF records match expected VCF records
    output_vcf_records = get_vcf_records(output_germ_context_vcf)
    expected_vcf_records = get_vcf_records(expected_germ_context_vcf)

    assert output_vcf_records == expected_vcf_records, "Output VCF records do not match expected VCF records"





