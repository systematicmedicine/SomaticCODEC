#!/usr/bin/env python3

"""
visualise_rulegraph.py

Authors:
    - Chat-GPT
    - Cameron Fraser

Render a Snakemake rulegraph for inspection and documentation.

This script is a read-only, standalone introspection tool. It visualises the
dependency structure (DAG) required to build a specific pipeline target, without
executing any pipeline rules or performing any real data processing.

Key properties:
- Not part of the core pipeline contract
- Does not run or modify the pipeline
- Uses temporary stub files and a temporary symlink for graph generation only
- Produces a human-readable rulegraph (PDF) for documentation and review

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

import csv
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from datetime import date
import yaml


def merge_existing(base, dev):
    """Deep-merge dev into base, but ONLY for keys already present in base."""
    if isinstance(base, dict) and isinstance(dev, dict):
        out = dict(base)
        for k, v in dev.items():
            if k not in base:
                continue
            out[k] = merge_existing(base[k], v)
        return out
    return dev


def touch_downloads(download_list_csv: Path, downloads_root: Path) -> None:
    with download_list_csv.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        _ = next(reader, None)  # header
        for row in reader:
            if not row:
                continue
            fname = row[0].strip().strip('"').strip("'")
            if not fname:
                continue
            rel = fname[len("tmp/downloads/") :] if fname.startswith("tmp/downloads/") else fname
            p = downloads_root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.touch(exist_ok=True)


def extract_dot(text: str) -> str | None:
    """
    Extract the DOT digraph from mixed stdout.
    Looks for the first 'digraph ... { ... }' block.
    """
    m = re.search(r"(digraph\s+[^{]*\{.*\}\s*)", text, flags=re.DOTALL)
    return m.group(1) if m else None


def main() -> int:
    snakefile = Path("Snakefile")
    config_base = Path("config/config.yaml")
    config_dev = Path("config/config.dev.yaml")
    downloads_link = Path("tmp/downloads")

    target_rule = "called_variants"
    today = date.today().strftime("%Y%m%d")
    pdf_out = Path("docs") / "rulegraphs" / f"{today}_called_variants_rulegraph.pdf"
    pdf_out.parent.mkdir(parents=True, exist_ok=True)

    for p in (snakefile, config_base, config_dev):
        if not p.exists():
            print(f"ERROR: missing {p}", file=sys.stderr)
            return 2

    base = yaml.safe_load(config_base.read_text(encoding="utf-8")) or {}
    dev = yaml.safe_load(config_dev.read_text(encoding="utf-8")) or {}
    merged = merge_existing(base, dev)

    download_list_csv = Path((base.get("metadata", {}) or {}).get("download_list", "config/download_list.csv"))
    if not download_list_csv.exists():
        print(f"ERROR: missing download list CSV: {download_list_csv}", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory() as tmpdir_str:
        tmpdir = Path(tmpdir_str)
        stub_downloads = tmpdir / "downloads"
        stub_downloads.mkdir(parents=True, exist_ok=True)

        # symlink tmp/downloads -> temp/downloads
        downloads_link.parent.mkdir(parents=True, exist_ok=True)
        if downloads_link.exists() and not downloads_link.is_symlink():
            print(f"ERROR: {downloads_link} exists and is not a symlink. Refusing.", file=sys.stderr)
            return 2
        if downloads_link.exists() or downloads_link.is_symlink():
            downloads_link.unlink()
        downloads_link.symlink_to(stub_downloads)

        try:
            touch_downloads(download_list_csv, stub_downloads)

            merged_cfg = tmpdir / "config.merged.yaml"
            merged_cfg.write_text(yaml.safe_dump(merged, sort_keys=False), encoding="utf-8")

            # Run snakemake and capture mixed stdout/stderr
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
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )

            # If snakemake failed, show stderr
            if proc.returncode != 0:
                print(proc.stderr, file=sys.stderr)
                return proc.returncode

            dot_text = extract_dot(proc.stdout)
            if not dot_text:
                # Some setups print graph to stderr instead; try that too
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

            subprocess.run(
                ["dot", "-Tpdf", str(dot_path)],
                check=True,
                stdout=pdf_out.open("wb"),
            )

            print(f"Wrote: {pdf_out}")
            return 0

        finally:
            if downloads_link.is_symlink():
                downloads_link.unlink()


if __name__ == "__main__":
    raise SystemExit(main())
