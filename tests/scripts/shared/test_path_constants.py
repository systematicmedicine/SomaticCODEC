"""
--- test_path_constants.py ---

Guardrails for centralised path constants in definitions.paths.io.

Test 1: Uniqueness
- No two path constants (excluding MET*) may have the same string value.

Test 2: Naming rules (skipping certain names)
- Skip constants starting with "MET" (metrics files)
- If name contains BAM   → ".bam"   must be in the string
- If name contains SAM   → ".sam"   must be in the string
- If name contains FASTQ → ".fastq" must be in the string
- If name contains VCF   → ".vcf"   must be in the string
- If name contains BED   → ".bed"   must be in the string
- If name contains R1    → value must contain "r1" and NOT "r2"
- If name contains R2    → value must contain "r2" and NOT "r1"
"""

import importlib
import pkgutil
from collections import defaultdict

import pytest

pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(6),
]


def load_all_path_modules():
    package = importlib.import_module("definitions.paths.io")
    modules = []
    for module_info in pkgutil.iter_modules(package.__path__):
        full_name = f"definitions.paths.io.{module_info.name}"
        modules.append(importlib.import_module(full_name))
    return modules


def iter_path_constants():
    """
    Yield (fully_qualified_name, name, value) for uppercase string constants
    defined in definitions.paths.io.* modules.
    """
    for module in load_all_path_modules():
        for name, value in vars(module).items():
            if not name.isupper():
                continue
            if not isinstance(value, str):
                continue
            fq = f"{module.__name__}.{name}"
            yield fq, name, value


def test_path_constants_are_unique():
    """
    No two path constants may share the same string value.
    """

    value_to_names = defaultdict(list)

    for fq, name, value in iter_path_constants():
        value_to_names[value].append(fq)

    duplicates = {v: nms for v, nms in value_to_names.items() if len(nms) > 1}

    if duplicates:
        lines = []
        for value in sorted(duplicates.keys()):
            names = ", ".join(sorted(duplicates[value]))
            lines.append(f"{value}  <-  {names}")
        raise AssertionError(
            "Duplicate path constant values found:\n" + "\n".join(lines)
        )


def test_path_constants_follow_filename_rules():
    """
    Enforce extension and read-label conventions (skipping MET*).
    """
    offenders = []

    for fq, name, value in iter_path_constants():
        if name.startswith("MET"):
            continue

        # Extension checks
        if "BAM" in name and ".bam" not in value:
            offenders.append(f"{fq} = {value}")

        if "SAM" in name and ".sam" not in value:
            offenders.append(f"{fq} = {value}")

        if "FASTQ" in name and ".fastq" not in value:
            offenders.append(f"{fq} = {value}")

        if "VCF" in name and ".vcf" not in value:
            offenders.append(f"{fq} = {value}")

        if "BED" in name and ".bed" not in value:
            offenders.append(f"{fq} = {value}")

        # R1 / R2 checks
        if "R1" in name:
            if "r1" not in value or "r2" in value:
                offenders.append(f"{fq} = {value}")

        if "R2" in name:
            if "r2" not in value or "r1" in value:
                offenders.append(f"{fq} = {value}")

    assert not offenders, (
        "Path constants with filename mismatches:\n" + "\n".join(offenders)
    )