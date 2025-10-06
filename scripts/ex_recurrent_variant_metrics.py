# =======================================================================================
# --- ex_recurrent_variant_metrics.py ---
#
# Identify SNVs that occur in multiple samples in the same batch.
# 
# Exclude germline variants present in the gnomAD database.
#
#Authors: 
#    - Cameron Fraser
#    - Chat-GPT
# =======================================================================================

# ---------------------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------------------

# Load libraries
from cyvcf2 import VCF
import pandas as pd
import pysam
import json

# ---------------------------------------------------------------------------------------
# Define functions
# ---------------------------------------------------------------------------------------

# Load all variants from a list fo VCFs
def load_variants_from_vcfs(vcf_paths):
    records = []

    for path in vcf_paths:
        for var in VCF(path):
            for alt_allele in var.ALT:
                records.append({
                    "vcf_file": path,
                    "chrom": var.CHROM,
                    "pos": var.POS,
                    "ref": var.REF,
                    "alt": alt_allele
                })

    df = pd.DataFrame(records)
    return df

# Removes variants from variants_df that are also present in exclusion_df
def filter_variants_by_exclusion_set(variants_df, exclusion_df):
    """
    Removes variants from variants_df that are also present in exclusion_df.

    Parameters:
        variants_df (pd.DataFrame): DataFrame with columns ['chrom', 'pos', 'ref', 'alt']
        exclusion_df (pd.DataFrame): DataFrame with the same structure (e.g. germline contaminants)

    Returns:
        pd.DataFrame: Filtered variants (not present in exclusion set)
    """
    exclusion_keys = set(
        f"{row.chrom}:{row.pos}:{row.ref}>{row.alt}"
        for _, row in exclusion_df.iterrows()
    )

    variant_keys = variants_df.apply(
        lambda row: f"{row['chrom']}:{row['pos']}:{row['ref']}>{row['alt']}", axis=1
    )

    return variants_df[~variant_keys.isin(exclusion_keys)].reset_index(drop=True)

# Collapses duplicate variants and counts how many VCFs each appears in
def count_recurrent_variants(variants_df):
    grouped = (
        variants_df
        .groupby(['chrom', 'pos', 'ref', 'alt'])
        .agg(
            count=('vcf_file', lambda x: len(set(x))),
            vcf_files=('vcf_file', lambda x: sorted(set(x)))
        )
        .reset_index()
    )
    return grouped

# Writes the recurrent variant table to VCF format
def write_recurrent_variants_to_vcf(recurrent_df, output_vcf_path):
    # Detect output format
    if output_vcf_path.endswith(".vcf"):
        mode = "w"
    elif output_vcf_path.endswith(".vcf.gz"):
        mode = "wz"
    else:
        raise ValueError(f"[ERROR] Unsupported VCF output extension: {output_vcf_path}")

    # Filter to only recurrent variants
    filtered_df = recurrent_df[recurrent_df['count'] > 1].copy()

    # Define minimal header
    header = pysam.VariantHeader()
    header.add_meta('fileformat', value='VCFv4.2')
    header.add_meta('INFO', items=[('ID', 'COUNT'), ('Number', '1'), ('Type', 'Integer'),
                                   ('Description', 'Number of VCFs in which this variant was found')])

    # Add contigs from recurrent_df
    for contig in sorted(filtered_df['chrom'].unique()):
        header.contigs.add(contig)

    # Write VCF
    with pysam.VariantFile(output_vcf_path, mode, header=header) as out_vcf:
        for _, row in filtered_df.iterrows():
            rec = out_vcf.new_record(
                contig=row['chrom'],
                start=int(row['pos']) - 1,
                stop=int(row['pos']) - 1 + max(len(row['ref']), len(row['alt'])),
                alleles=(row['ref'], row['alt']),
                info={'COUNT': row['count']}
            )
            out_vcf.write(rec)

# Calculates summary metrics for recurrent variants and writes to a JSON file
def write_recurrent_metrics_json(output_path, somatic_variants_df, filtered_variants_df, recurrent_variants_df):

    total_before_filtering = len(somatic_variants_df)
    total_after_filtering = len(filtered_variants_df)
    total_unique_after_filtering = recurrent_variants_df.shape[0]
    total_recurrent = (recurrent_variants_df['count'] > 1).sum()
    pct_recurrent = round(100 * total_recurrent / total_after_filtering, 2) if total_after_filtering > 0 else 0.0

    metrics = {
        "description": "Summary metrics for somatic variant recurrence across samples",
        "total_variants_before_filtering": {
            "value": int(total_before_filtering),
            "description": "Total number of somatic SNVs across all samples"
        },
        "total_variants_after_filtering": {
            "value": int(total_after_filtering),
            "description": "Number of somatic SNVs remaining after filtering against germline contaminants"
        },
        "total_unique_variants_after_filtering": {
            "value": int(total_unique_after_filtering),
            "description": "Number of unique SNVs (after filtering and deduplication across samples)"
        },
        "total_recurrent_variants_after_filtering": {
            "value": int(total_recurrent),
            "description": "Number of SNVs observed in more than one sample"
        },
        "percentage_recurrent_variants": {
            "value": float(pct_recurrent),
            "description": "Percentage of filtered SNVs that were observed in multiple samples"
        }
    }

    with open(output_path, "w") as f:
        json.dump(metrics, f, indent=4)

# ---------------------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------------------

def main(
    somatic_vcf_paths, 
    germ_contaminant_vcf_paths, 
    output_metrics_path, 
    output_vcf_path, 
    log_path
    ):

    # Inititate logging
    sys.stdout = open(log_path, "a")
    sys.stderr = open(log_path, "a")
    print("[INFO] Starting ex_recurrent_variant_metrics.py")
    
    # Load all somatic variants
    somatic_variants = load_variants_from_vcfs(somatic_vcf_paths)

    # Load gnomAD variants
    germline_contaminants = load_variants_from_vcfs(germ_contaminant_vcf_paths)

    # Filter somatic variants
    filtered_somatic_variants = filter_variants_by_exclusion_set(somatic_variants, germline_contaminants)

    # Collapse VCF by recurrant_variants
    recurrent_variants_df = count_recurrent_variants(filtered_somatic_variants)

    # Write recurrent variants to vcf
    write_recurrent_variants_to_vcf(recurrent_variants_df, output_vcf_path)
    
    # Calculate metrics
    write_recurrent_metrics_json(
        output_path=output_metrics_path,
        somatic_variants_df=somatic_variants,
        filtered_variants_df=filtered_somatic_variants,
        recurrent_variants_df=recurrent_variants_df
    )

    # Log script completion
    print("[INFO] Completed ex_recurrent_variant_metrics.py")

if __name__ == "__main__":
    main(
        somatic_vcf_paths = snakemake.input.somatic_vcfs,
        germ_contaminant_vcf_paths = snakemake.input.germ_contaminant_vcfs,
        output_metrics_path = snakemake.output.metrics_path,
        output_vcf_path = snakemake.output.vcf_path,
        log_path = snakemake.log[0]
    )
   

