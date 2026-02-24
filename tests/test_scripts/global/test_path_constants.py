"""
--- test_path_constants.py ---

Simple guardrail for centralised path constants.

For all uppercase string constants in definitions.paths.io:
    - Skip constants starting with "MET" (metrics files)
    - If name contains BAM   → ".bam"   must be in the string
    - If name contains SAM   → ".sam"   must be in the string
    - If name contains FASTQ → ".fastq" must be in the string
    - If name contains VCF   → ".vcf"   must be in the string
    - If name contains BED   → ".bed"   must be in the string
"""

import importlib
import pkgutil
import pytest

# Pytest marking
pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(6)
]


def load_all_path_modules():
    package = importlib.import_module("definitions.paths.io")
    modules = []

    for module_info in pkgutil.iter_modules(package.__path__):
        full_name = f"definitions.paths.io.{module_info.name}"
        modules.append(importlib.import_module(full_name))

    return modules


def test_path_constant_extensions():

    modules = load_all_path_modules()
    offenders = []

    for module in modules:
        for name, value in vars(module).items():

            if not name.isupper():
                continue

            if not isinstance(value, str):
                continue

            # Skip metrics constants
            if name.startswith("MET"):
                continue

            if "BAM" in name and ".bam" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "SAM" in name and ".sam" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "FASTQ" in name and ".fastq" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "VCF" in name and ".vcf" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "BED" in name and ".bed" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

    assert not offenders, (
        "Path constants with mismatched extensions:\n" +
        "\n".join(offenders)
    )
