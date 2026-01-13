#!/usr/bin/env python3
"""
--- ex_trinucleotide_context_metrics.py ---

Calculate trinucleotide context for a sample, and compare to reference
contexts.

Inputs:
  - Somatic variant VCF
  - Reference genome
  - Reference contexts in long format (Profile, Context, Proportion)

Assumes that contexts are expressed in ATA>G format. Assumes proportions are
normalised so that they sum to 1 for any sample/reference context. Profile
referes to the names of the reference contexts.

Outputs:
  - Trinucleotide context for sample
  - Consine similaries between sample and reference contexts
  - Plots comparing sample context to reference contexts

Authors:
  - Chat-GPT
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
from Bio import SeqIO
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import seaborn as sns
from pypdf import PdfReader, PdfWriter
import argparse
import subprocess
from helpers.fai_helpers import get_chrom_lengths, get_chrom_offsets
from helpers.bam_helpers import depth_array_BQ_bed

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

def get_sample_trinuc_context_counts(vcf_path, ref_genome):
    """Extract mutation trinucleotide context counts from a VCF"""
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

    return context_counts

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

def calculate_cosine_similarities(sample_proportions_df, profiles, ref_df, contexts):
    """Calculate cosine similarity between sample and reference proportions"""
    sample_vector = sample_proportions_df["Proportion"].values
    similarities = []

    for profile in profiles:
        ref_profile_df = ref_df[ref_df["Profile"] == profile].set_index("Context")
        ref_vector = ref_profile_df.loc[contexts, "Proportion"].values
        similarity = cosine_similarity_np(np.array(sample_vector), ref_vector)
        similarities.append({
            "Profile": profile,
            "CosineSimilarity": similarity
        })

    similarity_df = pd.DataFrame(similarities).sort_values("CosineSimilarity", ascending=False)
    similarity_dict = similarity_df.set_index("Profile")["CosineSimilarity"].to_dict()

    return similarity_df, similarity_dict

def get_variant_call_eligible_sequence(ref_fasta, include_bed, output_fasta):
    """Extract sequences for variant call eligible regions using bedtools"""

    cmd = [
        "bedtools", "getfasta",
        "-fi", ref_fasta,
        "-bed", include_bed,
        "-fo", output_fasta
    ]

    subprocess.run(cmd, check=True)

def get_genome_trinuc_proportions(ref_fasta, ref_genome_length, threads):
    """Extract trinucleotide proportions from a reference genome sequence"""
    counts = Counter()
    hash_size = int(ref_genome_length) * 2

    # Count trinucleotides in sequence
    trinuc_counts_jf_file = ref_fasta + ".jf"
    subprocess.run([
        "jellyfish", "count",
        "--mer-len", "3",
        "--size", str(hash_size),
        "--threads", str(threads),
        "--output", trinuc_counts_jf_file,
        ref_fasta
    ], check=True)

    # Dump counts into column format
    result = subprocess.run([
        "jellyfish", 
        "dump", 
        "-c", 
        trinuc_counts_jf_file
        ], capture_output=True, text=True, check=True)
    
    # Collapse context counts to pyrimidine-centred context
    for line in result.stdout.strip().split("\n"):
        trinuc, count_str = line.strip().split()
        count = int(count_str)
        center = trinuc[1]
        if center in "AG":
            trinuc = str(Seq(trinuc).reverse_complement())
        counts[trinuc] += count

    # Convert counts to proportions
    total = sum(counts.values())
    return {trinuc: count / total for trinuc, count in counts.items()}

def get_sample_trinuc_proportions(depth_array, ref_fasta, include_bed, chrom_lengths):
    """Extract depth-weighted sample trinucleotide proportions"""
    counts = Counter()

    # Load chromosome position offsets
    offsets, _ = get_chrom_offsets(chrom_lengths)

    # Load reference sequences
    ref_seqs = {r.id: str(r.seq).upper() for r in SeqIO.parse(ref_fasta, "fasta")}

    with open(include_bed) as bed:
        # Get reference sequence for each BED region
        for line in bed:
            if line.startswith("#") or line.strip() == "":
                continue
            chrom, start, end = line.strip().split()[:3]
            start = int(start)
            end = int(end)
            seq = ref_seqs[chrom][start:end]

            # Identify trinucleotides with 3bp sliding window
            for i in range(1, len(seq)-1):
                trinuc = seq[i-1:i+2]
                center = trinuc[1]
                # Convert to pyrimidine-centered
                if center in "AG":
                    trinuc = str(Seq(trinuc).reverse_complement())
                    center = trinuc[1]

                # Get depth at central base
                central_pos = start + i
                genome_index = offsets[chrom] + central_pos
                depth_at_pos = depth_array[genome_index]

                # Get depth-weighted trinucleotide count
                counts[trinuc] += depth_at_pos

    # Convert counts to proportions
    total = sum(counts.values())
    proportions = {trinuc: count/total for trinuc, count in counts.items()}
    return proportions

def normalise_sample_trinuc_context_counts(ref_genome_trinuc_proportions, sample_trinuc_proportions, mutation_context_counts):
    """Normalise mutation trinucleotide context counts based on trinucleotide proportions in variant call eligible regions"""
    normalized_counts = {}

    for context, count in mutation_context_counts.items():
        trinuc = context.split(">")[0] # Extract trinucleotide
        if sample_trinuc_proportions.get(trinuc, 0) > 0:
            # Calculate correction factor
            correction_factor = (
                ref_genome_trinuc_proportions.get(trinuc, 0)
                / sample_trinuc_proportions[trinuc]
            )
        else:
            correction_factor = 0

        normalized_counts[context] = count * correction_factor

    return normalized_counts

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
    ref_fasta_path = args.ref_fasta_path
    ref_fai_path = args.ref_fai_path
    include_bed_path = args.include_bed_path
    ref_contexts_path = args.ref_contexts_path
    ex_dsc_bam_path = args.ex_dsc_bam

    # Define outputs
    output_sample_csv_raw = args.sample_csv_raw
    output_sample_csv_normalised = args.sample_csv_normalised
    output_similarity_csv_raw = args.similarities_csv_raw
    output_similarity_csv_normalised = args.similarities_csv_normalised
    output_plot_pdf_raw = args.plot_pdf_raw
    output_plot_pdf_normalised = args.plot_pdf_normalised

    # Define params
    SAMPLE_NAME = args.sample
    THREADS = int(args.threads)
    EX_BQ_THRESHOLD = int(args.ex_bq_threshold)

    # Define contexts
    CONTEXTS = get_contexts()

    # Calculate ref genome length
    fai_df = pd.read_csv(ref_fai_path, sep="\t", header=None)
    fai_df.columns = ["chrom", "length", "offset", "line_bases", "line_width"]
    genome_length = fai_df["length"].sum()

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

    # Get raw mutation counts for each trinucleotide context
    sample_counts_raw = get_sample_trinuc_context_counts(vcf_path, ref_genome)

    # Get trinucleotide proportions in whole genome and in variant call eligible regions
    ref_genome_trinuc_proportions = get_genome_trinuc_proportions(ref_fasta_path, genome_length, THREADS)

    #get_variant_call_eligible_sequence(ref_fasta_path, include_bed_path, eligible_regions_fasta)
    chrom_lengths = get_chrom_lengths(ref_fai_path)
    sample_depth_array = depth_array_BQ_bed(ex_dsc_bam_path, chrom_lengths, EX_BQ_THRESHOLD, include_bed_path, THREADS)
    sample_trinuc_proportions = get_sample_trinuc_proportions(sample_depth_array, ref_fasta_path, include_bed_path, chrom_lengths)

    # Normalise trinucleotide mutation counts
    sample_counts_normalised = normalise_sample_trinuc_context_counts(ref_genome_trinuc_proportions, sample_trinuc_proportions, sample_counts_raw)

    # Compute sample context proportions and output to CSV
    sample_proportions_raw = get_sample_trinuc_context_proportions(sample_counts_raw, CONTEXTS)
    sample_proportions_normalised = get_sample_trinuc_context_proportions(sample_counts_normalised, CONTEXTS)
    
    sample_proportions_raw.to_csv(output_sample_csv_raw, index=False)
    sample_proportions_normalised.to_csv(output_sample_csv_normalised, index=False)

    # Compute cosine similarities and output to CSV
    similarity_df_raw, similarity_dict_raw = calculate_cosine_similarities(sample_proportions_raw, profiles, ref_df, CONTEXTS)
    similarity_df_normalised, similarity_dict_normalised = calculate_cosine_similarities(sample_proportions_normalised, profiles, ref_df, CONTEXTS)

    similarity_df_raw.to_csv(output_similarity_csv_raw, index=False)
    similarity_df_normalised.to_csv(output_similarity_csv_normalised, index=False)

    # Generate comparison plots
    generate_comparison_plots(similarity_dict_raw, ref_df, sample_proportions_raw, SAMPLE_NAME, output_plot_pdf_raw, CONTEXTS)
    generate_comparison_plots(similarity_dict_normalised, ref_df, sample_proportions_normalised, SAMPLE_NAME, output_plot_pdf_normalised, CONTEXTS)

    print("[INFO] Finished ex_trinucleotide_context_metrics.py")

if __name__ == "__main__":

    # Snakemake parameter injection
    parser = argparse.ArgumentParser()
    parser.add_argument("--threads", required=True)
    parser.add_argument("--vcf_path", required=True)
    parser.add_argument("--ref_fasta_path", required=True)
    parser.add_argument("--ref_fai_path", required=True)
    parser.add_argument("--include_bed_path", required=True)
    parser.add_argument("--ref_contexts_path", required=True)
    parser.add_argument("--ex_dsc_bam", required=True)
    parser.add_argument("--eligible_regions_fasta", required=True)
    parser.add_argument("--sample_csv_raw", required=True)
    parser.add_argument("--sample_csv_normalised", required=True)
    parser.add_argument("--similarities_csv_raw", required=True)
    parser.add_argument("--similarities_csv_normalised", required=True)
    parser.add_argument("--plot_pdf_raw", required=True)
    parser.add_argument("--plot_pdf_normalised", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--ex_bq_threshold", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)