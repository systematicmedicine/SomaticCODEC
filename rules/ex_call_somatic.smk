"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: ...
Output: ...

Author: ...

Temporary working comments:

# Personalized vcf name:
tmp/ms_hek1.1/ms_hek1.1.vcf
tmp/ms_hek1.1/ms_hek1.1.vcf.idx

# Personalized fasta name:

# Duplex bam name: 
tmp/ex_hek1.1/ex_hek1.1_map_dsc_anno.bam
tmp/ex_hek1.1/ex_hek1.1_map_dsc_anno.bam.bai

"""

# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])

