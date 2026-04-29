"""
--- test_ex_variant_call_eligible_disagree_rate.py ---

Tests the script ex_variant_call_eligible_disagree_rate.py

Authors:
  - James Phie
  - Joshua Johnstone
"""

import pysam
import pytest
import rule_scripts.ex.processing_metrics.ex_variant_call_eligible_disagree_rate as vcedr
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX
import definitions.paths.io.ms as MS

# Helper functions
def count_leading(string: str, match: str) -> int:
    count = 0
    for char in string:
        if char == match:
            count += 1
        else:
            break
    return count

def count_trailing(string: str, match: str) -> int:
    count = 0
    for char in reversed(string):
        if char == match:
            count += 1
        else:
            break
    return count

# --------------------------------------------------------------------------------------
# 1) Reverse-strand quality alignment check
# --------------------------------------------------------------------------------------
def test_flag16_reverse_aligns_ns_with_bang_qualities(lightweight_test_run):
    """
    After reversing qualities on FLAG 16 reads, leading/trailing 'n' runs in ac/bc
    should align to leading/trailing '!' runs in aq/bq respectively (same lengths).
    """

    # Load ex_sample IDs from config
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:

        found_reverse = False

        # Load BAM and BAI
        bam_path = EX.FILTERED_DSC.format(ex_sample=ex_sample)
        bai_path = EX.FILTERED_DSC_INDEX.format(ex_sample=ex_sample)
        bam = pysam.AlignmentFile(str(bam_path), "rb", index_filename=str(bai_path))

        for aln in bam.fetch():
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
            aq_r = vcedr.revstr(aq)
            bq_r = vcedr.revstr(bq)

            # Watson check: n <-> !
            lead_n_ac = count_leading(ac, "n")
            trail_n_ac = count_trailing(ac, "n")
            lead_bang_aq = count_leading(aq_r, "!")
            trail_bang_aq = count_trailing(aq_r, "!")

            assert lead_n_ac == lead_bang_aq
            assert trail_n_ac == trail_bang_aq

            # Crick check: n <-> !
            lead_n_bc = count_leading(bc, "n")
            trail_n_bc = count_trailing(bc, "n")
            lead_bang_bq = count_leading(bq_r, "!")
            trail_bang_bq = count_trailing(bq_r, "!")

            assert lead_n_bc == lead_bang_bq
            assert trail_n_bc == trail_bang_bq

            found_reverse = True
            break

        if not found_reverse:
            pytest.skip("No reverse-strand primary read found in BAM")

# --------------------------------------------------------------------------------------
# 2) BED masking integrity: only positions inside include BED are assessed
# --------------------------------------------------------------------------------------
def test_only_bed_positions_are_eligible(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)
    REQUIRED_Q = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"]

    for ex_sample in ex_samples:

        # Load BAM and BAI
        bam_path = EX.FILTERED_DSC.format(ex_sample=ex_sample)
        bai_path = EX.FILTERED_DSC_INDEX.format(ex_sample=ex_sample)
        bam = pysam.AlignmentFile(bam_path, "rb", index_filename=bai_path)
        include_bed_path = MS.INCLUDE_BED.format(ex_sample=ex_sample)

        # Create index for include BED
        bed_idx = vcedr.load_bed_as_index(include_bed_path)

        # Get eligible positions
        positions = []
        for aln in bam.fetch():
            positions.extend(vcedr.eligible_sites_from_alignment(aln, bed_idx, REQUIRED_Q))

        assert positions, "No eligible positions found"

        # Verify every returned position is inside the BED intervals
        for ch, p, _, _ in positions:
            assert ch in bed_idx, f"{ch} not present in BED index"
            assert any(start <= p < end
                    for start, end in zip(*bed_idx[ch])), f"Position {ch}:{p} outside include.bed"

# --------------------------------------------------------------------------------------
# 3) At least one disagreement exists in the BAM within the BED
# --------------------------------------------------------------------------------------
def test_at_least_one_disagreement_found(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)
    REQUIRED_Q = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"]
    RANDOM_SEED = config["infrastructure"]["random_seed"]

    for ex_sample in ex_samples:

        # Load BAM and BAI
        bam_path = EX.FILTERED_DSC.format(ex_sample=ex_sample)
        bai_path = EX.FILTERED_DSC_INDEX.format(ex_sample=ex_sample)
        bam = pysam.AlignmentFile(bam_path, "rb", index_filename=bai_path)
        include_bed_path = MS.INCLUDE_BED.format(ex_sample=ex_sample)

        # Create index for include BED
        bed_idx = vcedr.load_bed_as_index(include_bed_path)

        # Tally disagreements within BED region
        _, disagreements, _ = vcedr.tally_disagreements(bam, bed_idx, REQUIRED_Q, 10000, RANDOM_SEED)
        assert disagreements >= 1, f"Expected >= 1 disagreement, found {disagreements}"

# --------------------------------------------------------------------------------------
# 4) Exactly one disagreement exists in the BAM within the BED
#   * The test file contains only one Watson and Crick disagreement where the following are true:
#   * The disagreeing Watson and Crick base quality scores add up to >= 70
#   * The disagreeing Watson and Crick bases are within the bed mask
#   * The disagreeing Watson and Crick bases are both either A, C, G or T
# --------------------------------------------------------------------------------------
def test_exactly_one_disagreement_found():

    # Define test input paths
    bam_path = "tests/data/test_ex_variant_call_eligible_disagree_rate/test_map_dsc_anno_filtered.bam"
    bai_path = "tests/data/test_ex_variant_call_eligible_disagree_rate/test_map_dsc_anno_filtered.bam.bai"
    include_bed_path = "tests/data/test_ex_variant_call_eligible_disagree_rate/include.bed"

    # Define hardcoded test params
    REQUIRED_Q = 70
    RANDOM_SEED = 123

    # Load BAM
    bam = pysam.AlignmentFile(bam_path, "rb", index_filename=bai_path)

    # Create index for include BED
    bed_idx = vcedr.load_bed_as_index(include_bed_path)

    # Tally disagreements within BED region
    _, disagreements, _ = vcedr.tally_disagreements(bam, bed_idx, REQUIRED_Q, 10000, RANDOM_SEED)
    assert disagreements == 1, f"Expected exactly 1 disagreement, found {disagreements}"
