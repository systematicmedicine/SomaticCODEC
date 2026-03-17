# Obtain reference files

The pipeline requires the following reference filse, define in `config.yaml`.

```
sci_params:
  
  shared:
    reference_genome: tmp/downloads/UCSC-GCRh38-p14-filtered.fa
    reference_tri_contexts: tmp/downloads/2025-09-30_trinucleotide_contexts.csv
    reference_genome_trinuc_counts: tmp/downloads/UCSC-GCRh38-p14-filtered-trinucleotide-counts.csv
    known_germline_variants: tmp/downloads/gnomad_AF_0.001.vcf.bgz # Must be bgzipped
    precomputed_masks:
      - "tmp/downloads/GRCh38_alldifficultregions.bed"
      - "tmp/downloads/gnomad_AF_0.1.bed"
      - "tmp/downloads/GCRh38_repeat_masker.bed"
```

You can generate these files yourself, or download them from Systematic Medicines public S3 bucket.