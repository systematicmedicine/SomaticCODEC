#!/usr/bin/env python3
"""
--- ex_trinucleotide_context_metrics.py ---

Calculate normalised trinucleotide context for a sample, and compare to reference
contexts.

Designed to be used exclusively with rule "ex_trinucleotide_context_metrics.smk"

Authors:
  - Cameron Fraser
  - Joshua Johnstone
"""

# ---------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------

import sys
import pandas as pd
import numpy as np
from cyvcf2 import VCF
from pyfaidx import Fasta
from collections import Counter
from Bio.Seq import Seq
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import seaborn as sns
from pypdf import PdfReader, PdfWriter
import argparse

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

def get_genome_trinuc_counts_props(ref_trinuc_counts_path):
    """Extract trinucleotide proportions from provided reference trinucleotide counts"""
    # Load reference trinucleotide counts
    ref_trinuc_counts = pd.read_csv(ref_trinuc_counts_path)

    # Build counter object
    counts = Counter(dict(zip(ref_trinuc_counts['trinucleotide'], ref_trinuc_counts['trinuc_genome_count'])))

    # Convert counts to proportions
    total = sum(counts.values())
    proportions = {trinuc: count / total for trinuc, count in counts.items()}

    return counts, proportions

def get_variant_call_eligible_trinuc_counts_props(ref_genome, vcf_all):
    """Extract depth-weighted trinucleotide proportions for variant call eligible regions"""
    vcf = VCF(vcf_all)
    counts = Counter()

    # Process each position that was eligible for variant calling 
    for var in vcf:
        chrom = var.CHROM
        pos = var.POS - 1  # Convert 1-based VCF positions to 0-based
        ref_base = var.REF.upper()
        dp = var.INFO.get("DP", 0)
        
        # Skip positions at ends of sequence (no flanking bases)
        if pos == 0 or pos >= len(ref_genome[chrom]) - 1:
            continue

        # Get reference sequence for bases flanking position
        trinuc = ref_genome[chrom][pos-1:pos+2].seq.upper()

        # Skip trinucleotides containing N
        if "N" in trinuc:
            continue
        if ref_base == "N":
            continue

        # Convert to pyrimidine-centered
        center = trinuc[1]
        if center in "AG":
            trinuc = str(Seq(trinuc).reverse_complement())
            center = trinuc[1]

        # Weight trinucleotide count by depth
        counts[trinuc] += dp

    total = sum(counts.values())
    proportions = {tri: count/total for tri, count in counts.items()}

    return counts, proportions

def get_sample_trinuc_context_counts(vcf_path, ref_genome):
    """Extract mutation trinucleotide context counts from a VCF"""
    vcf = VCF(vcf_path)
    context_counts = Counter()

    for variant in vcf:
        if not variant.ALT or len(variant.REF) != 1 or len(variant.ALT[0]) != 1:
            continue  # Skip non-SNVs or malformed ALT

        chrom = variant.CHROM
        pos = variant.POS
        ref_base = variant.REF.upper()
        alt_base = variant.ALT[0].upper()
        ad = variant.format("AD")

        # Get alt depth for SNV
        alt_depth = ad[0][1]

        # Find reference bases for positions flanking SNV
        try:
            left = ref_genome[chrom][pos - 2].seq.upper()
            center = ref_base
            right = ref_genome[chrom][pos].seq.upper()

            if ref_base in ['C', 'T']:
                context = f"{left}{ref_base}{right}>{alt_base}"
            else:
                # Convert to pyrimidine-centered
                trinuc = Seq(left + center + right).reverse_complement()
                alt_rc = str(Seq(alt_base).reverse_complement())
                context = f"{trinuc[0]}{trinuc[1]}{trinuc[2]}>{alt_rc}"

            # Increase context count by the number of alt reads
            context_counts[context] += alt_depth

        except (KeyError, IndexError):
            continue

    return context_counts

