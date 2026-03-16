"""
--- resolve_path_constant.py ---

Resolves file paths from a paths constant and wildcards

Primarily used by non-python scripts that cannot natively access the definitions.paths package.

Author: Cameron Fraser
"""

from __future__ import annotations

from itertools import product
from typing import Iterable, List


def expand_pattern_to_paths(
    pattern: str,
    ex_lanes: Iterable[str],
    ex_samples: Iterable[str],
    ms_samples: Iterable[str],
) -> List[str]:
    """
    Expand a path-constant selector like "EX.MET_TRIM_FASTQ" into concrete file paths.

    Supported modules:
        EX -> definitions.paths.io.ex
        MS -> definitions.paths.io.ms
        S  -> definitions.paths.io.shared

    Supported wildcards:
        {ex_lane}
        {ex_sample}
        {ms_sample}

    Returns: list[str]
    """
    if "." not in pattern:
        raise ValueError(f"Pattern must look like 'EX.SOME_CONST', got: {pattern!r}")

    prefix, const_name = pattern.split(".", 1)

    module_map = {
        "EX": "definitions.paths.io.ex",
        "MS": "definitions.paths.io.ms",
        "S": "definitions.paths.io.shared",
    }

    if prefix not in module_map:
        raise ValueError(f"Unknown prefix {prefix!r} in pattern {pattern!r}")

    mod = __import__(module_map[prefix], fromlist=["*"])

    if not hasattr(mod, const_name):
        raise AttributeError(f"{module_map[prefix]} has no constant {const_name!r}")

    template = str(getattr(mod, const_name))

    wildcard_sources = {
        "ex_lane": list(ex_lanes),
        "ex_sample": list(ex_samples),
        "ms_sample": list(ms_samples),
    }

    keys = [k for k in wildcard_sources if f"{{{k}}}" in template]

    if not keys:
        return [template]

    axes = [wildcard_sources[k] for k in keys]

    paths: List[str] = []
    for values in product(*axes):
        wc = dict(zip(keys, values))
        paths.append(template.format(**wc))

    return paths