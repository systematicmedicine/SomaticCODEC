"""
--- test_ex_generate_demux_adaptors.py

Tests the rule ex_generate_demux_adaptors

Authors:
    - Joshua Johnstone
"""
import glob
from pathlib import Path
from helpers.fasta_helpers import count_fasta_data_points, check_fasta_structure
from helpers.get_metadata import load_config, get_ex_sample_ids, get_ex_lane_ids
import definitions.paths.io.ex as EX

# Tests that FASTA files have correct structure
def test_fasta_structure_correct(lightweight_test_run):
    
    # Load ex_lane IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_lanes = get_ex_lane_ids(config)

    # Locate all FASTA files
    fasta_files = []
    for ex_lane in ex_lanes:
        resolved_path_r1 = EX.DEMUX_ADAPTOR_R1.format(ex_lane = ex_lane)
        resolved_path_r2 = EX.DEMUX_ADAPTOR_R2.format(ex_lane = ex_lane)
        fasta_files.append(resolved_path_r1)
        fasta_files.append(resolved_path_r2)

    # Check for correct structure in each FASTA file
    for fasta in fasta_files:
        check_fasta_structure(fasta)

# Tests that that there are 2 FASTA entries per ex sample (r1 start, r2 start)
def test_fasta_entries_per_sample(lightweight_test_run):
    
    # Get ex_lane IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_lanes = get_ex_lane_ids(config)
    
    # Locate all FASTA files
    fasta_files = []
    for ex_lane in ex_lanes:
        resolved_path_r1 = EX.DEMUX_ADAPTOR_R1.format(ex_lane = ex_lane)
        resolved_path_r2 = EX.DEMUX_ADAPTOR_R2.format(ex_lane = ex_lane)
        fasta_files.append(resolved_path_r1)
        fasta_files.append(resolved_path_r2)

    # Count number of entries in FASTA files
    fasta_entries = {Path(f).name: count_fasta_data_points(f) for f in fasta_files}
    total_fasta_entries = sum(fasta_entries.values())

    # Get number of ex samples
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)
    ex_sample_count = len(ex_samples)

    # Assert that there are 2 FASTA entries per sample (r1 start, r2 start)
    assert total_fasta_entries / ex_sample_count == 2, (
    f"Expected 2 FASTA entries per EX sample, actual entries per EX sample: {total_fasta_entries / ex_sample_count}"
    )

