
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
"""


# ---------------------------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------------------------

# Load libraries
import os
import helpers.get_metadata as md

# Set working directory
os.chdir(workflow.basedir)

# ---------------------------------------------------------------------------------------------
# Define pipeline outputs
# ---------------------------------------------------------------------------------------------

# Get lists of sample ids
ex_lane_ids = md.get_ex_lane_ids(config)
ex_sample_ids = md.get_ex_sample_ids(config)
ex_technical_control_ids = md.get_ex_technical_control_ids(config)
ms_sample_ids = md.get_ms_sample_ids(config)

# Define setup files
setup_files = [
    config["sci_params"]["global"]["reference_genome"] + ".amb",
    config["sci_params"]["global"]["reference_genome"] + ".ann",
    config["sci_params"]["global"]["reference_genome"] + ".bwt.2bit.64",
    config["sci_params"]["global"]["reference_genome"] + ".pac",
    config["sci_params"]["global"]["reference_genome"] + ".0123",
    config["sci_params"]["global"]["reference_genome"] + ".fai",
    os.path.splitext(config["sci_params"]["global"]["reference_genome"])[0] + ".dict",
    config["sci_params"]["global"]["known_germline_variants"] + ".tbi",
    "tmp/downloads/excluded_chromosomes.bed",
    "logs/global_rules/check_included_chromosomes_present.done",
    "logs/global_rules/log_system_resource_usage.done",
    "logs/global_rules/check_ex_ms_mapping.done",
    "logs/bin_scripts/run_pipeline.log"
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
    expand("metrics/{ms_sample}/{ms_sample}_filter_metrics_ms.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_dedup_metrics.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_duplication_metrics_ms.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_alignment_stats.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_coverage_by_depth.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics_summary.json", ms_sample = ms_sample_ids),
    expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.json", ms_sample = ms_sample_ids)
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
    expand("metrics/{ex_sample}/{ex_sample}_filter_metrics_ex.txt", ex_sample = ex_sample_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.html", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.html", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics_summary.json", ex_lane = ex_lane_ids),
    expand("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics_summary.json", ex_lane = ex_lane_ids),
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
    expand("metrics/{ex_sample}/{ex_sample}_softclipping_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_variant_call_disagree_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trinuc_context.csv", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trinuc_similarities.csv", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_trinuc_plots.pdf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_snv_distance.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_snv_position_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_snv_position_plot.pdf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_germline_matches.vcf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_gnomAD_overlap_metrics.json", ex_sample = ex_sample_ids),
    expand("metrics/{ex_sample}/{ex_sample}_somatic_variant_germline_contexts.vcf", ex_sample = ex_sample_ids),
    expand("metrics/{ex_technical_control}/{ex_technical_control}_trimmed_read_length_metrics_tc.json", ex_technical_control = ex_technical_control_ids),
    "metrics/batch/batch_recurrent_variants.vcf",
    "metrics/batch/batch_recurrent_variant_metrics.json",
]

# Define other metrics
other_metrics = [
    "logs/global_rules/git_metadata.json",
    "metrics/metrics_report.csv",
    "metrics/metrics_heatmap.png",
    "logs/global_rules/combined_benchmarks.csv",
    "logs/global_rules/system_resource_usage.csv",
    "logs/global_rules/job_log.csv",
    "logs/global_rules/create_run_timeline_plot.log"
]

# Define results
results = [
    expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample = ex_sample_ids)
]

# Define rule all
rule all:
    input:
        setup_files + 
        ms_metrics + 
        #ex_metrics +
        other_metrics +
        results


# ---------------------------------------------------------------------------------------------
# Include required rules files
# ---------------------------------------------------------------------------------------------

include: "rules/setup.smk"
include: "rules/ms_preprocess_fastq.smk"
include: "rules/ms_alignment.smk"
include: "rules/ms_masked_regions.smk"
include: "rules/ms_metrics.smk"
include: "rules/ex_demultiplex.smk"
include: "rules/ex_technical_controls.smk"
include: "rules/ex_preprocess_fastq.smk"
include: "rules/ex_alignment.smk"
include: "rules/ex_create_dsc.smk"
include: "rules/ex_call_somatic.smk"
include: "rules/ex_metrics.smk"
include: "rules/other_metrics.smk"        