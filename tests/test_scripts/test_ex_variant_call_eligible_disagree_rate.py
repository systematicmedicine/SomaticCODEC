# =======================================================================================
# test_ex_variant_call_eligible_disagree_rate.py
#
# Targeted BAM-based checks:
#   1) For FLAG 16 reads, after reversing qualities, leading/trailing n's in ac/bc
#      line up with leading/trailing !'s in aq/bq (Watson/Crick respectively).
#   2) Eligibility masking respects include.bed exactly: any assessed base must lie
#      inside one of the two BED intervals (chr1:633279-633472, chr21:5062720-5062866).
#
# Authors:
#   - ChatGPT
#   - James Phie
# =======================================================================================

# --------------------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------------------

import sys
import importlib.util
from pathlib import Path

import pysam
import pytest

# Run pytest from repo root so these relative paths resolve.
TEST_DATA = Path("tests/data/test_ex_variant_call_eligible_disagree_rate")
BED = TEST_DATA / "include.bed"
BAM = TEST_DATA / "test_map_dsc_anno_filtered.bam"
BAI = TEST_DATA / "test_map_dsc_anno_filtered.bam.bai"

# Import the script as a module without executing __main__
SCRIPT_PATH = Path("scripts") / "ex_variant_call_eligible_disagree_rate.py"
spec = importlib.util.spec_from_file_location(
    "ex_variant_call_eligible_disagree_rate", str(SCRIPT_PATH)
)
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod
spec.loader.exec_module(mod)

# --------------------------
# Fixtures
# --------------------------
@pytest.fixture(scope="session")
def bed_idx():
    assert BED.exists(), f"Missing {BED}"
    return mod.load_bed_as_index(str(BED))


@pytest.fixture(scope="session")
def bam():
    assert BAM.exists(), f"Missing {BAM}"
    assert BAI.exists(), f"Missing {BAI}"
    return pysam.AlignmentFile(str(BAM), "rb", index_filename=str(BAI))


# --------------------------
# Helpers (local to tests)
# --------------------------
def _count_leading(s: str, ch: str) -> int:
    n = 0
    for c in s:
        if c == ch:
            n += 1
        else:
            break
    return n

def _count_trailing(s: str, ch: str) -> int:
    n = 0
    for c in reversed(s):
        if c == ch:
            n += 1
        else:
            break
    return n


# --------------------------------------------------------------------------------------
# 1) Reverse-strand quality alignment check
# --------------------------------------------------------------------------------------
def test_flag16_reverse_aligns_ns_with_bang_qualities(bam):
    """
    After reversing qualities on FLAG 16 reads, leading/trailing 'n' runs in ac/bc
    should align to leading/trailing '!' runs in aq/bq respectively (same lengths).
    """
    found_reverse = False

    for aln in bam.fetch("chr1", 633279, 633472):
        if aln.is_unmapped or aln.is_secondary or aln.is_supplementary:
            continue
        if not aln.is_reverse:
            continue

        # Pull tags
        ac = aln.get_tag("ac")
        bc = aln.get_tag("bc")
        aq = aln.get_tag("aq")
        bq = aln.get_tag("bq")

        # Reverse qualities for reverse-strand, mirroring production code
        aq_r = mod.revstr(aq)
        bq_r = mod.revstr(bq)

        # Watson check: n <-> !
        lead_n_ac = _count_leading(ac, "n")
        trail_n_ac = _count_trailing(ac, "n")
        lead_bang_aq = _count_leading(aq_r, "!")
        trail_bang_aq = _count_trailing(aq_r, "!")

        assert lead_n_ac == lead_bang_aq
        assert trail_n_ac == trail_bang_aq

        # Crick check: n <-> !
        lead_n_bc = _count_leading(bc, "n")
        trail_n_bc = _count_trailing(bc, "n")
        lead_bang_bq = _count_leading(bq_r, "!")
        trail_bang_bq = _count_trailing(bq_r, "!")

        assert lead_n_bc == lead_bang_bq
        assert trail_n_bc == trail_bang_bq

        found_reverse = True
        break

    if not found_reverse:
        pytest.skip("No reverse-strand primary read found in chr1 test window")


