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
# Add scripts to PATH and PYTHONPATH
# ---------------------------------------------------------------------------------------------

for root, dirs, files in os.walk(os.path.join(workflow.basedir, "scripts")):
    os.environ["PATH"] = root + os.pathsep + os.environ.get("PATH", "")

os.environ["PYTHONPATH"] = os.path.abspath(".") + os.pathsep + os.environ.get("PYTHONPATH", "")

# ---------------------------------------------------------------------------------------------
# Define pipeline outputs
# ---------------------------------------------------------------------------------------------

# Import pipeline outputs
include: "definitions/outputs/pipeline_outputs.smk"

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
# For DAG generation
# ---------------------------------------------------------------------------------------------

# Define minimal pipeline outputs
rule called_variants:
    input:
        ex_variant_calling