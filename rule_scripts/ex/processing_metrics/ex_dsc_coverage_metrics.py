#!/usr/bin/env python3
"""
--- ex_dsc_coverage_metrics.py ---

Calculates duplex coverage metrics

Authors:
    - Joshua Johnstone
    - Chat-GPT
"""

# Import libraries
import sys
import argparse
import numpy as np
import subprocess
import json
import plotly.graph_objects as go
from helpers.fai_helpers import get_chrom_lengths, get_chrom_offsets

def main(args):

    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_dsc_coverage_metrics.py")

    # Define input paths  
    ex_dsc_bam_path = args.ex_dsc_bam
    include_bed_path = args.include_bed
    ref_fai_path = args.ref_fai

    # Define output paths
    json_out_path = args.output_json
    plot_out_path = args.output_plot

    # Define params
    EX_DEPTH_THRESHOLD = int(args.ex_depth_threshold)
    EX_BQ_THRESHOLD = int(args.ex_bq_threshold)
    THREADS = int(args.threads)

    # Helper functions    
    # Creates a boolean array for BED file coverage
    def coverage_array_bed(bed_path, chrom_lengths):

        print(f"[INFO] Started creating coverage array for {bed_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array = np.zeros(genome_length, dtype=bool)

        # Mark BED-covered positions as True
        with open(bed_path) as bed:
            for line in bed:
                if line.startswith("#") or not line.strip():
                    continue

                chrom, start, end = line.rstrip().split()[:3]
                start = int(start)
                end = int(end)

                genome_start = offsets[chrom] + start
                genome_end = offsets[chrom] + end

                coverage_array[genome_start:genome_end] = True

        print(f"[INFO] Finished creating coverage array for {bed_path}")

        return coverage_array
    
    # Creates a boolean array for coverage at each BAM position
    def coverage_array_depth(bam_path, chrom_lengths, depth_threshold, threads):

        print(f"[INFO] Started creating depth coverage array for {bam_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array_depth = np.zeros(genome_length, dtype=bool)

        cmd = [
        "samtools", "depth",
        "--threads", str(threads),
        "-J",
        "-s",
        bam_path
        ]

        with subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        ) as proc:
            for line in proc.stdout:
                chrom, pos_str, depth_str = line.split()
                pos = int(pos_str) - 1 # Convert position to 0-based
                depth = int(depth_str)
                genome_index = offsets[chrom] + pos

                # If depth >= threshold, set coverage to True
                if depth >= depth_threshold:
                    coverage_array_depth[genome_index] = True

        print(f"[INFO] Finished creating depth coverage array for {bam_path}")

        return coverage_array_depth
    
    # Creates a boolean array for coverage at each BAM position (at a given BQ threshold)
    def coverage_array_BQ_threshold(bam_path, chrom_lengths, depth_threshold, BQ_threshold, threads):

        print(f"[INFO] Started creating BQ coverage array for {bam_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array_BQ = np.zeros(genome_length, dtype=bool)

        cmd = [
        "samtools", "depth",
        "--threads", str(threads),
        "-J",
        "-s",
        "--min-BQ", str(BQ_threshold), # Only bases with BQ >= threshold count towards depth
        bam_path
        ]

        with subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        ) as proc:

            for line in proc.stdout:
                chrom, pos_str, depth_str = line.split()
                pos = int(pos_str) - 1 # Convert position to 0-based
                depth = int(depth_str)
                genome_index = offsets[chrom] + pos

                # If depth >= threshold, set coverage to True
                if depth >= depth_threshold:
                    coverage_array_BQ[genome_index] = True

        print(f"[INFO] Finished creating BQ coverage array for {bam_path}")

        return coverage_array_BQ

    # Get chromosome lengths from reference FAI
    chrom_lengths = get_chrom_lengths(ref_fai_path)

    # Get genome length
    _, genome_length = get_chrom_offsets(chrom_lengths)

    # Create boolean array for include BED coverage
    include_bed_coverage = coverage_array_bed(include_bed_path, chrom_lengths)

    # Create boolean arrays for EX coverage at given depth and BQ thresholds
    ex_coverage_depth = coverage_array_depth(ex_dsc_bam_path, chrom_lengths, EX_DEPTH_THRESHOLD, THREADS)
    ex_coverage_BQ = coverage_array_BQ_threshold(ex_dsc_bam_path, chrom_lengths, EX_DEPTH_THRESHOLD, EX_BQ_THRESHOLD, THREADS)

    # Calculate coverage metrics
    ex_dsc_coverage_bases = int(np.sum(ex_coverage_depth))
    ex_dsc_coverage_pct = round(100 * (ex_dsc_coverage_bases / genome_length), ndigits = 2)
    ex_dsc_high_qual_bases = int(np.sum(ex_coverage_BQ))
    ex_dsc_high_qual_pct = round(100 * (ex_dsc_high_qual_bases / genome_length), ndigits = 2)
    ex_dsc_high_qual_unmasked_bases = int(np.sum(ex_coverage_BQ & include_bed_coverage))
    ex_dsc_high_qual_unmasked_pct = round(100 * (ex_dsc_high_qual_unmasked_bases / genome_length), ndigits = 2)

    # Fill JSON data
    json_data = {
        "total_genome_positions": {
            "description": "Number of positions in the reference genome.",
            "value": genome_length
            },
        "ex_dsc_coverage_count": {
            "description": "Number of genome positions with DSC depth > 0.",
            "value": ex_dsc_coverage_bases
            },
            "ex_dsc_coverage_pct": {
            "description": "Percentage of genome positions with DSC depth > 0.",
            "value": ex_dsc_coverage_pct
            },
        "ex_dsc_high_qual_count": {
            "description": "Number of genome positions that meet ex_dsc_coverage AND have base quality >= min_base_quality.",
            "value": ex_dsc_high_qual_bases
            },
        "ex_dsc_high_qual_pct": {
            "description": "Percentage of genome positions that meet ex_dsc_coverage AND have base quality >= min_base_quality.",
            "value": ex_dsc_high_qual_pct
            },
        "ex_dsc_high_qual_unmasked_count": {
            "description": "Number of genome positions that meet ex_dsc_high_qual AND are not masked.\nThese positions are eligible for variant calling.",
            "value": ex_dsc_high_qual_unmasked_bases
            },
        "ex_dsc_high_qual_unmasked_pct": {
            "description": "Percentage of genome positions that meet ex_dsc_high_qual AND are not masked.\nThese positions are eligible for variant calling.",
            "value": ex_dsc_high_qual_unmasked_pct
            }
        }

    # Write JSON
    with open(json_out_path, "w") as out_f:
        json.dump(json_data, out_f, indent=4)

    # Create Sankey plot
    sankey_plot = go.Figure(data=[go.Sankey(
    node = dict(
      pad = 40,
      thickness = 15,
      line = dict(color = "black", width = 0.5),
      label = ["Reference genome positions", "DSC depth > 0", "No DSC depth",
               f"BQ >= threshold ({EX_BQ_THRESHOLD})", f"BQ < threshold ({EX_BQ_THRESHOLD})", 
               "Unmasked", "Masked"],
      color = "blue",
      x = [0.0, 0.4, 0.4, 0.7, 0.7, 1.0, 1.0],
      y = [0.5, 0.2, 0.7, 0.3, 0.6, 0.4, 0.6]
    ),
    link = dict(
      source = [0, 0, 1, 1, 3, 3],
      target = [1, 2, 3, 4, 5, 6],
      value = [ex_dsc_coverage_pct, (100 - ex_dsc_coverage_pct),
               ex_dsc_high_qual_pct, (ex_dsc_coverage_pct - ex_dsc_high_qual_pct),
               ex_dsc_high_qual_unmasked_pct, (ex_dsc_high_qual_pct - ex_dsc_high_qual_unmasked_pct)
               ]
  ))])

    # Write Sankey plot
    sankey_plot.update_layout(title_text = "EX DSC coverage", 
                              font=dict(size=16, color='black')
                              )
    sankey_plot.add_annotation(
        x = 0,
        y = -0.1,
        xref='paper',
        yref='paper',
        text="Definitions:<br>" \
        "DSC depth: Duplex depth in the final DSC BAM.<br>" \
        "BQ: Base quality in the final DSC BAM.<br>" \
        "Unmasked/masked: Inside/not inside the include BED regions.",
        showarrow=False,
        font=dict(size=12, color='black'),
        align='left'
        )
    sankey_plot.write_html(plot_out_path)

    print("[INFO] Completed ex_dsc_coverage_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--threads", required=True)
    parser.add_argument("--ex_dsc_bam", required=True)
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--ref_fai", required=True)
    parser.add_argument("--ex_depth_threshold", required=True)
    parser.add_argument("--ex_bq_threshold", required=True)
    parser.add_argument("--output_json", required=True)
    parser.add_argument("--output_plot", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
