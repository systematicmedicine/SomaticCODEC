"""
--- ex_create_dsc.smk ---

Rules for creating a double stranded consensus, for experimental samples

Input: Single stranded consessus
Output: Double stranded consensus

Author: James Phie

"""

# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])