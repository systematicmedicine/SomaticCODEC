"""
--- test_ex_demux_counts_and_gini.py

Tests the script ex_demux_counts_and_gini.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
from pathlib import Path
import types
from scripts.ex.processing_metrics.ex_demux_counts_and_gini import main
from helpers.get_metadata import load_config

@pytest.mark.parametrize("demux_metrics, expected_gini", [
    ("tests/data/test_ex_demux_counts_and_gini/demux_metrics_gini_0.txt", 0.0),
    ("tests/data/test_ex_demux_counts_and_gini/demux_metrics_gini_0.25.txt", 0.25),
    ("tests/data/test_ex_demux_counts_and_gini/demux_metrics_gini_0.5.txt", 0.5),
])
def test_gini_coeff_calculation(tmp_path, demux_metrics, expected_gini):

    # Create config JSON for script to use
    config_yaml = load_config("config/config.yaml")
    
    config_json = json.dumps(config_yaml)  
    
    args = types.SimpleNamespace(
        demux_metrics=demux_metrics,
        demux_gini=str(tmp_path / "demux_gini.json"),
        config=config_json,
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    with open(tmp_path / "demux_gini.json") as f:
        data = json.load(f)

    assert data["gini_coefficient"] == pytest.approx(expected_gini, abs=0.01)