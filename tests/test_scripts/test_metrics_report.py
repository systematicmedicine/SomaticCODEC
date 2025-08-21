"""
--- test metrics report.py ---

Test the metrics report generated at the end of the pipeline

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
import os
import sys
import pytest
import pandas as pd
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

import scripts.get_metadata as md

# -------------------------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------------------------

@pytest.fixture(scope="module")
def config():
    return md.load_config("config/config.yaml")

@pytest.fixture(scope="module")
def metrics_df():
    metrics_path = os.path.join("metrics", "metrics_report.csv")
    return pd.read_csv(metrics_path)

@pytest.fixture(scope="module")
def component_metrics():
    component_metrics_path = os.path.join("config", "component_level_metrics.xlsx")
    df = pd.read_excel(component_metrics_path)
    return set(df["Name"].dropna().unique())

@pytest.fixture(scope="module")
def system_metrics():
    system_metrics_path = os.path.join("config", "system_level_metrics.xlsx")
    df = pd.read_excel(system_metrics_path)
    return set(df["Name"].dropna().unique())

# -------------------------------------------------------------------------------------
# Tests
# -------------------------------------------------------------------------------------

# Test that there are the same number of entries for each ex sample
def test_ex_samples_uniform(lightweight_test_run, config, metrics_df):
    ex_sample_ids = md.get_ex_sample_ids(config)
    ex_samples_df = metrics_df[metrics_df['Sample'].isin(ex_sample_ids)]
    ex_sample_counts = ex_samples_df['Sample'].value_counts()
    assert len(set(ex_sample_counts)) == 1, f"ex_samples have unequal counts: {ex_sample_counts.to_dict()}"

# Test that there are the same number of entries for each ms sample
def test_ms_samples_uniform(lightweight_test_run, config, metrics_df):
    ms_sample_ids = md.get_ms_sample_ids(config)
    ms_samples_df = metrics_df[metrics_df['Sample'].isin(ms_sample_ids)]
    ms_sample_counts = ms_samples_df['Sample'].value_counts()
    assert len(set(ms_sample_counts)) == 1, f"ms_samples have unequal counts: {ms_sample_counts.to_dict()}"

# Test that there are the same number of entries for each ex lane
def test_ex_lanes_uniform(lightweight_test_run, config, metrics_df):
    ex_lane_ids = md.get_ex_lane_ids(config)
    ex_lanes_df = metrics_df[metrics_df['Sample'].isin(ex_lane_ids)]
    ex_lane_counts = ex_lanes_df['Sample'].value_counts()
    assert len(set(ex_lane_counts)) == 1, f"ex_lanes have unequal counts: {ex_lane_counts.to_dict()}"

# Test that all metrics defined in the component and system metrics spreadsheets are present in the report
def test_expected_metrics_present(lightweight_test_run, metrics_df):
    
    reported = set(
        metrics_df["Metric"]
        .dropna()
        .astype(str)
        .str.strip()
        .unique()
    )

    comp_df = pd.read_excel(os.path.join("config", "component_level_metrics.xlsx"))
    sys_df  = pd.read_excel(os.path.join("config", "system_level_metrics.xlsx"))

    expected_present = pd.concat([
        comp_df.loc[comp_df["include_automated_report"].fillna(False), "Name"],
        sys_df.loc[sys_df["include_automated_report"].fillna(False), "Name"],
    ], ignore_index=True)

    expected = set(
        expected_present
        .dropna()
        .astype(str)
        .str.strip()
        .unique()
    )

    missing = sorted(expected - reported)
    assert not missing, f"Missing metrics (expected but not found): {missing}"

# Test that no more than 20% of grades are NA
def test_grade_na_ratio(lightweight_test_run, metrics_df):
    na_ratio = (metrics_df["Grade"] == "NA").mean()
    assert na_ratio <= 0.20, f"Too many 'NA' grades: {na_ratio:.2%} of entries"
