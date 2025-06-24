
"""
--- Snakefile ---

Top-level Snakefile that runs entire pipeline.
All rules (except rule all) are defined in .smk files in /rules directory.


Inputs: 
    - Raw FASTQ files of Illumina sequenced CODEC libraries
    - Raw FASTQ files of Illumina sequenced matched samples
    - Reference files (e.g. GRCh38)

Outputs:
    - Called somatic variants
    - Metrics files

Abbreviations:
    - EX: Experimental samples (CODEC library prep, used to call somatic variants)
    - MS: Matched samples (Standard Illumina library prep, used to determine germline variants for each person)

Authors:
    - James Phie
    - Cameron Fraser
    - Joshua Johnstone
    - Benjamin Barry
"""

# Load libraries
import os
import pandas as pd

# Set working directory
os.chdir(workflow.basedir)

# Load additional config data
ex_samples = pd.read_csv(config["ex_samples_path"])
ex_adapters = pd.read_csv(config["ex_adapters_path"])
ms_samples = pd.read_csv(config["ms_samples_path"])
component_metrics = pd.read_csv(config["component_metrics_path"])

# Include rules files

include: "rules/ms_preprocess_fastq.smk"
include: "rules/ms_alignment.smk"
include: "rules/ms_call_germ.smk"
include: "rules/ms_metrics.smk"
include: "rules/ex_preprocess_fastq.smk"
include: "rules/ex_alignment.smk"
include: "rules/ex_create_dsc.smk"
include: "rules/ex_call_somatic.smk"
include: "rules/ex_metrics.smk"
include: "rules/index_reference_genome.smk"
include: "rules/masked_regions.smk"

# Rule all defines all the output that the pipeline will create
rule all:
    input:
        expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample=ex_sample_names),
        expand("results/{ex_sample}/{ex_sample}_somatic_variant_rate.txt", ex_sample=ex_sample_names),
        expand("metrics/{lane}/{lane}_demux_metrics.json", lane=ex_lanes),
        expand("metrics/{lane}/{lane}_r1_fastqc_raw_metrics.html",lane=ex_lanes),
        expand("metrics/{lane}/{lane}_r2_fastqc_raw_metrics.html",lane=ex_lanes),
        expand("metrics/{lane}/{lane}_sample_readcounts_metrics.txt", lane=ex_lanes),
        expand("metrics/{lane}/{lane}_batchcontamination_metrics.txt", lane=ex_lanes),
        expand("metrics/{lane}/{lane}_correctproduct_metrics.txt", lane=ex_lanes),
        expand("metrics/{ex_sample}/{ex_sample}_trim_metrics.json", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_filter_metrics.json", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_r1_filter_metrics.html", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_r2_filter_metrics.html", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_map_umi3_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_insert_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_dsc_depth_metrics.txt", ex_sample=ex_sample_names),
        "metrics/ex_duplication_metrics.txt",
        expand("metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_trimfilter_metrics.tsv", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_trimfilter_r1_fastqc.html", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_trimfilter_r2_fastqc.html", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_markdup_metrics.txt", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_alignment_stats.txt", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_depth_stats.txt", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.txt", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_variantCall_unfiltered_summary.txt", ms_sample = ms_sample_names),
        expand("metrics/{ms_sample}/{ms_sample}_variantCall_filtered_summary.txt", ms_sample = ms_sample_names),
        "metrics/component_metrics_report.csv"