# Generating sequencing data

### Overview

- For each biological that will be measured, prepare a single EX sample and a single MS sample
- The type of MS sample will depend on the use case:
    - For primary human tissues, the ms sample must be from the same individual, but could be a different tissue
    - For cultured cells, an isogenic control may be more appropriate

### EX samples

- For library prep and sequencing, follow `Basic Protocol 1` from [Phie *et al*. 2026]()
- By default we recommend 12 EX samples per 3B lane of a `NovaSeq X 25B` flow cell
- The bioinformatics pipeline assumes that the EX samples **are not demultiplexed** before running the pipeline
- A pair of FASTQ files (R1/R2) containing reads from multiple non-demultiplexed EX samples are referred to as an `ex_lane` 
- The individual EX samples that will be demultiplexed by the pipeline are referred to as an `ex_sample`

### MS samples

- For library prep and sequencing, follow `Basic Protocol 2` from [Phie *et al*. 2026]()
- By default we recommend 6 MS samples per 3B lane of a `NovaSeq X 25B` flow cell
- The bioinformatics pipeline assumes that the MS samples **are demultiplexed** before running the pipeline.
- A pair of FASTQ files (R1/R2) containing reads from a single MS sample are referred to as an `ms_sample`


