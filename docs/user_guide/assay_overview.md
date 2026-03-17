# Assay Overview

SomaticCODEC is a sequencing assay for quantifying somatic SNVs in human DNA.

The assay consists of three stages:

1. **Library preparation**
2. **Sequencing**
3. **Bioinformatics pipeline**

SomaticCODEC utilises a matched-sample design. An `EX` (experimental) sample is used to call somatic variants, and an `MS` (matched) sample is used to identify germline variants and improve variant calling.

Alternative terminology used in the literature to describe similar designs includes *case/control* and *tumor/normal*.

```
          Human DNA
              │
              ▼
 ┌───────────────────────────┐
 │        Library prep       │
 └───────────────────────────┘
        │           │
        ▼           ▼
 ┌─────────────┬─────────────┐
 │  EX library │  MS library │
 └─────────────┴─────────────┘
        │           │
        ▼           ▼
     Sequencing   Sequencing
        │           │
        ▼           ▼
     EX FASTQ      MS FASTQ
        │           │
        └──────┬────┘
               ▼
        Bioinformatics
            pipeline
               │
               ▼
        Somatic SNV calls
```

## Library preparation

**Inputs**

- Human genomic DNA

**Outputs**

- EX DNA library (CODEC)
- MS DNA library (standard Illumina paired-end library)

## Sequencing

**Inputs**

- EX DNA library (CODEC)
- MS DNA library (standard Illumina paired-end library)

**Outputs**

- EX FASTQ files (not demultiplexed)
- MS FASTQ files (demultiplexed)

## Bioinformatics pipeline

**Inputs**

- EX FASTQ files (not demultiplexed)
- MS FASTQ files (demultiplexed)
- Reference files (e.g. reference genome, genome masks, reference germline variants)

**Outputs**

- VCF containing called somatic variants
- Multiple metrics files and QC reports