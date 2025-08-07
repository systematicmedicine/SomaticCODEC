"""
--- component_metrics_report.py ---

Generate a report of component level metric performance:
    - Only assesses metrics that can be assessed bioinformatically
    - Skips metrics if metrics files cannot be found
    - Component metrics are defined in component_metrics.xlsx
    - New component metrics can be added provided that 1. A JSON or txt metrics file exitst 2. The value can be extracted via a pattern

Author:
    - Cameron Fraser
"""


"""
Setup
"""
"""
# Load libraries
import pandas as pd

# Parameter injection from Snakemake
    #input_files = snakemake.input
    #output_files = snakemake.output
    #params = snakemake.params
    #wildcards = snakemake.wildcards
    #config = snakemake.config
    #log_file = snakemake.log[0] if snakemake.log else None

config = {"component_metrics_path", "config/component_metrics.csv"}

# Initiate logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting component_metrics_report.py")
"""


"""
Getter function for metrics contained in txt files
"""


"""
Getter function for metrics contained in JSON files
"""


"""
Getter function for metrics contained in JSON files
"""

"""
Create report
"""
"""
def create_report(config):
    
    # Load metrics metadata

# Filter for metrics to be included in report

# For each metric

    # Search for files

    # For file in files

        # Determine file extension

        # Lookup value for file

        # Append to component report


# Score metrics against targets 
if __name__ == "__main__":
    create_report(config)
    print("[INFO] Completed component_metrics_report.py")
"""
