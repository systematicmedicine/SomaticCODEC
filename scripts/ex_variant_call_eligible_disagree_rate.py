# =====================================================================
# ex_variant_call_eligible_disagree_rate.py
#
# Compute empirical Watson/Crick disagreement rate at positions that are eligible for variant calling.
#
# Inputs (from Snakemake rule):
#   * BAM:   tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam
#   * BAI:   tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai
#   * BED:   tmp/{ex_sample}/{ex_sample}_include.bed    (include mask)
#
# Outputs:
#   * JSON:  metrics/{ex_sample}/{ex_sample}_variant_call_disagree_metrics.json
#
# What we do:
#   * Shuffle references and take the first NUMBER_OF_READS primary alignments from BAM
#   * Reverse aq:Z and bq:Z (Watson and Crick quality scores) on FLAG16 so qualities align to ac:Z / bc:Z (Watson and Crick sequences)
#   * Per base, require: ac:Z:,bc:Z: ∈ {A,C,G,T}, qa+qb ≥ REQUIRED_Q, and position lies inside include BED
#   * Tally:
#       - Total_eligible_sites
#       - Observed_disagreements   (ac:Z: != bc:Z:)
#       - Observed_disagreement_rate = Observed_disagreements / Total_eligible_sites
#
# Notes:
#   * aq and bq must be reversed if flag 0x10 (flag 16) is set
#       - The main sequence, ac and bc were already reversed earlier in the pipeline, but aq and bq were not
#   * Uses per-read interval sweeping for fast BED membership checks.
#
# Authors:
#  * James Phie
#  * ChatGPT
# =====================================================================

# ---------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------
import os
import sys
import json
import random
from typing import Dict, Tuple, List

import pysam

# ---------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------
def revstr(s: str) -> str:
    """Reverse a string (used to align aq/bq to ac/bc on FLAG16)."""
    return s[::-1]

def is_base(c: str) -> bool:
    """Return True if c is one of A/C/G/T (case-insensitive)."""
    return c.upper() in ("A", "C", "G", "T")

def phred_char_to_q(ch: str) -> int:
    """FASTQ ASCII → Phred integer; returns -1 if empty/invalid."""
    return -1 if not ch else (ord(ch) - 33)

def load_bed_as_index(bed_path: str) -> Dict[str, Tuple[List[int], List[int]]]:
    """
    Load BED (0-based, half-open) into an index:
        {chrom: ([starts_sorted], [ends_sorted])}
    for fast point-in-interval checks or sweeps.
    """
    idx: Dict[str, Tuple[List[int], List[int]]] = {}
    with open(bed_path, "r") as fh:
        for line in fh:
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            chrom, start, end = parts[0], int(parts[1]), int(parts[2])
            if chrom not in idx:
                idx[chrom] = ([], [])
            idx[chrom][0].append(start)
            idx[chrom][1].append(end)
    # sort per chrom
    for chrom, (starts, ends) in list(idx.items()):
        if not starts:
            continue
        pairs = sorted(zip(starts, ends))
        s, e = zip(*pairs)
        idx[chrom] = (list(s), list(e))
    return idx

def sweep_bed_membership(chrom: str,
                         ref_positions: List[int],
                         bed_idx: Dict[str, Tuple[List[int], List[int]]]) -> List[bool]:
    """
    For a single alignment, build a boolean mask over read positions indicating whether each
    reference-mapped position is inside the include BED.

    Uses a two-pointer sweep over the sorted intervals (amortized O(1) per base).
    ref_positions is a list of 0-based reference positions (or None for insertions/soft clips).
    """
    mask = [False] * len(ref_positions)
    if chrom not in bed_idx:
        return mask
    starts, ends = bed_idx[chrom]
    if not starts:
        return mask

    j = 0  # interval pointer
    for i, pos in enumerate(ref_positions):
        if pos is None:
            continue
        while j < len(starts) and ends[j] <= pos:
            j += 1
        if j >= len(starts):
            break
        if starts[j] <= pos < ends[j]:
            mask[i] = True
    return mask

