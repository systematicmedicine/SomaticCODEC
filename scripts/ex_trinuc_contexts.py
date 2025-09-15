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

import sys
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_trinuc_contexts.py")

import pandas as pd
import numpy as np
from cyvcf2 import VCF
from pyfaidx import Fasta
from collections import Counter
from Bio.Seq import Seq
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import seaborn as sns
import PyPDF2

# Snakemake parameter injection
vcf_path = snakemake.input.vcf_path
ref_fasta_path = snakemake.input.ref_fasta_path
context_csv_path = snakemake.input.context_csv_path
output_sample_csv = snakemake.output.sample_csv
output_similarity_csv = snakemake.output.similarities_csv
output_plot_pdf = snakemake.output.plot_pdf
sample_name = snakemake.wildcards.ex_sample

# ---------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------
def get_contexts():
    """Generate 96 canoncial trinucleotide contexts""" 
    return [
        f"{left}{mut[0]}{right}>{mut[2]}"
        for mut in ["C>A", "C>G", "C>T", "T>A", "T>C", "T>G"]
        for left in "ACGT"
        for right in "ACGT"
    ]

def cosine_similarity_np(u, v):
    """Compute cosine similarity between two 1D numpy arrays"""
    num = np.dot(u, v)
    denom = np.linalg.norm(u) * np.linalg.norm(v)
    return num / denom if denom != 0 else 0.0


def get_sample_trinuc_context(vcf_path, ref_genome, contexts):
    """Extract trinucleotide contexts from a VCF and return normalized proportions."""
    vcf = VCF(vcf_path)
    sample_contexts = []

    for variant in vcf:
        if not variant.ALT or len(variant.REF) != 1 or len(variant.ALT[0]) != 1:
            continue  # Skip non-SNVs or malformed ALT

        chrom = variant.CHROM
        pos = variant.POS
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
            continue

    context_counts = Counter(sample_contexts)
    total = sum(context_counts.get(c, 0) for c in contexts)
    proportions = [
        context_counts.get(c, 0) / total if total > 0 else 0.0
        for c in contexts
    ]

    return pd.DataFrame({
        "Context": contexts,
        "Proportion": proportions
    })

# ---------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------

# Define contexts
CONTEXTS = get_contexts()

# Load reference contexts
ref_df = pd.read_csv(context_csv_path)
profiles = ref_df["Profile"].unique()

# Validate all profiles include exactly the 96 canonical contexts
for profile in profiles:
    sub = ref_df[ref_df["Profile"] == profile]
    contexts_in_profile = set(sub["Context"])
    missing = set(CONTEXTS) - contexts_in_profile
    extra = contexts_in_profile - set(CONTEXTS)
    if missing or extra:
        raise ValueError(
            f"[ERROR] Profile '{profile}' does not follow canonical 96-context schema.\n"
            f"  Missing: {sorted(missing)}\n"
            f"  Extra:   {sorted(extra)}"
        )

# Load reference genome
ref_genome = Fasta(ref_fasta_path, rebuild=False)

# Compute sample context proportions
sample_df = get_sample_trinuc_context(vcf_path, ref_genome, CONTEXTS)
sample_df.to_csv(output_sample_csv, index=False)

# Compute cosine similarities
sample_vector = sample_df["Proportion"].values
similarities = []

for profile in profiles:
    ref_profile_df = ref_df[ref_df["Profile"] == profile].set_index("Context")
    ref_vector = ref_profile_df.loc[CONTEXTS, "Proportion"].values
    similarity = cosine_similarity_np(np.array(sample_vector), ref_vector)
    similarities.append({
        "Profile": profile,
        "CosineSimilarity": similarity
    })

similarity_df = pd.DataFrame(similarities).sort_values("CosineSimilarity", ascending=False)
similarity_df.to_csv(output_similarity_csv, index=False)
sim_dict = similarity_df.set_index("Profile")["CosineSimilarity"].to_dict()

# ---------------------------------------------------------------------
# Generate comparison plots
# ---------------------------------------------------------------------

print(f"[INFO] Generating comparison plots to {output_plot_pdf}")
pages = []

with PdfPages(output_plot_pdf) as pdf:
    for profile in sim_dict.keys():
        ref_profile_df = ref_df[ref_df["Profile"] == profile]
        similarity = sim_dict[profile]

        merged = pd.merge(
            sample_df.rename(columns={"Proportion": sample_name}),
            ref_profile_df[["Context", "Proportion"]].rename(columns={"Proportion": profile}),
            on="Context",
            how="left"
        )

        long_df = pd.melt(
            merged,
            id_vars="Context",
            var_name="Source",
            value_name="Proportion"
        )
        long_df["Context"] = pd.Categorical(long_df["Context"], categories=CONTEXTS, ordered=True)
        long_df = long_df.sort_values("Context")

        fig, ax = plt.subplots(figsize=(20, 6))
        sns.barplot(data=long_df, x="Context", y="Proportion", hue="Source", ax=ax)

        ax.set_title(f"{sample_name} vs {profile} (Cosine similarity: {similarity:.3f})", fontsize=12)
        ax.set_xlabel("Context")
        ax.set_ylabel("Proportion")
        ax.tick_params(axis="x", rotation=90, labelsize=6)
        plt.tight_layout()

        pdf.savefig(fig)
        plt.close()
        pages.append(profile)

print("[INFO] Plot generation complete. Adding bookmarks...")

reader = PyPDF2.PdfReader(output_plot_pdf)
writer = PyPDF2.PdfWriter()

for i, page in enumerate(reader.pages):
    writer.add_page(page)
    writer.add_outline_item(pages[i], i)

with open(output_plot_pdf, "wb") as f_out:
    writer.write(f_out)

print("[INFO] Bookmarks added successfully.")
print("[INFO] Finished ex_trinuc_contexts.py")
