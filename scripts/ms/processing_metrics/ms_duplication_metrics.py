#!/usr/bin/env python3
"""
--- ms_duplication_metrics.py ---

Calculates duplication rate based on samtools markdup metrics.

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import sys
import json
import argparse

def main(args):
    # Redirect stdout/stderr to log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ms_duplication_metrics.py")

    # Define inputs
    dedup_metrics = args.dedup_metrics
    sample = args.sample

    # Define output
    json_out = args.duplication_metrics

    # Load samtools markdup JSON metrics
    with open(dedup_metrics) as f:
        metrics = json.load(f)

    # Extract counts
    input_reads = metrics["READ"]
    excluded_reads = metrics["EXCLUDED"]
    examined_reads = metrics["EXAMINED"]
    duplicate_reads = metrics["DUPLICATE TOTAL"]
    output_reads = metrics["WRITTEN"]

    # Calculate duplication rate
    duplication_rate = round(duplicate_reads / examined_reads, 4)

    # Prepare output JSON
    metrics_dict = {
        "Description": "Duplication rate based on samtools markdup metrics",
        "sample": sample,
        "reads_before_dedup": input_reads,
        "excluded_reads": excluded_reads,
        "examined_reads": examined_reads,
        "duplicate_reads": duplicate_reads,
        "duplication_rate": duplication_rate,
        "reads_after_dedup": output_reads
    }

    # Write JSON
    with open(json_out, "w") as out:
        json.dump(metrics_dict, out, indent=4)

    print("[INFO] Completed ms_duplication_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dedup_metrics", required=True)
    parser.add_argument("--duplication_metrics", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