def normalise_sample_trinuc_context_counts(ref_genome_trinuc_proportions, variant_call_eligible_trinuc_proportions, mutation_context_counts):
    """Normalise mutation trinucleotide context counts based on trinucleotide proportions in variant call eligible regions"""
    normalised_counts = {}

    for context, count in mutation_context_counts.items():
        trinuc = context.split(">")[0] # Extract trinucleotide from full context
        if variant_call_eligible_trinuc_proportions.get(trinuc, 0) > 0:
            # Calculate correction factor
            correction_factor = (
                ref_genome_trinuc_proportions.get(trinuc, 0)
                / variant_call_eligible_trinuc_proportions[trinuc]
            )
        else:
            correction_factor = 0

        normalised_counts[context] = count * correction_factor

    return normalised_counts

def get_sample_trinuc_context_proportions(sample_context_counts, contexts):
    """Calculate trinucleotide context proportions from count data"""
    total = sum(sample_context_counts.get(c, 0) for c in contexts)

    proportions = [
        sample_context_counts.get(c, 0) / total if total > 0 else 0.0
        for c in contexts
    ]

    return pd.DataFrame({
        "Context": contexts,
        "Proportion": proportions
    })

def cosine_similarity_np(u, v):
    """Compute cosine similarity between two 1D numpy arrays"""
    num = np.dot(u, v)
    denom = np.linalg.norm(u) * np.linalg.norm(v)
    return num / denom if denom != 0 else 0.0

def calculate_cosine_similarities(sample_proportions_df, profiles, ref_df, contexts, raw_norm):
    """Calculate cosine similarity between sample and reference proportions"""
    sample_vector = sample_proportions_df["Proportion"].values
    similarities = []

    for profile in profiles:
        ref_profile_df = ref_df[ref_df["Profile"] == profile].set_index("Context")
        ref_vector = ref_profile_df.loc[contexts, "Proportion"].values
        similarity = cosine_similarity_np(np.array(sample_vector), ref_vector)
        similarities.append({
            "Profile": profile,
            f"cosine_sim_{raw_norm}": similarity
        })

    similarity_df = pd.DataFrame(similarities).sort_values(f"cosine_sim_{raw_norm}", ascending=False)
    similarity_dict = similarity_df.set_index("Profile")[f"cosine_sim_{raw_norm}"].to_dict()

    return similarity_df, similarity_dict

