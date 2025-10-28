
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

# Set working directory
os.chdir(workflow.basedir)

# ---------------------------------------------------------------------------------------------
# Define pipeline outputs
# ---------------------------------------------------------------------------------------------

# Import pipeline outputs
include: "definitions/pipeline_outputs.smk"

# Define rule all
rule all:
    input:
        global_setup + 
        ms_processing_metrics + 
        ex_processing_metrics +
        ex_variant_calling +
        ex_variant_analysis +
        global_metrics

# ---------------------------------------------------------------------------------------------
# Include rules files
# ---------------------------------------------------------------------------------------------

include: "rules/include_all.smk"