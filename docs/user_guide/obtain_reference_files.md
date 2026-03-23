# Obtain reference files

The pipeline requires the following reference files, defined in `config.yaml` -> `sci_params.shared`.

```
# ----------------------------------------------------------------------------
# Scientfic parameters shared across multiple rules, and reference files
# ----------------------------------------------------------------------------

shared:

# Default reference files can be downloaded from: https://sm-unrestricted-public.s3.ap-southeast-2.amazonaws.com/somaticcodec/reference-data/refs-v1/

  reference_genome: tmp/downloads/UCSC-GCRh38-p14-filtered.fa
  
  included_chromosomes: [
    "chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8", "chr9", "chr10",
    "chr11", "chr12", "chr13", "chr14", "chr15", "chr16", "chr17", "chr18", "chr19", 
    "chr20", "chr21", "chr22", "chrX", "chrY"
    ]  # Restricts analysis to canonical chromosomes

  precomputed_masks:
    - "tmp/downloads/GRCh38_alldifficultregions.bed"  # Masks genomic regions associated with elevated error rates
    - "tmp/downloads/gnomad_AF_0.1.bed"               # Marks genomic regions likely to contain common germline variants
    - "tmp/downloads/GCRh38_repeat_masker.bed"        # Masks highly repetitive, error-prone genomic regions
  
  reference_tri_contexts: tmp/downloads/2025-09-30_trinucleotide_contexts.csv  # Reference trinucleotide context frequencies
  reference_genome_trinuc_counts: tmp/downloads/UCSC-GCRh38-p14-filtered-trinucleotide-counts.csv  # Genome-wide trinucleotide counts for normalisation

  known_germline_variants: tmp/downloads/gnomad_AF_0.001.vcf.bgz  # Used to compute germline overlap metrics

# ----------------------------------------------------------------------------
# Scientific parameters for individual rules
# ----------------------------------------------------------------------------
```

The default reference files can be obtained from our public S3 bucket (see `config.yaml` for URL). However, you can generate your own versions to suit your use case.