"""
--- test_expected_files.py ---

Tests:
1. Test if all expected files have been created
2. Test if any unexpected files have been created
3. Test if created files have nonzero size
4. Test if created files contain valid datapoints

Author: Cameron Fraser

"""

# ------------------------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------------------------
from __future__ import annotations
from helpers.get_metadata import load_config as _load_config
import helpers.get_metadata as md
from helpers.count_data_points import count_data_points
from pathlib import Path
import string
import importlib
import itertools
import pytest

pytestmark = pytest.mark.order(9)

# ------------------------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------------------------

# Load lightweight_test_run config
def load_config(lightweight_test_run):
    cfg_path = lightweight_test_run["test_config_path"]
    return _load_config(cfg_path)

# Create a list of all files created by the pipeline
def file_manifest() -> list[str]:
    roots = ["tmp", "metrics", "results", "logs"]
    out = set()

    for root in roots:
        root_path = Path(root)
        if not root_path.exists():
            continue

        for path in root_path.rglob("*"):
            if not path.is_file():
                continue

            # Skip hidden files and runtime artefacts
            if any(part.startswith(".") for part in path.parts):
                continue
            if "__pycache__" in path.parts:
                continue
            if ".snakemake" in path.parts:
                continue

            out.add(str(path))

    return sorted(out)

# Collate list of expected files from config
def expected_from_config(config) -> list[str]:
    rf = config["sci_params"]["reference_files"]
    ref = Path(rf["genome"])
    gnomad = Path(rf["germline_variants"])

    paths = {
        # Reference genome & indicies
        str(ref),
        str(ref.with_suffix(".dict")),
        str(ref) + ".fai",
        str(ref) + ".0123",
        str(ref) + ".amb",
        str(ref) + ".ann",
        str(ref) + ".bwt.2bit.64",
        str(ref) + ".pac",

        # gnomAD VCF & index
        str(gnomad),
        str(gnomad) + ".tbi",

        # Trinucleotide contexts
        str(rf["tri_contexts"]),
        str(rf["genome_trinuc_counts"]),

        # Precomputed masks
        *rf.get("precomputed_masks", []),
    }

    return sorted(p for p in paths if p)


# Collate list of raw FASTQ files
def expected_from_metadata(config) -> list[str]:
    paths = set()

    # EX lane FASTQs
    for r1, r2 in md.get_ex_lane_fastqs(config).values():
        paths.update([r1, r2])

    # MS sample FASTQs
    for r1, r2 in md.get_ms_sample_fastqs(config).values():
        paths.update([r1, r2])

    return sorted(p for p in paths if p)


# Collate list of expected files from paths package
def expected_from_paths_package(config) -> list[str]:
    from helpers.get_metadata import (
        get_ex_lane_ids,
        get_ex_sample_ids,
        get_ms_sample_ids,
    )

    values = {
        "ex_lane": list(get_ex_lane_ids(config)),
        "ex_sample": list(get_ex_sample_ids(config)),
        "ms_sample": list(get_ms_sample_ids(config)),
    }

    modules = (
        "definitions.paths.io.ex",
        "definitions.paths.io.ms",
        "definitions.paths.io.shared",
        "definitions.paths.log",
        "definitions.paths.benchmark"
    )

    fmt = string.Formatter()
    out = set()

    for mod in modules:
        for name, tpl in vars(importlib.import_module(mod)).items():
            if name.startswith("_") or not isinstance(tpl, str):
                continue

            # Skip rule which does not run if pipeline log exists
            if "ensure_pipeline_log_exists" in tpl:
                continue

            fields = {f for _, f, _, _ in fmt.parse(tpl) if f}

            if not fields:
                out.add(tpl)
                continue

            if fields - values.keys():
                raise ValueError(f"Unsupported wildcards in {mod}.{name}")

            for combo in itertools.product(*(values[k] for k in sorted(fields))):
                out.add(tpl.format(**dict(zip(sorted(fields), combo))))

    return sorted(out)

# Collate list of all expected files
def expected_files(config) -> list[str]:
    return sorted({
        *expected_from_paths_package(config),
        *expected_from_config(config),
        *expected_from_metadata(config),
    })


# ------------------------------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------------------------------

# (1) Test if all expected files have been created
def test_expected_files_exist(lightweight_test_run):
    config = load_config(lightweight_test_run)

    expected = set(expected_files(config))
    actual = set(file_manifest())

    assert expected == actual, (
        "File manifest mismatch:\n\n"
        f"Missing:\n{chr(10).join(sorted(expected - actual))}\n\n"
        f"Unexpected:\n{chr(10).join(sorted(actual - expected))}"
    )


# (2) Test if any unexpected files have been created
def test_unexpected_files(lightweight_test_run):
    config = load_config(lightweight_test_run)

    expected = set(expected_files(config))
    actual = set(file_manifest())

    unexpected = sorted(actual - expected)

    assert not unexpected, (
        "Unexpected files found:\n\n" +
        "\n".join(unexpected)
    )


# (3) Test that files have nonzero size
def test_nonzero_size():
    zero_size = []

    for path in file_manifest():
        # Skip log/benchmark files
        if Path(path).parts[0] == "logs":
            continue

        # Add zero-size files to list
        if Path(path).stat().st_size == 0:
            zero_size.append(path)

    assert not zero_size, (
        "Zero-size files detected:\n\n" +
        "\n".join(sorted(zero_size))
    )


# (4) Test that files have valid datapoints
def test_has_datapoints():
    empty_files = []
    errors = []

    for path in file_manifest():
        result = count_data_points(path)

        # Skip unsupported file types
        if isinstance(result, str):
            continue

        # Defensive: unexpected return type
        if not isinstance(result, int):
            errors.append(f"{path} -> unexpected return: {result}")
            continue

        if result == 0:
            empty_files.append(path)

    assert not errors, (
        "Errors during data point counting:\n\n" +
        "\n".join(sorted(errors))
    )

    assert not empty_files, (
        "Files contain zero data points:\n\n" +
        "\n".join(sorted(empty_files))
    )