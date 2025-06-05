"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: ...
Output: ...

Author: ...

"""

# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])