# --------------------------------------------------------------------------------------
# 2) BED masking integrity: only positions inside include.bed are ever assessed
# --------------------------------------------------------------------------------------
def test_only_bed_positions_are_eligible(bam, bed_idx):
    """
    Run the eligibility screen over the WHOLE BAM, but assert that any position that
    would be 'assessed' (passes all filters) lies strictly within the two include.bed
    intervals (chr1:633279-633472) or (chr21:5062720-5062866).
    """
    REQUIRED_Q = 70
    assessed_positions = []  # (chrom, pos) 0-based ref positions

    # Iterate all references and reads to catch any accidental leakage
    for rname in bam.references:
        for aln in bam.fetch(rname):
            if aln.is_unmapped or aln.is_secondary or aln.is_supplementary:
                continue

            # Required tags
            try:
                ac = aln.get_tag("ac")
                bc = aln.get_tag("bc")
                aq = aln.get_tag("aq")
                bq = aln.get_tag("bq")
            except KeyError:
                continue
            if not ac or not bc or not aq or not bq or aq == "*" or bq == "*":
                continue

            # Align qualities to ac/bc for reverse strand
            if aln.is_reverse:
                aq = mod.revstr(aq)
                bq = mod.revstr(bq)

            ref_positions = aln.get_reference_positions(full_length=True)
            chrom = aln.reference_name
            in_bed_mask = mod.sweep_bed_membership(chrom, ref_positions, bed_idx)

            L = min(len(ac), len(bc), len(aq), len(bq), len(ref_positions))
            for p in range(L):
                if not in_bed_mask[p]:
                    continue
                pos = ref_positions[p]
                if pos is None:
                    continue

                a = ac[p]
                b = bc[p]
                if not (mod.is_base(a) and mod.is_base(b)):
                    continue

                qa = mod.phred_char_to_q(aq[p])
                qb = mod.phred_char_to_q(bq[p])
                if qa < 0 or qb < 0 or (qa + qb) < REQUIRED_Q:
                    continue

                assessed_positions.append((chrom, pos))

    # Define the two allowed half-open intervals from include.bed
    def _in_allowed(ch, pos):
        return (
            (ch == "chr1" and 633279 <= pos < 633472) or
            (ch == "chr21" and 5062720 <= pos < 5062866)
        )

    # Nothing assessed outside the BED
    assert assessed_positions, "No assessed positions found; fixture changed?"
    assert all(_in_allowed(ch, pos) for ch, pos in assessed_positions), (
        "Found assessed positions outside include.bed"
    )

# --------------------------------------------------------------------------------------
# 3) At least one disagreement exists in the BAM within the BED
# --------------------------------------------------------------------------------------
def test_at_least_one_disagreement_found(bam, bed_idx):
    """
    Sanity check: ensure that the provided BAM+BED combination produces at least one
    Watson/Crick disagreement at an eligible site.
    """
    REQUIRED_Q = 70
    disagreements = 0

    for chrom in ["chr1", "chr21"]:
        for aln in bam.fetch(chrom):
            if aln.is_unmapped or aln.is_secondary or aln.is_supplementary:
                continue
            try:
                ac = aln.get_tag("ac")
                bc = aln.get_tag("bc")
                aq = aln.get_tag("aq")
                bq = aln.get_tag("bq")
            except KeyError:
                continue
            if not ac or not bc or not aq or not bq or aq == "*" or bq == "*":
                continue

            if aln.is_reverse:
                aq = mod.revstr(aq)
                bq = mod.revstr(bq)

            ref_positions = aln.get_reference_positions(full_length=True)
            in_bed = mod.sweep_bed_membership(chrom, ref_positions, bed_idx)
            L = min(len(ac), len(bc), len(aq), len(bq), len(ref_positions))
            for p in range(L):
                if not in_bed[p] or ref_positions[p] is None:
                    continue
                a = ac[p]
                b = bc[p]
                if not (mod.is_base(a) and mod.is_base(b)):
                    continue
                qa = mod.phred_char_to_q(aq[p])
                qb = mod.phred_char_to_q(bq[p])
                if qa < 0 or qb < 0 or (qa + qb) < REQUIRED_Q:
                    continue
                if a.upper() != b.upper():
                    disagreements += 1

    assert disagreements == 1, f"Expected 1 disagreement, found {disagreements}"
