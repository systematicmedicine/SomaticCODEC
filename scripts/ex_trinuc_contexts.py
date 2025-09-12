# =====================================================================
# ex_trinuc_conexts.py
#
# Calculate trinucleotide context for a sample, and compare to reference
# contexts.
#
# Inputs:
#   - Somatic variant VCF
#   - Reference genome
#   - Reference contexts in long format (Profile, Context, Proportion)
#
# Assumes that contexts are expressed in ATA>G format. Assumes proportions are
# normalised so that they sum to 1 for any sample/reference context. Profile
# referes to the names of the reference contexts.
#
# Outputs:
#   - Trinucleotide context for sample
#   - Consine similaries between sample and reference contexts
#   - Plots comparing sample context to reference contexts
#
# Authors:
#   - Chat-GPT
#   - Cameron Fraser
# =====================================================================

# ---------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------

# Redirect stdout/stderr to Snakemake log
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_trinuc_contexts.py")

# Load libraries
import pandas as pd
import numpy as np
from cyvcf2 import VCF
from pyfaidx import Fasta
from collections import Counter
from Bio.Seq import Seq

# Snakemake parameter injection
vcf_path = snakemake.input.vcf_path
ref_fasta_path = snakemake.input.ref_fasta_path
context_csv_path = snakemake.input.context_csv_path
output_sample_csv = snakemake.output.sample_csv
output_similarity_csv = snakemake.output.similarities_csv

# ---------------------------------------------------------------------
# Custom functions
# ---------------------------------------------------------------------
def cosine_similarity_np(u, v):
    """Compute cosine similarity between two 1D numpy arrays"""
    num = np.dot(u, v)
    denom = np.linalg.norm(u) * np.linalg.norm(v)
    return num / denom if denom != 0 else 0.0

# ---------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------

# Load reference contexts (96 context rows per profile)
ref_df = pd.read_csv(context_csv_path)
contexts = sorted(ref_df["Context"].unique())  # Ensure consistent order
profiles = ref_df["Profile"].unique()

# Load reference genome FASTA
ref_genome = Fasta(ref_fasta_path, rebuild=False)

# Parse VCF and extract trinucleotide contexts
vcf = VCF(vcf_path)
sample_contexts = []

for variant in vcf:
    if len(variant.REF) != 1 or len(variant.ALT[0]) != 1:
        continue  # Skip non-SNVs

    chrom = variant.CHROM
    pos = variant.POS  # 1-based
    ref_base = variant.REF.upper()
    alt_base = variant.ALT[0].upper()

    try:
        left = ref_genome[chrom][pos - 2].seq.upper()
        center = ref_base
        right = ref_genome[chrom][pos].seq.upper()

        if ref_base in ['C', 'T']:
            context = f"{left}{ref_base}{right}>{alt_base}"
        else:
            trinuc = Seq(left + center + right).reverse_complement()
            alt_rc = str(Seq(alt_base).reverse_complement())
            context = f"{trinuc[0]}{trinuc[1]}{trinuc[2]}>{alt_rc}"

        sample_contexts.append(context)

    except (KeyError, IndexError):
        continue  # Cannot fetch context

# Normalize to proportions (to match reference profiles)
context_counts = Counter(sample_contexts)
total = sum(context_counts.get(c, 0) for c in contexts)
sample_vector = [context_counts.get(c, 0) / total if total > 0 else 0.0 for c in contexts]

sample_df = pd.DataFrame({
    "Context": contexts,
    "Proportion": sample_vector
})
sample_df.to_csv(output_sample_csv, index=False)


# Cosine similarity with each reference profile
similarities = []

for profile in profiles:
    ref_profile = (
        ref_df[ref_df["Profile"] == profile]
        .set_index("Context")
        .loc[contexts, "Proportion"]
        .values
    )
    similarity = cosine_similarity_np(np.array(sample_vector), ref_profile)
    similarities.append({
        "Profile": profile,
        "CosineSimilarity": similarity
    })

similarity_df = pd.DataFrame(similarities).sort_values("CosineSimilarity", ascending=False)
similarity_df.to_csv(output_similarity_csv, index=False)

# Log that script is finished
print("[INFO] Starting ex_trinuc_contexts.py")