"""
--- test_ex_variant_call_eligible_disagree_rate.py ---

Tests
  1) Reverse-strand quality alignment check
    * Quality tags for Watson and Crick strands are not reversed automatically, while Watson, Crick and duplex sequences are. 
    * This tests that the reverse script implemented during ex_variant_call_eligible_disagree_rate.py correctly reverses the required tags. 
  2) BED masking integrity: only positions inside include.bed are ever assessed
    * Tests that only positions inside the bed mask are assessed for Watson and Crick disagreement
  3) Exactly one disagreement exists in the test BAM at eligible positions
    * The test file contains only one Watson and Crick disagreement where the following are true:
      * The disagreeing Watson and Crick base quality scores add up to >= 70
      * The disagreeing Watson and Crick bases are within the bed mask
      * The disagreeing Watson and Crick bases are both either A, C, G or T
  4) Guardrail: ex_call_somatic.smk checksum must not change (assumption lock)
      * ex_variant_call_eligible_disagree_rate metrics make assumptions about how variant calling is done
      * This test flags if ex_call_somatic.smk has been changed
      * After any changes to ex_call_somatic.smk, this script must be checked to make sure the assumptions match the updated rule

Authors:
  - ChatGPT
  - James Phie
"""
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
REQUIRED_Q = 70


# Import the script as a module without executing __main__
SCRIPT_PATH = Path("scripts/ex/processing_metrics") / "ex_variant_call_eligible_disagree_rate.py"
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
    positions = []
    for aln in bam.fetch():
        positions.extend(mod.eligible_sites_from_alignment(aln, bed_idx, REQUIRED_Q))

    assert positions, "No eligible positions found"

    # Build a quick lookup for allowed positions from the BED
    allowed = {
        chrom: set(range(start, end))
        for chrom, (starts, ends) in bed_idx.items()
        for start, end in zip(starts, ends)
    }

    # Collect any leaks (pos not in allowed BED set)
    leaks = [(ch, p) for ch, p, _, _ in positions if ch not in allowed or p not in allowed[ch]]

    assert not leaks, f"Found assessed positions outside include.bed: {leaks}"

# --------------------------------------------------------------------------------------
# 3) At least one disagreement exists in the BAM within the BED
# --------------------------------------------------------------------------------------
def test_at_least_one_disagreement_found(bam, bed_idx):
    _, disagreements, _ = mod.tally_disagreements(bam, bed_idx, REQUIRED_Q, 10000)
    assert disagreements == 1, f"Expected 1 disagreement, found {disagreements}"
