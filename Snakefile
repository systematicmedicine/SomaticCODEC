
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

Authors:
    - James Phie
    - Cameron Fraser
    - Joshua Johnstone
    - Benjamin Barry
"""

# Load libraries
import pandas as pd

# Set working directory
workdir: config["cwd"]

# Extract experimental sample names from ex_samples.csv
ex_sample_names = list(pd.read_csv(config["ex_samples"])["ex_sample"])

# Create mapping between experimental (codec) and matched sample (standard ngs) sample names
ex_to_ms = pd.read_csv(config["ex_samples"]).set_index("ex_sample")["ms_sample"].to_dict()

# Include rules files
include: "rules/ex_preprocess_fastq.smk"
include: "rules/ex_alignment.smk"
include: "rules/ex_create_dsc.smk"
include: "rules/ex_call_somatic.smk"
include: "rules/ms_preprocess_fastq.smk"
include: "rules/ms_alignment.smk"
include: "rules/ms_call_germ.smk"
include: "rules/ms_personal_ref.smk"
include: "rules/masked_regions.smk"

# Rule all defines all the output that the pipeline will create
rule all:
    input:
        "metrics/demux_metrics.json",
        "metrics/sample_readcounts_metrics.txt",
        "metrics/batchcontamination_metrics.txt",
        "metrics/correctproduct_metrics.txt",
        "metrics/duplication_metrics.txt",
        expand("metrics/{ex_sample}/{ex_sample}_trim_metrics.json", ex_samples=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_trimfilter_metrics.json", ex_samples=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_r1_trimfilter_metrics.html", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_r2_trimfilter_metrics.html", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_map_umi3_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_deduplicated_insert_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_deduplicated_insert_metrics.pdf", ex_sample=ex_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_dsc_depth_metrics.txt", ex_sample=ex_sample_names),
        expand("metrics/duplication_metrics.txt", ex_sample=ex_sample_names),