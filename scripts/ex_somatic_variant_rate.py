"""
--- ex_somatic_variant_rate.py ---

Calculates the somatic variant rate and bases filtered during variant calling from vcf's produced by bcftools pileup and bcftools call. 

This script is to be used exclusively with its parent rule

Author: 
    - James Phie
    - Cameron Fraser
"""

# Load libraries
import re
import sys
import json

# Define human nuclear genome size
#   - External reference: 10.1126/science.abj6987
#   - Internal reference: CODECseq/20251027 Human genome size/20251027-Human-genome-size.html

HUMAN_NUC_GENOME_SIZE = 6_063_731_176  

def main(snakemake):
    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_somatic_variant_rate.py")

    # Setup
    vcf_path = snakemake.input.vcf_all
    output_path = snakemake.output.results

    starting_bases = 0
    filtered_bases = 0
    evaluated_bases = 0
    num_snv_bases = 0
    min_bq = "NA"
    min_mq = "NA"


    # Extract min-BQ and min-MQ filtering values applied during bcftools mpileup from the header lines to report in variants called summary
    with open(vcf_path) as f:
        for line in f:
            if line.startswith("##bcftoolsCommand="):
                # Extract --min-BQ and --min-MQ from the header line
                bq_match = re.search(r"--min-BQ\s+(\d+)", line)
                mq_match = re.search(r"--min-MQ\s+(\d+)", line)
                if bq_match:
                    min_bq = bq_match.group(1)
                if mq_match:
                    min_mq = mq_match.group(1)


    # Check through all lines of the complete vcf (variants and no variants) for the following:
        # Starting bases - bases before base quality and mapping quality filtering
        # Filtered bases - total bases filtered for base quality
        # Evaluated bases - total bases assessed for variants (ie. denominator)
        # Number of SNV bases - total number of 1bp SNVs detected (MNVs counted as multiple 1bp SNVs)
        # SNV rate - Number of SNV bases divided by evaluated bases
        # SNVs per diploid - Estimate of the number of SNVs per 6.4Gbp

        f.seek(0)  # Rewind to process data lines
        for line in f:
            if line.startswith("#"):
                continue

            cols = line.strip().split("\t")
            assert len(cols) >= 9, f"Malformed line with too few columns:\n{line}"

            info = dict(field.split("=", 1) for field in cols[7].split(";") if "=" in field)
            sample_fmt = cols[8].split(":")
            sample_vals = cols[9].split(":")
            fmt = dict(zip(sample_fmt, sample_vals))

            dp_info = int(info.get("DP", 0))  # Raw read depth
            dp_fmt = int(fmt.get("DP", 0))    # High-quality read depth (--min-BQ filter)
            ad_vals = [int(x) for x in fmt.get("AD", "").split(",")]

            starting_bases += dp_info
            filtered_bases += dp_info - dp_fmt
            evaluated_bases += dp_fmt
            num_snv_bases += sum(ad_vals[1:]) if len(ad_vals) > 1 else 0

    snv_rate = num_snv_bases / evaluated_bases if evaluated_bases > 0 else 0
    snv_per_diploid = snv_rate * HUMAN_NUC_GENOME_SIZE

    # Write output to JSON
    result = {
        "starting_bases": starting_bases,
        "min-BQ": min_bq,
        "min-MQ": min_mq,
        "filtered_bases": filtered_bases,
        "evaluated_bases": evaluated_bases,
        "num_snv_bases": num_snv_bases,
        "snv_rate": float(f"{snv_rate:.6e}"),
        "snv_per_diploid": round(snv_per_diploid, 2)
    }

    with open(output_path, "w") as out:
        json.dump(result, out, indent=4)

    # Print script completion message to log
    print("[INFO] Completed ex_somatic_variant_rate.py")

if __name__ == "__main__":
    main(snakemake)