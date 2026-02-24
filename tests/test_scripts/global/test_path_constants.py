"""
--- test_path_constants.py ---

Simple guardrail for centralised path constants.

Rules:
- Skip constants starting with "MET" (metrics files)
- If name contains BAM   → ".bam"   must be in the string
- If name contains SAM   → ".sam"   must be in the string
- If name contains DSC   → ".bam"   must be in the string 
- If name contains FASTQ → ".fastq" must be in the string
- If name contains VCF   → ".vcf"   must be in the string
- If name contains BED   → ".bed"   must be in the string
- If name contains R1    → value must contain "r1" and NOT "r2"
- If name contains R2    → value must contain "r2" and NOT "r1"
"""

import importlib
import pkgutil


def load_all_path_modules():
    package = importlib.import_module("definitions.paths.io")
    modules = []

    for module_info in pkgutil.iter_modules(package.__path__):
        full_name = f"definitions.paths.io.{module_info.name}"
        modules.append(importlib.import_module(full_name))

    return modules


def test_path_constant_extensions_and_read_labels():

    modules = load_all_path_modules()
    offenders = []

    for module in modules:
        for name, value in vars(module).items():

            if not name.isupper():
                continue

            if not isinstance(value, str):
                continue

            if name.startswith("MET"):
                continue

            # Extension checks
            if "BAM" in name and ".bam" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "SAM" in name and ".sam" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "DSC" in name and ".bam" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "FASTQ" in name and ".fastq" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "VCF" in name and ".vcf" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            if "BED" in name and ".bed" not in value:
                offenders.append(f"{module.__name__}.{name} = {value}")

            # R1 / R2 checks
            if "R1" in name:
                if "r1" not in value or "r2" in value:
                    offenders.append(f"{module.__name__}.{name} = {value}")

            if "R2" in name:
                if "r2" not in value or "r1" in value:
                    offenders.append(f"{module.__name__}.{name} = {value}")

    assert not offenders, (
        "Path constants with mismatches:\n" +
        "\n".join(offenders)
    )
