"""
--- test_component_metrics_report.py

Tests the rule component_metrics_report

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import scripts.get_metadata as md
import pandas as pd

# Test that metrics in the report match those in the config
def test_report_metrics_match_config_metrics(lightweight_test_run):
    # Load dataframes
    config = md.load_config("tests/configs/lightweight_test_run/config.yaml")
    component_metrics_df = pd.read_csv(config["component_metrics_path"])
    report_df = pd.read_csv("metrics/component_metrics_report.csv")

    # Create set of all metrics from config
    all_metrics = set(component_metrics_df[component_metrics_df["stage"] != "Library preparation"]["metric"])
    
    # Create set of metrics in report (removing sample prefix)
    report_metrics = set(report_df["metric"])

    # Find missing or unexpected metrics in report
    missing_metrics = all_metrics - report_metrics
    unexpected_metrics = report_metrics - all_metrics

    # Assert that metrics in the report match those in the config
    assert report_metrics == all_metrics, (
        f"Metrics not matched between config and report:\n"
        f"Missing from report:{missing_metrics}\n"
        f"Unexpected in report:{unexpected_metrics}\n"
    )

# Test that all samples are included in the component metrics report
def test_all_samples_in_report(lightweight_test_run):
    # Load config samples
    config = md.load_config("tests/configs/lightweight_test_run/config.yaml")
    ms_samples = md.get_ms_sample_ids(config)
    ex_samples = md.get_ex_sample_ids(config)
    ex_lanes = md.get_ex_lane_ids(config)

    # Create set of config sample names
    config_samples = set().union(ms_samples, ex_samples, ex_lanes)
    
    # Load report dataframe
    report_df = pd.read_csv("metrics/component_metrics_report.csv")

    # Create set of samples in report
    report_samples = set(report_df["sample"])

    # Find missing or unexpected samples in report
    missing_samples = config_samples - report_samples
    unexpected_samples = report_samples - config_samples

    # Assert that samples in the report match those in the config
    assert  report_samples == config_samples, (
        f"Samples not matched between config and report:\n"
        f"Missing from report:{missing_samples}\n"
        f"Unexpected in report:{unexpected_samples}\n"
    )



    