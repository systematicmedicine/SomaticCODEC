"""
--- test_ex_somatic_SNV_clustering_metrics.py

Tests the script ex_somatic_SNV_clustering_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import os
from scripts.ex_somatic_SNV_clustering_metrics import main

@pytest.mark.parametrize(
    "vcf_path, expected_total_snvs, expected_alt_depth_gt1, expected_alt_depth_gt3, expected_clustered_snvs, expected_depth_pct, expected_clustered_pct",
    [
        (
            "tests/data/test_ex_somatic_SNV_clustering_metrics/test_cluster.vcf",
            4, 3, 2, 3, 75, 75
        ),
        (
            "tests/data/test_ex_somatic_SNV_clustering_metrics/test_no_cluster.vcf",
            4, 2, 1, 0, 50, 0
        ),
    ]
)
def test_snv_clustering_metrics(tmp_path, vcf_path, expected_total_snvs, expected_alt_depth_gt1, expected_alt_depth_gt3, 
                                expected_clustered_snvs, expected_depth_pct, expected_clustered_pct):
    vcf_file = vcf_path
    output_metrics = tmp_path / "metrics.txt"
    log_file = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"vcf_snvs": vcf_file})
        output = type("output", (), {"metrics": str(output_metrics)})
        log = [str(log_file)]

    main(MockSnakemake)

    metrics = {}
    with open(output_metrics) as f:
        for line in f:
            key, val = line.strip().split("\t")
            if "%" in val:
                val = float(val.strip("%"))
            else:
                val = int(val)
            metrics[key] = val

    assert metrics["ex_total_somatic_snv_positions"] == expected_total_snvs
    assert metrics["ex_total_somatic_snv_positions_>1x_depth"] == expected_alt_depth_gt1
    assert metrics["ex_total_somatic_snv_positions_>3x_depth"] == expected_alt_depth_gt3
    assert metrics["ex_total_somatic_snv_positions_clustered"] == expected_clustered_snvs
    assert metrics["ex_somatic_depth_per_position"] == pytest.approx(expected_depth_pct)
    assert metrics["ex_somatic_clustered_or_mnv"] == pytest.approx(expected_clustered_pct)

    if os.path.exists(log_file):
        os.remove(log_file)


