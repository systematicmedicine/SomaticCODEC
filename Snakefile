
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
include: "rules/define_outputs.smk"

# Define rule all
rule all:
    input:
        setup_files + 
        ms_metrics + 
        ex_metrics +
        other_metrics +
        results

# ---------------------------------------------------------------------------------------------
# Include rules files
# ---------------------------------------------------------------------------------------------

# Matched samples (MS)
include: "rules/ms_preprocess_fastq.smk"
include: "rules/ms_alignment.smk"
include: "rules/ms_masked_regions.smk"
include: "rules/ms_metrics.smk"

# Experimental samples (EX)
include: "rules/ex_demultiplex.smk"
include: "rules/ex_technical_controls.smk"
include: "rules/ex_preprocess_fastq.smk"
include: "rules/ex_alignment.smk"
include: "rules/ex_create_dsc.smk"
include: "rules/ex_call_somatic.smk"
include: "rules/ex_metrics.smk"

# Other
include: "rules/setup.smk"
include: "rules/other_metrics.smk"      