# Assay Overview

SomaticCODEC is a sequencing assay for quantifying somatic mutation burden in normal human tissues.  
The assay consists of three stages: **library preparation**, **sequencing**, and a **bioinformatics pipeline**.

The bioinformatics pipeline analyses two sequencing libraries derived from the same biological sample:

- an **experimental (EX) sample**, prepared using the CODEC protocol and used for somatic variant calling
- a **matched (MS) sample**, prepared using a mostly standard PCR-free workflow and used to identify and mask germline variants

## Assay structure

```
Biological sample
        │
        ▼
 ┌──────────────────┐
 │   Library prep   │
 └──────────────────┘
        │
        ▼
 ┌─────────────┬─────────────┐
 │  EX library │  MS library │
 │  (CODEC)    │  (PCR-free) │
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

## Bioinformatics pipeline inputs

The SomaticCODEC bioinformatics pipeline requires the following inputs.

### Sequencing data

- **EX sample FASTQs** – experimental CODEC library used for somatic variant calling  
- **MS sample FASTQs** – matched library used to identify and mask germline variants

### Reference data

- Reference genome
- Reference trinucleotide contexts
- Known germline variant databases
- Precomputed genomic masks

## Pipeline outputs

The pipeline produces:

- A VCF of Somatic SNV calls for each experimental sample
- Component-level and system-level assay performance metrics
- QC reports and diagnostic plots