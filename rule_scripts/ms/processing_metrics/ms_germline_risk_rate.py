#!/usr/bin/env python3
"""
--- ms_germline_risk_rate.py ---

Generates a metrics file with the germline risk rate

To be used with rule ms_germline_risk_rate

Authors:
    - Joshua Johnstone
"""

import json
import sys
import argparse

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ms_germline_risk_rate.py")

    # Define input paths
    depth_pileup_path = args.depth_pileup
    depth_alt_pileup_path = args.depth_alt_pileup

    # Define output path
    output_json = args.output_json

    # Get number of bases eligible for variant calling from depth pileup
    with open(depth_pileup_path, "rt") as f:
        callable_bases = sum(1 for line in f if not line.startswith("#"))

    # Get number of germline risk positions (callable bases with alt VAF >= min_alt_vaf)
    with open(depth_alt_pileup_path, "rt") as f:
        germ_risk_positions = sum(1 for line in f if not line.startswith("#"))

    # Calculate germline risk rate and output in json
    germline_risk_rate = round(germ_risk_positions / callable_bases, 4) if callable_bases else 0
    
    result = {
        "callable_bases": {
            "definition": "Number of bases with depth >= min_depth and BQ >= min_base_qual",
            "value": callable_bases
        },
        "germ_risk_positions": {
            "definition": "Number of callable bases with alt VAF >= min_alt_vaf",
            "value": germ_risk_positions
        },
        "germline_risk_rate": {
            "definition": "germ_risk_positions divided by callable_bases",
            "value": germline_risk_rate
        }
    }

    with open(output_json, 'w') as f:
        json.dump(result, f, indent=4)

    print("[INFO] Completed ms_germline_risk_rate.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--depth_pileup", required=True)
    parser.add_argument("--depth_alt_pileup", required=True)
    parser.add_argument("--output_json", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)