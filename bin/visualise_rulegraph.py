#!/usr/bin/env python3

"""
visualise_rulegraph.py

Authors:
    - Cameron Fraser

Render a Snakemake rulegraph for inspection and documentation.

This script is a read-only, standalone introspection tool. It visualises the
dependency structure (DAG) required to build a specific pipeline target, without
executing any pipeline rules or performing any real data processing.

Key properties:
- Not part of the core pipeline contract
- Does not run or modify the pipeline
- Uses temporary stub files and a temporary symlink for graph generation only
- Produces a human-readable rulegraph (SVG) for documentation and review

Intended use:
- Understanding pipeline structure and dependencies
- Reviewing changes to rule dependencies
- Generating documentation artefacts (e.g. for design discussions or reviews)

Not intended for:
- Pipeline execution
- Performance benchmarking
- Scientific or production runs
"""

from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

import yaml


def merge_existing(base, dev):
    """Deep-merge dev into base, but only for keys already present in base."""
    if isinstance(base, dict) and isinstance(dev, dict):
        out = dict(base)
        for k, v in dev.items():
            if k not in base:
                continue
            out[k] = merge_existing(base[k], v)
        return out
    return dev


def touch_lightweight_test_downloads(project_root: Path, downloads_root: Path) -> None:
    """Create empty placeholder download files based on lightweight_test_run."""
    src_dir = project_root / "tests" / "data" / "lightweight_test_run" / "downloads"

    if not src_dir.exists():
        raise FileNotFoundError(
            f"Lightweight test downloads directory not found: {src_dir}"
        )

    files_to_create = [f for f in src_dir.glob("*") if f.name != ".gitkeep"]

    for src in files_to_create:
        dst = downloads_root / src.name
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.touch(exist_ok=True)


def extract_dot(text: str) -> str | None:
    """
    Extract the DOT digraph from mixed stdout/stderr.
    Looks for the first 'digraph ... { ... }' block.
    """
    m = re.search(r"(digraph\s+[^{]*\{.*\}\s*)", text, flags=re.DOTALL)
    return m.group(1) if m else None


def main() -> int:
    project_root = Path.cwd()
    snakefile = project_root / "Snakefile"
    config_base = project_root / "config" / "config.yaml"
    config_dev = project_root / "config" / "config.dev.yaml"
    downloads_link = project_root / "tmp" / "downloads"

    target_rule = "called_variants"
    today = date.today().strftime("%Y%m%d")
    svg_out = project_root / "docs" / "development" / "variant_calling_rulegraph.svg"
    svg_out.parent.mkdir(parents=True, exist_ok=True)

    for p in (snakefile, config_base, config_dev):
        if not p.exists():
            print(f"ERROR: missing {p}", file=sys.stderr)
            return 2

    base = yaml.safe_load(config_base.read_text(encoding="utf-8")) or {}
    dev = yaml.safe_load(config_dev.read_text(encoding="utf-8")) or {}
    merged = merge_existing(base, dev)

    with tempfile.TemporaryDirectory() as tmpdir_str:
        tmpdir = Path(tmpdir_str)
        stub_downloads = tmpdir / "downloads"
        stub_downloads.mkdir(parents=True, exist_ok=True)

        downloads_link.parent.mkdir(parents=True, exist_ok=True)
        if downloads_link.exists() and not downloads_link.is_symlink():
            print(f"ERROR: {downloads_link} exists and is not a symlink. Refusing.", file=sys.stderr)
            return 2
        if downloads_link.exists() or downloads_link.is_symlink():
            downloads_link.unlink()
        downloads_link.symlink_to(stub_downloads)

        try:
            touch_lightweight_test_downloads(project_root, stub_downloads)

            merged_cfg = tmpdir / "config.merged.yaml"
            merged_cfg.write_text(
                yaml.safe_dump(merged, sort_keys=False),
                encoding="utf-8",
            )

            proc = subprocess.run(
                [
                    "snakemake",
                    "-s",
                    str(snakefile),
                    "--rulegraph",
                    target_rule,
                    "--configfile",
                    str(merged_cfg),
                ],
                cwd=str(project_root),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )

            if proc.returncode != 0:
                print(proc.stderr, file=sys.stderr)
                return proc.returncode

            dot_text = extract_dot(proc.stdout)
            if not dot_text:
                dot_text = extract_dot(proc.stderr)

            if not dot_text:
                print("ERROR: Could not find DOT 'digraph {...}' in Snakemake output.", file=sys.stderr)
                print("---- stdout (first 500 chars) ----", file=sys.stderr)
                print(proc.stdout[:500], file=sys.stderr)
                print("---- stderr (first 500 chars) ----", file=sys.stderr)
                print(proc.stderr[:500], file=sys.stderr)
                return 1

            dot_path = tmpdir / "rulegraph.dot"
            dot_path.write_text(dot_text, encoding="utf-8")

            with svg_out.open("wb") as f:
                subprocess.run(
                    ["dot", "-Tsvg", str(dot_path)],
                    check=True,
                    stdout=f,
                )

            print(f"Wrote: {svg_out}")
            return 0

        finally:
            if downloads_link.is_symlink():
                downloads_link.unlink()


if __name__ == "__main__":
    raise SystemExit(main())