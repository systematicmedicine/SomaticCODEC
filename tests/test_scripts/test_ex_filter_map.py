"""
--- test_ex_filter_map.py

Tests the rule ex_filter_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""
from pathlib import Path
import pysam
from scripts.helpers.get_metadata import load_config, get_ex_sample_ids
from scripts.helpers.bam_helpers import count_bam_data_points

# Test that filtered read count is not greater than aligned read count
def test_filtered_reads_less_than_aligned_reads(lightweight_test_run):
    config = load_config("config/config.yaml")
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:
        
        # Get aligned read count
        pre_file = Path(f"tmp/{ex_sample}/{ex_sample}_map.bam")
        pre_count = count_bam_data_points(pre_file)

        # Get filtered read count       
        post_file = Path(f"tmp/{ex_sample}/{ex_sample}_map_correct.bam")
        post_count = count_bam_data_points(post_file)

        # Assert total reads pre marking duplicates <= total reads post marking duplicates
        assert post_count <= pre_count, (
            f"Post-filtering reads ({post_count}) > pre-filtering reads ({pre_count}) for {ex_sample}"
            )


# Test that all reads in the filtered BAM are:
#   - Properly paired (0x2)
#   - Not unmapped (0x4)
#   - Not secondary alignments (0x100)
#   - Not supplementary alignments (0x800)
def test_flags_filtering(lightweight_test_run):
    
    FLAG_PROPER_PAIR = 0x2
    FLAG_UNMAPPED = 0x4
    FLAG_SECONDARY = 0x100
    FLAG_SUPPLEMENTARY = 0x800
    
    config = load_config("config/config.yaml")
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:

        output_bam_path = Path(f"tmp/{ex_sample}/{ex_sample}_map_correct.bam")

        with pysam.AlignmentFile(output_bam_path, "rb") as bam:
            for read in bam:
                flag = read.flag

                # ✅ Must be properly paired
                assert (flag & FLAG_PROPER_PAIR) == FLAG_PROPER_PAIR, f"Read {read.query_name} is not properly paired"

                # ❌ Must NOT be unmapped, secondary, or supplementary
                assert (flag & FLAG_UNMAPPED) == 0, f"Read {read.query_name} is unmapped"
                assert (flag & FLAG_SECONDARY ) == 0, f"Read {read.query_name} is secondary"
                assert (flag & FLAG_SUPPLEMENTARY) == 0, f"Read {read.query_name} is supplementary"