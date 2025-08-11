"""
--- ex_dsc_coverage_metrics.py ---

Calculate duplex sequencing coverage metrics:

1. Mean analyzable duplex depth across variant calling regions (selected per sample with include_bed)
2. Percent of variant calling positions with >0x coverage (selected per sample with include_bed)
3. Percent of whole genome positions with >0x coverage

Only bases with high base quality scores (>= QUALITY_THRESHOLD, typically >=Q70) are considered for depth and coverage calculations (e.g. duplex bases made from 2 Q35 bases).

Inputs:
- Filtered DSC BAM file
- Include BED file which excludes difficult to call regions (GIAB difficult regions), low depth germline regions, and germline mutations
- MS low depth bed
- Reference FAI file

Authors: 
    - James Phie
    - Joshua Johnstone
    - Chat-GPT
"""
# Import libraries
import sys
import subprocess
import bisect
import json

def main(snakemake):
    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_dsc_coverage_metrics.py")

    # Load quality threshold
    QUALITY_THRESHOLD = snakemake.params.quality_threshold

    # Inputs from Snakemake
    bam_ex_dsc = snakemake.input.bam_ex_dsc
    ms_depth = snakemake.input.ms_depth
    include_bed = snakemake.input.include_bed
    ref_fai = snakemake.input.fai
    sample = snakemake.params.sample
    ms_depth_threshold = snakemake.params.ms_depth_threshold

    # Output path
    json_out_path = snakemake.output.metrics

    # Load include BED intervals
    def load_bed(path):
        bed = {}
        with open(path) as f:
            for line in f:
                if not line.strip():
                    continue
                chrom, start, end = line.split()[:3]
                start, end = int(start), int(end)
                bed.setdefault(chrom, []).append((start, end))
        for chrom in bed:
            bed[chrom].sort()
        return bed

    include_intervals = load_bed(include_bed)

    # Get genome length from FAI
    ref_lengths = {}
    with open(ref_fai) as f:
        for line in f:
            chrom, length = line.split()[:2]
            ref_lengths[chrom] = int(length)

    total_genome_positions = sum(ref_lengths.values())

    # Checks if a position exists in BED intervals
    def in_intervals(chrom, pos, bed_dict):
        intervals = bed_dict.get(chrom, [])
        i = bisect.bisect_right(intervals, (pos, float('inf'))) - 1
        return i >= 0 and intervals[i][0] <= pos < intervals[i][1]

    # Precompute BED total positions
    include_bed_total_positions = sum(end - start for intervals in include_intervals.values() for start, end in intervals)

    # Get MS depth > half depth threshold positions
    ms_half_depth_threshold = ms_depth_threshold / 2
    ms_depth_half_pos = {}

    with open(ms_depth, "r") as f:
        for line in f:
            chrom, pos_str, depth_str = line.split()
            pos = int(pos_str)
            depth = int(depth_str)
            if depth > ms_half_depth_threshold:
                ms_depth_half_pos.setdefault(chrom, set()).add(pos)

    # Get duplex depth >0 positions and compare overlap with MS
    include_bed_total_depth = 0
    genome_duplex_depth_positions = 0
    include_bed_covered_positions = 0
    ms_ex_overlap_bases = 0
    ms_total_bases = sum(len(s) for s in ms_depth_half_pos.values())
    ex_total_bases = 0
    union_bases = 0

    with open(snakemake.log[0], "a") as log_file:
        proc_ex = subprocess.Popen(
        ["samtools", "depth", "-q", str(QUALITY_THRESHOLD), "-a", bam_ex_dsc],
        stdout=subprocess.PIPE,
        stderr=log_file,
        text=True
    )

    for line in proc_ex.stdout:
        chrom, pos_str, depth_str = line.split()
        pos = int(pos_str) - 1
        depth = int(depth_str)

        in_bed = in_intervals(chrom, pos, include_intervals)
        in_ms = pos in ms_depth_half_pos.get(chrom, set())

        if depth > 0:
            ex_total_bases += 1
            genome_duplex_depth_positions += 1
            if in_ms:
                ms_ex_overlap_bases += 1

        if in_ms or depth > 0:
            union_bases += 1

        if in_bed:
            include_bed_total_depth += depth
            if depth > 0:
                include_bed_covered_positions += 1

    proc_ex.stdout.close()
    proc_ex.wait()

    # Calculate metrics
    coverage_overlap_ex_ms = round((ms_ex_overlap_bases / union_bases * 100) if union_bases else 0, 2)
    ex_duplex_coverage = round((genome_duplex_depth_positions / total_genome_positions * 100) if total_genome_positions else 0, 2)
    include_bed_coverage = round((include_bed_total_positions / total_genome_positions * 100) if total_genome_positions else 0, 2)
    ex_mean_analyzable_duplex_depth = round((include_bed_total_depth / include_bed_total_positions) if include_bed_total_positions else 0, 2)
    ex_dsc_coverage_bedregions = round((include_bed_covered_positions / include_bed_total_positions * 100) if include_bed_total_positions else 0, 2)
    ex_dsc_coverage_wholegenome = round((include_bed_covered_positions / total_genome_positions * 100) if total_genome_positions else 0, 2)
    duplex_bases_in_bed_positions = include_bed_total_depth

    # Write output
    output_data = {
        "description": (
        "Duplex sequencing coverage metrics. See component metrics CSV for definitions."
        ),
        "sample": sample,
        "total_genome_positions": total_genome_positions,
        "include_bed_total_positions": include_bed_total_positions,
        "coverage_overlap_ex_ms": coverage_overlap_ex_ms,
        "ex_duplex_coverage": ex_duplex_coverage,
        "include_bed_coverage": include_bed_coverage,
        "ex_mean_analyzable_duplex_depth": ex_mean_analyzable_duplex_depth,
        "ex_dsc_coverage_bedregions": ex_dsc_coverage_bedregions,
        "ex_dsc_coverage_wholegenome": ex_dsc_coverage_wholegenome,
        "duplex_bases_in_bed_positions": duplex_bases_in_bed_positions
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_dsc_coverage_metrics.py")

# Only run in Snakemake
if __name__ == "__main__":
    main(snakemake) 