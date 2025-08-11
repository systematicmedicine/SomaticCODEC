"""
--- test_ex_trinucleotide_context_metrics.py

Tests the script ex_trinucleotide_context_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import shutil
from scripts.ex_trinucleotide_context_metrics import main

@pytest.mark.parametrize(
    "vcf_path, ref_path, nanoseq_path, sample_name",
    [
        (
            "tests/data/test_ex_trinucleotide_context_metrics/test.vcf",
            "tests/data/test_ex_trinucleotide_context_metrics/test.fa",
            "tests/data/test_ex_trinucleotide_context_metrics/nanoseq.csv",
            "testsample"
        )
    ]
)
def test_trinucleotide_metrics(tmp_path, vcf_path, ref_path, nanoseq_path, sample_name):
    tmp_vcf = tmp_path / "input.vcf"
    tmp_nanoseq = tmp_path / "nanoseq.csv"
    tmp_output = tmp_path / "metrics.json"
    tmp_log = tmp_path / "log.txt"

    shutil.copy(vcf_path, tmp_vcf)
    shutil.copy(nanoseq_path, tmp_nanoseq)


    class MockSnakemake:
        input = type("input", (), {
            "vcf_snvs": str(tmp_vcf),
            "ref": ref_path,
            "nanoseq_contexts": str(tmp_nanoseq),
        })
        output = type("output", (), {
            "metrics": str(tmp_output)
        })
        params = type("params", (), {
            "sample": sample_name
        })
        log = [str(tmp_log)]

    main(MockSnakemake)

    with open(tmp_output) as f:
        data = json.load(f)

    assert data["cosine_similarity_score"] == 0
