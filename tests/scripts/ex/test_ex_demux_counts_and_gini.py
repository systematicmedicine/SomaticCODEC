"""
--- test_ex_demux_counts_and_gini.py

Tests the script ex_demux_counts_and_gini.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import types
from rule_scripts.ex.processing_metrics.ex_demux_counts_and_gini import main
from helpers.get_metadata import load_config, get_ex_sample_ids

@pytest.mark.parametrize("demux_metrics, expected_gini", [
    ("tests/data/test_ex_demux_counts_and_gini/demux_metrics_gini_0.txt", 0.0),
    ("tests/data/test_ex_demux_counts_and_gini/demux_metrics_gini_0.25.txt", 0.25),
    ("tests/data/test_ex_demux_counts_and_gini/demux_metrics_gini_0.5.txt", 0.5),
])
def test_gini_coeff_calculation(lightweight_test_run, tmp_path, demux_metrics, expected_gini):

    # Load config
    config_yaml = load_config(lightweight_test_run["test_config_path"])

    # Get ex_sample IDs
    ex_sample_ids = get_ex_sample_ids(config_yaml)  
    
    args = types.SimpleNamespace(
        demux_metrics=demux_metrics,
        demux_gini=str(tmp_path / "demux_gini.json"),
        ex_sample_ids=ex_sample_ids,
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    with open(tmp_path / "demux_gini.json") as f:
        data = json.load(f)

    assert data["gini_coefficient"] == pytest.approx(expected_gini, abs=0.01)