# ---------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------
def main(snakemake):
    # Start logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_variant_call_eligible_disagree_rate.py")

    # Snakemake parameter injection
    bam_path = snakemake.input.bam
    bai_path = snakemake.input.bai
    bed_path = snakemake.input.include_bed
    out_json = snakemake.output.metrics_json

    REQUIRED_Q = int(snakemake.params.required_Q)
    NUMBER_OF_READS = int(snakemake.params.number_of_reads)
    THREADS = int(getattr(snakemake, "threads", 1))

    print(f"[INFO] BAM: {bam_path}")
    print(f"[INFO] BED: {bed_path}")
    print(f"[INFO] REQUIRED_Q: {REQUIRED_Q}")
    print(f"[INFO] NUMBER_OF_READS target: {NUMBER_OF_READS}")
    print(f"[INFO] THREADS: {THREADS}")

    # Load include mask
    bed_idx = load_bed_as_index(bed_path)

    # Open BAM (explicit index path in case it's not colocated)
    bam = pysam.AlignmentFile(bam_path, "rb", threads=THREADS, index_filename=bai_path)

    print("[INFO] Sampling mode: shuffle references, then take first N primary reads")
    refs = list(bam.header.references)
    random.shuffle(refs)

    # Tally
    total_eligible_sites = 0
    observed_disagreements = 0
    sampled_reads = 0

    # Stream and sample (by shuffled references), stop after NUMBER_OF_READS
    for r in refs:
        for aln in bam.fetch(r):
            if aln.is_unmapped or aln.is_secondary or aln.is_supplementary:
                continue

            try:
                ac = aln.get_tag("ac")  # Watson sequence
                bc = aln.get_tag("bc")  # Crick sequence
                aq = aln.get_tag("aq")  # Watson quality scores
                bq = aln.get_tag("bq")  # Crick quality scores
            except KeyError:
                continue
            if not ac or not bc or not aq or not bq or aq == "*" or bq == "*":
                continue

            # Reverse qualities for reverse-strand
            if aln.is_reverse:
                aq = revstr(aq)
                bq = revstr(bq)

            # Map read indices to 0-based reference positions
            ref_positions = aln.get_reference_positions(full_length=True)
            if not ref_positions:
                continue

            # Precompute BED membership mask for this alignment
            chrom = aln.reference_name
            in_bed = sweep_bed_membership(chrom, ref_positions, bed_idx)

            L = min(len(ac), len(bc), len(aq), len(bq), len(ref_positions))
            for p in range(L):
                if not in_bed[p]:
                    continue
                if ref_positions[p] is None:
                    continue

                a = ac[p]
                b = bc[p]
                if not (is_base(a) and is_base(b)):
                    continue

                qa = phred_char_to_q(aq[p])
                qb = phred_char_to_q(bq[p])
                if qa < 0 or qb < 0:
                    continue
                if qa + qb < REQUIRED_Q:
                    continue

                total_eligible_sites += 1
                if a.upper() != b.upper():
                    observed_disagreements += 1

            sampled_reads += 1
            if sampled_reads >= NUMBER_OF_READS:
                break
        if sampled_reads >= NUMBER_OF_READS:
            break

    if sampled_reads < NUMBER_OF_READS:
        print(f"[WARN] Requested {NUMBER_OF_READS} primaries but only sampled {sampled_reads}.")

    bam.close()

    # Final metric
    obs_disagree_rate = (observed_disagreements / total_eligible_sites) if total_eligible_sites else 0.0

    # Ensure output directory exists
    os.makedirs(os.path.dirname(out_json), exist_ok=True)

    # Write JSON with key metrics
    output_data = {
        "description": (
            "Summary of Watson/Crick disagreement rates at bases eligible for variant calling.",
            "Definitions:",
            "required_q: Minimum combined Phred quality (Watson + Crick) required for a base to be eligible.",
            "number_of_reads_target: Target number of primary alignments to sample.",
            "number_of_reads_sampled: Actual number of primary alignments sampled.",
            "Total_eligible_sites: Bases passing filters (in masked regions include_bed, A/C/G/T on both strands, qa+qb ≥ required_q).",
            "Observed_disagreements: Eligible bases where Watson and Crick base calls disagree.",
            "Observed_disagreement_rate: Fraction of disagreements over eligible sites (Observed_disagreements/Total_eligible_sites)."
        ),
        "required_q": REQUIRED_Q,
        "number_of_reads_target": NUMBER_OF_READS,
        "number_of_reads_sampled": sampled_reads,
        "total_eligible_sites": total_eligible_sites,
        "observed_disagreements": observed_disagreements,
        "observed_disagreement_rate": obs_disagree_rate,
    }

    with open(out_json, "w") as fh:
        json.dump(output_data, fh, indent=2)

    print(f"[INFO] Wrote {out_json}")
    print("[INFO] Finished ex_variant_call_eligible_disagree_rate.py")

if __name__ == "__main__":
    if "snakemake" not in globals():
        sys.stderr.write("[ERROR] This script is intended to be run via Snakemake 'script:'\n")
        sys.exit(2)
    main(snakemake)