"""
--- test_ms_low_depth.py

Tests the rule ms_low_depth

Authors:
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.get_metadata import load_config, get_ms_sample_ids
from definitions.paths.io import ms as MS
import pysam
from bisect import bisect_right

# Test that low depth BED has the correct structure
def test_bed_structure_correct(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        lowdepth_bed = Path(MS.LOW_DEPTH_MASK.format(ms_sample=ms_sample))

        with lowdepth_bed.open() as f:
            for linenum, line in enumerate(f, start=1):
                cols = line.rstrip('\n').split('\t')

                # Assertion 1: File has 3 tab-separated columns
                assert len(cols) == 3, f"Line {linenum} does not have 3 columns: {line}"
                start = int(cols[1])
                end = int(cols[2])

                # Assertion 2: Start position is before end position
                assert start < end, f"Start >= end on line {linenum}: {line}"

# Test that no positions in low depth BED overlap with the pileup depth VCF
def test_no_overlap_with_depth_vcf(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        pileup_depth_vcf = Path(MS.PILEUP_DEPTH.format(ms_sample=ms_sample))
        lowdepth_bed = Path(MS.LOW_DEPTH_MASK.format(ms_sample=ms_sample))

        # Build sorted intervals per chromosome
        bed_intervals = {}
        for line in open(lowdepth_bed):
            chrom, start, end, *rest = line.strip().split()
            start, end = int(start), int(end)
            bed_intervals.setdefault(chrom, []).append((start, end))

        # Sort intervals for each chromosome
        for chrom in bed_intervals:
            bed_intervals[chrom].sort()

        # Prepare lists of interval starts and ends for binary search
        bed_starts_ends = {}
        for chrom, intervals in bed_intervals.items():
            starts, ends = zip(*intervals)
            bed_starts_ends[chrom] = (list(starts), list(ends))

        # Open the VCF
        vcf = pysam.VariantFile(pileup_depth_vcf)
        for record in vcf:
            chrom = record.chrom
            pos = record.pos - 1  # Convert 1-based VCF positions to 0-based

            if chrom not in bed_starts_ends:
                continue

            starts, ends = bed_starts_ends[chrom]
            # Find first interval with start > pos
            idx = bisect_right(starts, pos)
            if idx == 0:
                continue  # Skip if all intervals start after pos

            # Check the previous interval's end
            if pos < ends[idx - 1]:
                raise AssertionError(f"Lowdepth BED overlaps with pileup depth VCF at {chrom}:{pos+1}")

# Test that all positions in low depth BED had low depth in pileup BCF
def test_low_depth_correctly_assigned(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    min_depth = config["sci_params"]["ms_pileup"]["min_depth"]

    for ms_sample in ms_samples:
        pileup_bcf = Path(MS.PILEUP_INT.format(ms_sample=ms_sample))
        lowdepth_bed = Path(MS.LOW_DEPTH_MASK.format(ms_sample=ms_sample))

        # Build sorted intervals per chromosome
        bed_intervals = {}
        for line in open(lowdepth_bed):
            chrom, start, end, *rest = line.strip().split()
            start, end = int(start), int(end)
            bed_intervals.setdefault(chrom, []).append((start, end))

        # Sort intervals for each chromosome
        for chrom in bed_intervals:
            bed_intervals[chrom].sort()

        # Prepare lists of interval starts and ends for binary search
        bed_starts_ends = {}
        for chrom, intervals in bed_intervals.items():
            starts, ends = zip(*intervals)
            bed_starts_ends[chrom] = (list(starts), list(ends))

        # Open the BCF
        bcf = pysam.VariantFile(pileup_bcf)
        for record in bcf:
            chrom = record.chrom
            pos = record.pos - 1  # Convert 1-based BCF positions to 0-based

            if chrom not in bed_starts_ends:
                continue

            starts, ends = bed_starts_ends[chrom]
            # Find the first interval with start > pos
            idx = bisect_right(starts, pos)
            if idx == 0:
                continue  # Skip if all intervals start after pos

            # Check the previous interval's end
            if pos < ends[idx - 1]:
                ad = record.samples[0].get("AD")
                if ad is None:
                    raise AssertionError(f"No AD field for {chrom}:{pos+1}")
                total_depth = sum(ad)
                assert total_depth < min_depth, (
                    f"Position {chrom}:{pos+1} in low depth mask has total allele depth "
                    f"({total_depth}) > min_depth ({min_depth})"
                )
