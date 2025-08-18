"""
--- ex_recurrent_variant_metrics.py ---

Compares all somatic variants found in a batch and outputs recurrent variants.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import json
from collections import defaultdict
import sys

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_recurrent_variant_metrics.py")

    # Get paths
    vcf_paths = snakemake.input.vcfs
    json_out_path = snakemake.output.metrics

    # Collect variants across all VCFs
    variant_files = defaultdict(set)
    for vcf_path in vcf_paths:
        vcf_name = vcf_path.split("/")[-1]
        with open(vcf_path, "r") as f:
            for line in f:
                if line.startswith("#"):
                    continue
                fields = line.strip().split("\t")
                chrom, pos, ref, alt = fields[0], fields[1], fields[3], fields[4]
                key = f"{chrom}:{pos}:{ref}>{alt}"
                variant_files[key].add(vcf_name)

    # Find total number of somatic variants called across all VCFs (including reoccurring variants)
    total_variant_calls = sum(len(files) for files in variant_files.values())
    
    # Find total number of distinct somatic variants across all VCFs
    distinct_variants_called = len(variant_files)

    # Find reoccurring variants
    recurrent_variants = []
    for variant, files in variant_files.items():
        if len(files) > 1:
            recurrent_variants.append({
                "variant": variant,
                "number_of_occurrences": len(files),
                "files": sorted(list(files))
            })

    total_recurrent_variants = len(recurrent_variants)
    
    pct_recurrent_variants = round(100 * total_recurrent_variants / distinct_variants_called, 2)

    # Write output JSON
    output_data = {
        "description": "Summary of somatic variants that occur more than once within a batch.",
        "total_variant_calls": total_variant_calls,
        "total_distinct_variants": distinct_variants_called,
        "total_recurrent_variants": total_recurrent_variants,
        "pct_recurrent_variants": pct_recurrent_variants,
        "recurrent_variant_details": recurrent_variants
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_recurrent_variant_metrics.py")

if __name__ == "__main__":
    main(snakemake)
