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
def write_recurrent_variants_to_vcf(recurrent_df, output_vcf_path, reference_vcf_path=None):

    # Choose output mode based on file extension
    if output_vcf_path.endswith(".vcf"):
        mode = "w"
    elif output_vcf_path.endswith(".vcf.gz"):
        mode = "wz"  # BGZF-compressed
    else:
        raise ValueError(f"[ERROR] Unsupported VCF output extension: {output_vcf_path}")

    # Load or create VCF header
    if reference_vcf_path:
        with pysam.VariantFile(reference_vcf_path) as header_template:
            header = header_template.header.copy()
    else:
        header = pysam.VariantHeader()
        header.add_meta('fileformat', value='VCFv4.2')
        header.add_meta('INFO', items=[('ID', 'COUNT'), ('Number', '1'), ('Type', 'Integer'),
                                       ('Description', 'Number of VCFs in which this variant was found')])

    # Write output VCF
    with pysam.VariantFile(output_vcf_path, mode, header=header) as out_vcf:
        for _, row in recurrent_df.iterrows():
            rec = out_vcf.new_record(
                contig=row['chrom'],
                start=int(row['pos']) - 1,  # VCF is 0-based in pysam
                stop = int(row['pos']) - 1 + max(len(row['ref']), len(row['alt'])),
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
        "total_variants_before_filtering": total_before_filtering,
        "total_variants_after_filtering": total_after_filtering,
        "total_unique_variants_after_filtering": total_unique_after_filtering,
        "total_recurrent_variants_after_filtering": total_recurrent,
        "percentage_recurrent_variants": pct_recurrent
    }

    with open(output_path, "w") as f:
        json.dump(metrics, f, indent=4)

# ---------------------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------------------

if __name__ == "__main__":
   
    # Snakemake parameter injection
    somatic_vcf_paths = snakemake.input.somatic_vcfs
    germ_contaminant_vcf_paths = snakemake.input.germ_contaminant_vcfs
    output_metrics_path = snakemake.output.metrics_path
    output_vcf_path = snakemake.output.vcf_path
    log_path = snakemake.log

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
    write_recurrent_variants_to_vcf(
        recurrent_df=recurrent_variants_df,
        output_vcf_path=output_vcf_path,
        reference_vcf_path=somatic_vcf_paths[0]  # Optional: for header reuse
    )
    
    # Calculate metrics
    write_recurrent_metrics_json(
        output_path=output_metrics_path,
        somatic_variants_df=somatic_variants,
        filtered_variants_df=filtered_somatic_variants,
        recurrent_variants_df=recurrent_variants_df
    )

    # Log script completion
    print("[INFO] Completed ex_recurrent_variant_metrics.py")