def generate_comparison_plots(similarity_dict, ref_df, sample_proportions_df, sample_name, output_pdf, contexts):
    print(f"[INFO] Generating comparison plots to {output_pdf}")
    pages = []

    with PdfPages(output_pdf) as pdf:
        for profile in similarity_dict.keys():
            ref_profile_df = ref_df[ref_df["Profile"] == profile]
            similarity = similarity_dict[profile]

            merged = pd.merge(
                sample_proportions_df.rename(columns={"Proportion": sample_name}),
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
            long_df["Context"] = pd.Categorical(long_df["Context"], categories=contexts, ordered=True)
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

    reader = PdfReader(output_pdf)
    writer = PdfWriter()

    for i, page in enumerate(reader.pages):
        writer.add_page(page)
        writer.add_outline_item(pages[i], i)

    with open(output_pdf, "wb") as f_out:
        writer.write(f_out)

    print("[INFO] Bookmarks added successfully.")

# ---------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------

def main(args):

    # Start logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_trinucleotide_context_metrics.py")

    # Define inputs
    vcf_path = args.vcf_path
    vcf_all_path = args.vcf_all_path
    ref_fasta_path = args.ref_fasta_path
    ref_contexts_path = args.ref_contexts_path
    ref_trinuc_counts_path = args.ref_trinuc_counts_path

    # Define outputs
    output_proportions_csv = args.proportions_csv
    output_similarities_csv = args.similarities_csv
    output_plot_pdf_normalised = args.plot_pdf_normalised

    # Define params
    SAMPLE_NAME = args.sample

    # Define contexts
    CONTEXTS = get_contexts()

    # Load reference contexts
    ref_df = pd.read_csv(ref_contexts_path)
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

    # Get trinucleotide counts and proportions in whole genome
    ref_genome_trinuc_counts, ref_genome_trinuc_proportions = get_genome_trinuc_counts_props(ref_trinuc_counts_path)

    # Get trinucleotide counts and proportions in variant call eligible regions (weighted by depth)
    variant_call_eligible_trinuc_counts, variant_call_eligible_trinuc_proportions = get_variant_call_eligible_trinuc_counts_props(ref_genome, vcf_all_path)

    # Get raw mutation counts for each trinucleotide context
    sample_counts_raw = get_sample_trinuc_context_counts(vcf_path, ref_genome)

    # Normalise sample trinucleotide mutation counts
    sample_counts_normalised = normalise_sample_trinuc_context_counts(ref_genome_trinuc_proportions, variant_call_eligible_trinuc_proportions, sample_counts_raw)

    # Compute sample context proportions and output to CSV
    sample_proportions_raw = get_sample_trinuc_context_proportions(sample_counts_raw, CONTEXTS)
    sample_proportions_normalised = get_sample_trinuc_context_proportions(sample_counts_normalised, CONTEXTS)

    total_snvs_raw = sum(sample_counts_raw.values())
    total_snvs_norm = sum(sample_counts_normalised.values())

    proportions_csv_rows = []

    for context in CONTEXTS:
        trinuc = context.split(">")[0]

        genome_count = ref_genome_trinuc_counts.get(trinuc, 0)
        genome_prop = ref_genome_trinuc_proportions.get(trinuc, 0)

        eligible_count = variant_call_eligible_trinuc_counts.get(trinuc, 0)
        eligible_prop = variant_call_eligible_trinuc_proportions.get(trinuc, 0)

        correction_factor = (
            genome_prop / eligible_prop if eligible_prop > 0 else 0
        )

        snv_count_raw = sample_counts_raw.get(context, 0)
        snv_prop_raw = snv_count_raw / total_snvs_raw if total_snvs_raw > 0 else 0

        snv_count_norm = sample_counts_normalised.get(context, 0)
        snv_prop_norm = snv_count_norm / total_snvs_norm if total_snvs_norm > 0 else 0

        proportions_csv_rows.append({
            "context": context,
            "trinucleotide": trinuc,
            "trinuc_genome_count": genome_count,
            "trinuc_genome_prop": round(genome_prop, ndigits = 4),
            "trinuc_var_call_eligible_count": eligible_count,
            "trinuc_var_call_eligible_prop": round(eligible_prop, ndigits = 4),
            "correction_factor": round(correction_factor, ndigits = 4),
            "snv_count_raw": snv_count_raw,
            "snv_prop_raw": round(snv_prop_raw, ndigits = 4),
            "snv_count_norm": round(snv_count_norm, ndigits = 4),
            "snv_prop_norm": round(snv_prop_norm, ndigits = 4)
        })

    proportions_csv = pd.DataFrame(proportions_csv_rows)
    proportions_csv.to_csv(output_proportions_csv, index=False)

    # Compute cosine similarities and output to CSV
    similarity_df_raw, similarity_dict_raw = calculate_cosine_similarities(sample_proportions_raw, profiles, ref_df, CONTEXTS, "raw")
    similarity_df_normalised, similarity_dict_normalised = calculate_cosine_similarities(sample_proportions_normalised, profiles, ref_df, CONTEXTS, "norm")

    similarity_df = similarity_df_raw.merge(similarity_df_normalised, on="Profile", how="inner")
    similarity_df.sort_values("cosine_sim_norm", ascending=False, inplace=True)
    similarity_df.to_csv(output_similarities_csv, index=False)

    # Generate comparison plots
    generate_comparison_plots(similarity_dict_normalised, ref_df, sample_proportions_normalised, SAMPLE_NAME, output_plot_pdf_normalised, CONTEXTS)

    print("[INFO] Finished ex_trinucleotide_context_metrics.py")

if __name__ == "__main__":
    # Snakemake parameter injection
    parser = argparse.ArgumentParser()
    parser.add_argument("--vcf_path", required=True)
    parser.add_argument("--vcf_all_path", required=True)
    parser.add_argument("--ref_fasta_path", required=True)
    parser.add_argument("--ref_contexts_path", required=True)
    parser.add_argument("--ref_trinuc_counts_path", required=True)
    parser.add_argument("--proportions_csv", required=True)
    parser.add_argument("--similarities_csv", required=True)
    parser.add_argument("--plot_pdf_normalised", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)