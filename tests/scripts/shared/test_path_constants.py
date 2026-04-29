"""
--- test_path_constants.py ---

Guardrails for centralised path constants in definitions.paths.*

Checks:
1) No duplicate constant values.
2) R1/R2 naming consistency for all constants.
3) Metrics constants (name contains "MET"):
   - must end with an acceptable extension
4/5) Log/benchmark constants must contain the same name as the constant name
6) Non-metrics/log/benchmark constants:
   - extension expectations based on name tokens (BAM/SAM/FASTQ/VCF/BED)
   - must end with an acceptable extension

Authors: 
    - Cameron Fraser
    - Joshua Johnstone
"""

from __future__ import annotations
import importlib
import pkgutil
from collections import defaultdict
import pytest
from pathlib import Path

pytestmark = [
    pytest.mark.quicktests,
    pytest.mark.order(7),
]

NON_MET_ALLOWED_SUFFIXES = (
    ".fastq",
    ".fasta",
    ".gz",
    ".bam",
    ".bai",
    ".vcf",
    ".sam",
    ".bed",
    ".bcf"
)

MET_ALLOWED_SUFFIXES = (
    ".txt",
    ".json",
    ".html",
    ".pdf",
    ".png",
    ".zip",
    ".bgz",
    ".bgz.tbi",
    ".vcf",
    ".csv"
)


def _iter_io_constants():
    """
    Yield (fq_name, const_name, value) for uppercase string constants
    in definitions.paths.* modules.
    """
    package = importlib.import_module("definitions.paths")
    for module_info in pkgutil.walk_packages(package.__path__, package.__name__ + "."):
        mod = importlib.import_module(module_info.name)
        for name, value in vars(mod).items():
            if name.isupper() and isinstance(value, str):
                yield f"{mod.__name__}.{name}", name, value


def _endswith_any(value: str, suffixes: tuple[str, ...]) -> bool:
    return any(value.endswith(s) for s in suffixes)


def test_path_constants_guardrails():
    offenders: list[str] = []

    # 1) No duplicate values
    value_to_names = defaultdict(list)
    constants = list(_iter_io_constants())
    for fq, name, value in constants:
        value_to_names[value].append(fq)

    dupes = {v: nms for v, nms in value_to_names.items() if len(nms) > 1}
    for value in sorted(dupes.keys()):
        offenders.append(f"Duplicate value: {value} <- {', '.join(sorted(dupes[value]))}")

    # 2-5) Per-constant checks
    for fq, name, value in constants:
        is_met = name.startswith("MET")
        is_log = fq.startswith("definitions.paths.log.")
        is_benchmark = fq.startswith("definitions.paths.benchmark.")

        # 2) R1 / R2 rules (apply to all constants)
        if "R1" in name:
            if "r1" not in value.lower() or "r2" in value.lower():
                offenders.append(f"{fq}: name implies R1 but value is '{value}'")

        if "R2" in name:
            if "r2" not in value.lower() or "r1" in value.lower():
                offenders.append(f"{fq}: name implies R2 but value is '{value}'")
       
        if is_met:
            # 3) MET rules
            if not _endswith_any(value, MET_ALLOWED_SUFFIXES):
                offenders.append(
                    f"{fq}: MET path must end with one of {MET_ALLOWED_SUFFIXES} -> '{value}'"
                )

        elif is_log:
            # 4) Log rules
            if "DONE" in name:
                if not (Path(value).stem).lower() + "_done" == name.lower():
                    offenders.append(
                        f"{fq}: Log filename '{(Path(value).stem).lower() + '_done'}' must match log constant name '{name}'"
                    )

            elif not (Path(value).stem).lower() == name.lower():
                offenders.append(
                    f"{fq}: Log filename '{(Path(value).stem).lower()}' must match constant name '{name}'"
                )

        elif is_benchmark:
            # 5) Benchmark rules
            if not (Path(value).stem.rsplit('.', 1)[0]).lower() == name.lower():
                    offenders.append(
                        f"{fq}: Benchmark filename '{(Path(value).stem.rsplit('.', 1)[0]).lower()}' must match constant name '{name}'"
                    )   

        else:
            # 6) Non-metrics/log/benchmark rules
            if "BAM" in name and ".bam" not in value:
                offenders.append(f"{fq}: name contains BAM but '.bam' not in value -> '{value}'")

            if "SAM" in name and ".sam" not in value:
                offenders.append(f"{fq}: name contains SAM but '.sam' not in value -> '{value}'")

            if "FASTQ" in name and ".fastq" not in value:
                offenders.append(f"{fq}: name contains FASTQ but '.fastq' not in value -> '{value}'")

            if "VCF" in name and ".vcf" not in value:
                offenders.append(f"{fq}: name contains VCF but '.vcf' not in value -> '{value}'")

            if "BED" in name and ".bed" not in value:
                offenders.append(f"{fq}: name contains BED but '.bed' not in value -> '{value}'")

            if not _endswith_any(value, NON_MET_ALLOWED_SUFFIXES):
                offenders.append(
                    f"{fq}: non-MET path must end with one of {NON_MET_ALLOWED_SUFFIXES} -> '{value}'"
                )

    assert not offenders, "Path constant guardrail failures:\n" + "\n".join(offenders)
