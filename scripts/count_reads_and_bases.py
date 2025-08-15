#!/usr/bin/env python3
"""
Count reads and bases for FASTQ and BAM files under PROJECT_ROOT/tmp.

- Finds *.fastq.gz and *.bam (excluding anything in tmp/downloads).
- Sample name = first-level subdirectory under tmp (e.g., tmp/S001/* -> sample "S001").
- Uses seqkit (FASTQ) and samtools (BAM) for counts.
- Writes one JSON per sample at tmp/<sample>/<sample>_read_base_counts.json.
- Only counts primary alignments in BAM files

Requirements:
  - seqkit (>=2.x recommended)
  - samtools (>=1.10 recommended)

Usage:
  python scripts/summarize_reads_and_bases.py --project-root . [--threads 4]

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
from __future__ import annotations
import json
import os
import shlex
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Define hard coded variables
FASTQ_EXTS = {".fastq.gz"}
BAM_EXTS = {".bam"}
PRIMARY_ONLY_FILTER = 0x100 | 0x800  # exclude secondary (0x100) and supplementary (0x800)

def run_cmd(cmd: List[str], capture_stderr: bool = True) -> str:
    try:
        proc = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE if capture_stderr else None,
            text=True,
        )
        return proc.stdout
    except FileNotFoundError as e:
        raise RuntimeError(f"Missing required tool: {cmd[0]!r}") from e
    except subprocess.CalledProcessError as e:
        stderr = e.stderr.strip() if e.stderr else ""
        raise RuntimeError(
            f"Command failed: {shlex.join(cmd)}\nExit code: {e.returncode}\nStderr:\n{stderr}"
        ) from e


# ---------------- FASTQ ----------------
def count_fastq_with_seqkit(fastq_path: Path) -> Tuple[int, int]:
    cmd = ["seqkit", "stats", "-Ta", str(fastq_path)]
    out = run_cmd(cmd)
    lines = [ln for ln in out.splitlines() if ln.strip()]
    if len(lines) < 2:
        raise RuntimeError(f"Unexpected seqkit stats output for {fastq_path}: {out}")

    header = lines[0].split("\t")
    row = lines[1].split("\t")
    try:
        idx_num = header.index("num_seqs")
        idx_sum = header.index("sum_len")
    except ValueError:
        idx_num, idx_sum = 3, 4
    return int(row[idx_num]), int(row[idx_sum])


# ---------------- BAM ----------------
def count_bam_reads(bam_path: Path, threads: int = 1) -> int:
    cmd = ["samtools", "view", "-@", str(threads), "-c", "-F", str(PRIMARY_ONLY_FILTER), str(bam_path)]
    out = run_cmd(cmd)
    return int(out.strip())


def count_bam_bases_from_sequences(bam_path: Path, threads: int = 1) -> int:
    cmd = ["samtools", "view", "-@", str(threads), "-F", str(PRIMARY_ONLY_FILTER), str(bam_path)]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    bases = 0
    assert proc.stdout is not None
    for line in proc.stdout:
        if not line or line.startswith("@"):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) >= 10 and parts[9] != "*":
            bases += len(parts[9])
    _, stderr = proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"samtools view failed for {bam_path}\n{stderr}")
    return bases


def count_bam_with_samtools(bam_path: Path, threads: int = 1) -> Tuple[int, int]:
    reads = count_bam_reads(bam_path, threads=threads)
    bases = count_bam_bases_from_sequences(bam_path, threads=threads)
    return reads, bases


# ---------------- Discovery & Orchestration ----------------
def is_in_downloads_under_tmp(p: Path, tmp_dir: Path) -> bool:
    try:
        rel = p.relative_to(tmp_dir)
    except ValueError:
        return False
    return rel.parts and rel.parts[0] == "downloads"


def detect_file_type(p: Path) -> Optional[str]:
    s = str(p.name)
    if s.endswith(".fastq.gz"):
        return "fastq.gz"
    if s.endswith(".bam"):
        return "bam"
    return None


def sample_name_for_path(p: Path, tmp_dir: Path) -> Optional[str]:
    try:
        rel = p.relative_to(tmp_dir)
    except ValueError:
        return None
    if len(rel.parts) < 2:
        return None
    return rel.parts[0]


def collect_files(project_root: Path) -> Dict[str, List[Path]]:
    tmp_dir = project_root / "tmp"
    if not tmp_dir.is_dir():
        raise RuntimeError(f"Expected tmp directory at: {tmp_dir}")

    sample_to_files: Dict[str, List[Path]] = {}
    for p in tmp_dir.rglob("*"):
        if not p.is_file():
            continue
        if is_in_downloads_under_tmp(p, tmp_dir):
            continue
        ftype = detect_file_type(p)
        if ftype is None:
            continue
        sample = sample_name_for_path(p, tmp_dir)
        if sample is None:
            continue
        sample_to_files.setdefault(sample, []).append(p)
    return sample_to_files


def summarize_sample(sample: str, files: List[Path], threads: int = 1) -> dict:
    per_file = []
    total_reads = 0
    total_bases = 0
    for fp in sorted(files):
        ftype = detect_file_type(fp)
        if ftype == "fastq.gz":
            reads, bases = count_fastq_with_seqkit(fp)
        elif ftype == "bam":
            reads, bases = count_bam_with_samtools(fp, threads=threads)
        else:
            continue
        per_file.append({"path": str(fp), "type": ftype, "reads": reads, "bases": bases})
        total_reads += reads
        total_bases += bases
    return {
        "sample": sample,
        "files": per_file,
        "totals": {"reads": total_reads, "bases": total_bases},
        "tools": {
            "fastq": "seqkit stats -Ta",
            "bam": "samtools view -F 2304 (primary only)",
        },
    }


def write_sample_json(metrics_dir: Path, sample: str, payload: dict) -> Path:
    out_path = metrics_dir / sample / f"{sample}_read_base_counts.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)
    return out_path


def main():

    print("[INFO] Starting count_reads_and_bases.py")

    # Automatically detect PROJECT_ROOT from script location
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    metrics_dir = project_root / "metrics"

    sample_to_files = collect_files(project_root)
    if not sample_to_files:
        print(f"No matching files found under /tmp (excluding tmp/downloads).")
        return

    written = []
    for sample, files in sorted(sample_to_files.items()):
        summary = summarize_sample(sample, files, threads=1)
        out_path = write_sample_json(metrics_dir, sample, summary)
        written.append(out_path)

    print("Wrote:")
    for p in written:
        print(f"  {p}")

    print("[INFO] Completed count_reads_and_bases.py")

if __name__ == "__main__":
    main()