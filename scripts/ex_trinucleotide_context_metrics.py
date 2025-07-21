"""
--- ex_trinucleotide_context_metrics.py ---

Calculate 96 trinucleotide contexts for called somatic mutations
    - ex_trinucleotide_cosine_similarity: Cosine similarity compared to nanoseq granulocyte reference data

Nanoseq trinucleotide contexts were used as a reference for comparison. Nanoseq data show good agreement with Bae2023 trinucleotide contexts. 
Average nanoseq granulocyte somatic trinucleotide contexts were obtained from 8 donor samples. 
Donor characteristics for nanoseq reference trinucleotide contexts:
    - Healthy
    - Aged 20-80
    - 6 Female 2 Male

Author: James Phie
"""

# Load libraries
import sys
import os
import pandas as pd
import numpy as np
import pysam
from collections import Counter

# Redirect stdout and stderr to Snakemake log file
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_trinucleotide_context_metrics.py")

# Inputs
vcf_paths = snakemake.input.vcf_snvs
ref_path = snakemake.input.ref
nanoseq_contexts_path = snakemake.input.nanoseq_contexts
output_path = snakemake.output.metrics

# Load reference genome
ref = pysam.FastaFile(ref_path)

# Predefined standard 96 trinucleotide context order (with pyrimidine-centric convention - ie. C or T as the middle base)
mutation_types = ["C>A", "C>G", "C>T", "T>A", "T>C", "T>G"]
bases = ["A", "C", "G", "T"]
contexts_96 = [
    f"{p1}{mut[0]}{p2}>{mut[2]}"
    for mut in mutation_types
    for p1 in bases
    for p2 in bases
]
contexts_96 = pd.Series(contexts_96, name="Context")

# Reverse complement function (if mutation is a G or A, convert to C or T)
def reverse_complement(seq):
    return seq.translate(str.maketrans("ACGT", "TGCA"))[::-1]

def normalize_context(center_base, alt_base, context):
    if center_base in ['C', 'T']:
        return f"{context}>{alt_base}"
    else:
        rc_context = reverse_complement(context)
        rc_alt = reverse_complement(alt_base)
        return f"{rc_context}>{rc_alt}"

# Count trinucleotide contexts from VCF
def count_trinucleotide_contexts(vcf_file, reference):
    counts = Counter()
    total = 0
    with open(vcf_file) as vcf:
        for line in vcf:
            if line.startswith("#"):
                continue
            fields = line.strip().split("\t")
            chrom = fields[0]
            pos = int(fields[1])
            ref_base = fields[3].upper()
            alt_base = fields[4].upper()
            if len(ref_base) != 1 or len(alt_base) != 1:
                continue
            try:
                trinuc_seq = reference.fetch(chrom, pos - 2, pos + 1).upper()
                if len(trinuc_seq) != 3 or 'N' in trinuc_seq:
                    continue
                context = normalize_context(ref_base, alt_base, trinuc_seq)
                counts[context] += 1
                total += 1
            except:
                continue
    return counts, total

# Load and average NanoSeq contexts
try:
    nanoseq_df_all = pd.read_csv(nanoseq_contexts_path)
except Exception as e:
    raise RuntimeError(f"[ERROR] Failed to load nanoseq CSV: {e}")

nanoseq_long_df = nanoseq_df_all.melt(id_vars="SampleID", var_name="Context", value_name="Mutations")
nanoseq_long_df["Mutations"] = pd.to_numeric(nanoseq_long_df["Mutations"], errors="coerce")
nanoseq_long_df = nanoseq_long_df.dropna()

# Step 1: Normalize within each sample
nanoseq_long_df["Total"] = nanoseq_long_df.groupby("SampleID")["Mutations"].transform("sum")
nanoseq_long_df["Proportion"] = nanoseq_long_df["Mutations"] / nanoseq_long_df["Total"]

# Step 2: Average proportions across samples
nanoseq_df = (
    nanoseq_long_df
    .groupby("Context")["Proportion"]
    .mean()
    .reset_index()
)
nanoseq_df = contexts_96.to_frame().merge(nanoseq_df, on="Context", how="left").fillna(0)

# Count trinucleotide mutations, normalize to proportions and merge with full 96 trinucleotide context list
results = []
all_samples_df = []

for vcf_file in vcf_paths:
    sample_id = os.path.basename(vcf_file).split("_")[0]
    context_counts, total_mutations = count_trinucleotide_contexts(vcf_file, ref)

    sample_df = pd.DataFrame.from_dict(context_counts, orient="index", columns=["Mutations"])
    sample_df.index.name = "Context"
    sample_df = sample_df.reset_index()
    sample_df["Proportion"] = sample_df["Mutations"] / total_mutations
    sample_df["SampleID"] = sample_id

    sample_df = contexts_96.to_frame().merge(sample_df, on="Context", how="left").fillna(0)
# Compare sample's trinucleotide profile to NanoSeq reference using cosine similarity
    v1 = sample_df["Proportion"].to_numpy()
    v2 = nanoseq_df["Proportion"].to_numpy()

    cosine_sim = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
    print(f"[INFO] Cosine similarity for {sample_id} = {cosine_sim:.4f}")
    results.append((sample_id, cosine_sim))
    all_samples_df.append(sample_df)

# Write cosine similarity results
metrics_df = pd.DataFrame(results, columns=["SampleID", "Cosine_similarity_score"])
metrics_df.to_csv(output_path, sep="\t", index=False)

print("[INFO] Finished ex_trinucleotide_context_metrics.py")