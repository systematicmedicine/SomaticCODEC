
"""
--- Snakefile ---

Top-level snakefile that orchestrates SomaticCodec pipeline

Author: Cameron Fraser
"""

# ---------------------------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------------------------

# Load libraries
import os

# Set working directory
os.chdir(workflow.basedir)

# ---------------------------------------------------------------------------------------------
# Include rules files
# ---------------------------------------------------------------------------------------------

include: "rules/include_all.smk"

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

