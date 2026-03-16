"""
--- test_regex.py ---

1. Tests all regexes return correct values
2. Tests that all omponent metrics that use regexes, are tested by this test

To add additional test cases, update:

tests\\expected\\test_regex\\regex_expected_values.csv

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
import os
import pytest
import pandas as pd
import sys
from pathlib import Path
from rpy2 import robjects
from rpy2.robjects.packages import importr
from rpy2.robjects.conversion import localconverter
from rpy2.robjects import default_converter
from rpy2.robjects import pandas2ri

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(4)
]

# Define paths
from conftest import PROJECT_ROOT
CSV_PATH = os.path.join(PROJECT_ROOT, 'tests', 'expected', 'test_regex', 'regex_expected_values.csv')
COMPONENT_XLSX = os.path.join(PROJECT_ROOT, 'config', 'component_level_metrics.xlsx')
SYSTEM_XLSX = os.path.join(PROJECT_ROOT, 'config', 'system_level_metrics.xlsx')
R_SCRIPT_PATH = os.path.join(PROJECT_ROOT, 'rule_scripts/shared/metrics', 'create_metrics_report_functions.R')

# Load R script
robjects.r.source(R_SCRIPT_PATH)
get_metric_txt = robjects.globalenv['get_metric_txt']

# Load expected values and config
expected_df = pd.read_csv(CSV_PATH)
component_df = pd.read_excel(COMPONENT_XLSX)
system_df = pd.read_excel(SYSTEM_XLSX)
config_df = pd.concat([component_df, system_df], ignore_index=True)


def build_test_cases():
    merged = expected_df.merge(config_df[['Name', 'value_pattern']],
                               left_on='Metric', right_on='Name', how='left')

    if merged['value_pattern'].isnull().any():
        missing = merged[merged['value_pattern'].isnull()]
        raise ValueError(f"Missing regex pattern for the following metrics:\n{missing[['Metric', 'File_path']]}")

    return [
        (row['Metric'], row['File_path'], row['value_pattern'], row['Expected'])
        for _, row in merged.iterrows()
    ]


@pytest.mark.parametrize("metric, file_path, pattern, expected", build_test_cases())
def test_regex_matches_expected(metric, file_path, pattern, expected):
    abs_file_path = os.path.join(PROJECT_ROOT, file_path)

    try:
        # Call R function and use appropriate conversion context
        with localconverter(default_converter + pandas2ri.converter):
            result = get_metric_txt(abs_file_path, pattern)[0]
    except Exception as e:
        raise RuntimeError(f"Error calling R function for {metric} in {file_path}: {e}")

    assert str(result) == str(expected), f"Mismatch for {metric} in {file_path}: expected '{expected}', got '{result}'"


def test_all_regexes_tested():
    # Filter config for metrics with file_path ending in '.txt'
    txt_metrics = config_df[config_df['file_pattern'].str.endswith(('.txt', '.csv'), na=False)]

    # Get the set of metrics present in expected values CSV
    expected_metrics = set(expected_df['Metric'])

    # Get the set of metrics with txt files in config
    txt_metrics_set = set(txt_metrics['Name'])

    # Find any metrics with txt files missing from expected values
    missing_metrics = txt_metrics_set - expected_metrics

    assert not missing_metrics, (
        f"The following metrics use regexes but are not included in regex test:\n"
        f"{missing_metrics}"
    )
