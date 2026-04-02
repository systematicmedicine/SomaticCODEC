"""
--- test_testing_coverage.py

Warns if any Snakemake rule under rules/** does not have a
corresponding test script under tests/scripts/**.

Also warns if any test script under tests/scripts/** is named like
test_<rule_name>.py but <rule_name> does not correspond to a rule.

Conventions:
- Rules live under: rules/** (any subdirectory)
- Tests live under: tests/scripts/** (any subdirectory)
- Tests that test a single rule must be named: test_<rule_name>.py
- Some rules may be intentionally excluded
- Some tests may be intentionally excluded (e.g. multi-rule tests)

Author:
    - Cameron Fraser
"""

import re
import warnings
from pathlib import Path
from typing import Set


RULES_DIR = Path("rules")
TESTS_DIR = Path("tests/scripts")

# Rules intentionally not tested (e.g. marker rules)
EXCLUDED_RULES: Set[str] = {
    "collate_benchmarks",
    "ensure_pipeline_log_exists",
    "write_git_metadata",
    "complete_setup",
    "ex_fastqc_filter_summary_metrics", # One test multiple rules
    "ex_fastqc_raw_summary_metrics", # One test multiple rules
    "ms_fastqc_summary_metrics", # One test multiple rules
    "ex_fastqcfilter_metrics", # Wrapper for external tool
    "ex_fastqcraw_metrics", # Wrapper for external tool
    "ms_raw_fastq_metrics", # Wrapper for external tool
    "ms_processed_fastq_metrics", # Wrapper for external tool
    "bwamem_index_files", # Wrapper for external tool
    "ex_alignment_metrics", # Wrapper for external tool
    "ex_insert_metrics", # Wrapper for external tool
    "ms_alignment_metrics", # Wrapper for external tool
    "ms_insert_metrics", # Wrapper for external tool
    "picard_sequence_dict", # Wrapper for external tool
    "samtools_index_files", # Wrapper for external tool
    "tabix_index_files", # Wrapper for external tool
    "ms_germ_risk_variant_metrics", # Wrapper for external tool
    "ms_multimapping_metrics", # One test multiple rules
    "ex_multimapping_raw_metrics", # One test multiple rules
    "ex_multimapping_dsc_metrics" # One test multiple rules
}

# Tests that do not correspond to a single rule name (e.g. multi-rule tests)
# These are the *name* portion from test_<name>.py
EXCLUDED_TEST_NAMES: Set[str] = {
    "docker",
    "dryrun",
    "expected_files",
    "experiment_sheets",
    "path_constants",
    "regex",
    "script_syntax",
    "environments",
    "profiles",
    "fastqc_summary_metrics", # One test multiple rules
    "multimapping_metrics" # One test multiple rules
}

RULE_DECL_RE = re.compile(r"(?m)^\s*rule\s+([A-Za-z_][A-Za-z0-9_]*)\s*:")


def collect_rule_names() -> Set[str]:
    rule_names: Set[str] = set()

    for path in RULES_DIR.rglob("*"):
        if not path.is_file():
            continue

        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = path.read_text(errors="replace")

        rule_names.update(RULE_DECL_RE.findall(text))

    return rule_names


def collect_test_rule_names() -> Set[str]:
    """
    Returns the set of names implied by tests named test_<name>.py.
    (The returned value is <name>, i.e. the part after 'test_'.)
    """
    names: Set[str] = set()

    for path in TESTS_DIR.rglob("test_*.py"):
        stem = path.stem  # e.g. test_combine_masks
        name = stem[len("test_") :]
        if name:
            names.add(name)

    return names


def test_testing_coverage():
    if not RULES_DIR.exists():
        raise AssertionError(f"Missing directory: {RULES_DIR}")

    if not TESTS_DIR.exists():
        raise AssertionError(f"Missing directory: {TESTS_DIR}")

    all_rules = collect_rule_names()
    all_rules_minus_exclusions = {r for r in all_rules if r not in EXCLUDED_RULES}

    test_names = collect_test_rule_names()
    test_names_minus_exclusions = {t for t in test_names if t not in EXCLUDED_TEST_NAMES}

    # 1) Rules missing tests
    missing_tests_for_rules = sorted(
        r for r in all_rules_minus_exclusions
        if r not in test_names
    )

    # 2) Tests that don't map to rules
    orphan_tests = sorted(
        t for t in test_names_minus_exclusions
        if t not in all_rules
    )

    warnings_out = []

    if missing_tests_for_rules:
        warnings_out.extend(
            [
                "Missing test scripts for the following rules:",
                *[f"  - {r} (expected: test_{r}.py)" for r in missing_tests_for_rules],
                "",
            ]
        )

    if orphan_tests:
        warnings_out.extend(
            [
                "Test scripts that do not match any rule name and are not whitelisted:",
                *[f"  - test_{t}.py" for t in orphan_tests],
                "",
                "If a test intentionally covers multiple rules (or is otherwise not 1:1),",
                "add its <name> (from test_<name>.py) to EXCLUDED_TEST_NAMES.",
            ]
        )

    if warnings_out:
        # One warning with a clean, readable multi-section message.
        warnings.warn("\n".join(warnings_out).rstrip(), UserWarning)