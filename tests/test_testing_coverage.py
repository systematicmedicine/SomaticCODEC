"""
--- test_testing_coverage.py

Warns if any Snakemake rule under rules/** does not have a
corresponding test script under tests/scripts/**.

Conventions:
- Rules live under: rules/** (any subdirectory)
- Tests live under: tests/scripts/** (any subdirectory)
- Tests that test a rule must be named: test_<rule_name>.py
- Some rules may be intentionally excluded

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
    "bwamem_index_files",
    "collate_benchmarks",
    "create_run_timeline_plot",
    "ensure_pipeline_log_exists",
    "write_git_metadata"
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

        matches = RULE_DECL_RE.findall(text)
        rule_names.update(matches)

    return rule_names


def collect_test_rule_names() -> Set[str]:
    rule_names: Set[str] = set()

    for path in TESTS_DIR.rglob("test_*.py"):
        stem = path.stem  # e.g. test_combine_masks
        rule_name = stem[len("test_") :]
        if rule_name:
            rule_names.add(rule_name)

    return rule_names


def test_testing_coverage():
    if not RULES_DIR.exists():
        raise AssertionError(f"Missing directory: {RULES_DIR}")

    if not TESTS_DIR.exists():
        raise AssertionError(f"Missing directory: {TESTS_DIR}")

    all_rules = collect_rule_names()
    tested_rules = collect_test_rule_names()

    missing = sorted(
        r for r in all_rules
        if r not in tested_rules and r not in EXCLUDED_RULES
    )

    if missing:
        message = [
            "Missing test scripts for the following rules:",
            *[f"  - {r} (expected: test_{r}.py)" for r in missing],
        ]
        warnings.warn("\n".join(message), UserWarning)