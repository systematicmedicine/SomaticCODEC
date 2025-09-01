
"""
--- Snakefile ---

Top-level snakefile that runs codec-opensource pipeline

Inputs: 
    - Raw FASTQ files of Illumina sequenced CODEC libraries
    - Raw FASTQ files of Illumina sequenced matched samples
    - Reference files (e.g. GRCh38)

Outputs:
    - Called somatic variants
    - Metrics files

Abbreviations:
    - ex: experimental samples (CODEC library prep, used to call somatic variants)
    - ms: matched samples (Standard Illumina library prep, used to determine germline variants for each donor)

Authors:
    - James Phie
    - Cameron Fraser
    - Joshua Johnstone
    - Benjamin Barry
"""


# ---------------------------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------------------------

# Load libraries
import os
import scripts.get_metadata as md

# Set working directory
os.chdir(workflow.basedir)

# ---------------------------------------------------------------------------------------------
# Define pipeline outputs
# ---------------------------------------------------------------------------------------------

# Get lists of sample ids
ex_lane_ids = md.get_ex_lane_ids(config)
ex_sample_ids = md.get_ex_sample_ids(config)
ms_sample_ids = md.get_ms_sample_ids(config)

# Define setup files
setup_files = [
    "logs/pipeline/check_ex_ms_mapping.done",
    config["files"]["reference_genome"] + ".amb",
    config["files"]["reference_genome"] + ".ann",
    config["files"]["reference_genome"] + ".bwt.2bit.64",
    config["files"]["reference_genome"] + ".pac",
    config["files"]["reference_genome"] + ".0123",
    "logs/pipeline/check_variant_calling_chroms_present.done",
    "tmp/downloads/non_variant_calling_chroms.bed",
    config["files"]["reference_genome"] + ".fai",
    os.path.splitext(config["files"]["reference_genome"])[0] + ".dict",
    expand("tmp/{ex_lane}/{ex_lane}_{region}.fasta", 
    ex_lane = md.get_ex_lane_ids(config), 
    region = ["r1_start", "r1_end", "r2_start", "r2_end"])
]

# Define results
results = [
    expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample = ex_sample_ids)
]

# Define metrics for ex samples
ex_metrics = [
    expand("metrics/{ex_lane}/{ex_lane}_demux_metrics.txt", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_demux_counts_and_gini.json", ex_lane = ex_lane_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trim_5prime_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r1_trim_3prime_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r2_trim_3prime_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_bases_trimmed.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trimmed_read_length_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_filter_length.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_filter_quality.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.html", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.html", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics_summary.json", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics_summary.json", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_read_counts.json", ex_lane = ex_lane_ids),
    expand("metrics/{ex_sample}/{ex_sample}_total_read_loss.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.html", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.html", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics_summary.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics_summary.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_duplication_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_insert_metrics.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_somatic_variant_rate.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_call_dsc_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_call_codec_consensus_metrics.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_dsc_remap_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_percent_eligible_N_bases.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_softclipping_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trinucleotide_context_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trinucleotide_context_histogram.pdf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_read_counts.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_germline_matches.vcf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_germline_matches.json", ex_sample = ex_sample_ids),
    "metrics/batch/batch_recurrent_variant_metrics.json"
]

# Define metrics for ms samples
ms_metrics = [
    expand("metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_trim_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filtered_fq_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_dedup_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_duplication_metrics_ms.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_alignment_stats.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_depth_summary.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_depth_histogram_fractions.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_candidate_variant_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_ms_het_hom_ratio.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_candidate_variant_metrics_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_read_counts.json", ms_sample = ms_sample_ids)
]

# Define other metrics
other_metrics = [
    "logs/pipeline/git_metadata.json",
    "metrics/metrics_report.csv",
    "metrics/metrics_heatmap.png",
    "logs/pipeline/combined_benchmarks.csv"
]

# Define rule all
rule all:
    input:
        setup_files + results + ex_metrics + ms_metrics + other_metrics


# ---------------------------------------------------------------------------------------------
# Include required rules files
# ---------------------------------------------------------------------------------------------

include: "rules/setup.smk"
include: "rules/ms_preprocess_fastq.smk"
include: "rules/ms_alignment.smk"
include: "rules/ms_call_germ.smk"
include: "rules/ms_metrics.smk"
include: "rules/ex_preprocess_fastq.smk"
include: "rules/ex_alignment.smk"
include: "rules/ex_create_dsc.smk"
include: "rules/ex_call_somatic.smk"
include: "rules/ex_metrics.smk"
include: "rules/masked_regions.smk"
include: "rules/other_metrics.smk"        