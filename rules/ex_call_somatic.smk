"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: ...
Output: ...

Author: ...

Temporary working comments:
- Personalized fasta name:
- Duplex bam name: ex_hek1.1_map_dsc.bam


"""

# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])


# Personalized fasta name: 

# Duplex bam name: 