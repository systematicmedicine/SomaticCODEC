"""
--- ms_het_hom_ratio.py ---

Calculates the het/hom ratio from MS candidate variants VCF

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import pysam
import sys
import json

def main(snakemake):
    # Redirect stdout/stderr to log
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ms_het_hom_ratio.py")

    input_vcf = pysam.VariantFile(snakemake.input.vcf)
    output_json = snakemake.output.json
    sample = snakemake.params.sample
    het_threshold = snakemake.params.het_threshold

    het_count = 0
    hom_count = 0

    for record in input_vcf:
        vcf_sample = next(iter(record.samples.values()))
        ad = vcf_sample.get("AD")
        dp = vcf_sample.get("DP")

        alt_reads = sum(ad[1:len(record.alts)])
        vaf = alt_reads / dp

        if het_threshold <= vaf < (1 - het_threshold):
            het_count += 1
        elif vaf >= (1 - het_threshold):
            hom_count += 1

    het_hom_ratio = round(het_count / hom_count, 2) if hom_count else 0

    # Prepare output JSON
    metrics_dict = {
        "Description": "Het/hom ratio based on MS candidate variants VCF",
        "sample": sample,
        "het_variants": het_count,
        "hom_variants": hom_count,
        "het_hom_ratio": het_hom_ratio
    }

    # Write JSON
    with open(output_json, "w") as out:
        json.dump(metrics_dict, out, indent=4)

    print("[INFO] Completed ms_het_hom_ratio.py")

if __name__ == "__main__":
    main(snakemake)
