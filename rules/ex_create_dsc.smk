"""
--- ex_create_dsc.smk ---

Rules for creating a double stranded (duplex) consensus for experimental samples

Input: Single stranded consensus
Output: Double stranded consensus

Author: James Phie

"""

# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])