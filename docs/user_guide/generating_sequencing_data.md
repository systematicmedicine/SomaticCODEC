# Generating sequencing data

### Overview

- For each biological that will be measured, prepare a single EX sample and a single MS sample
- The MS sample does not have to be derived from the same tissue, but must be derived from the same individual

### EX samples

- For library prep and sequencing, follow `Basic Protocol 1` from [Phie et al. 2026](doi)
- By default we reccomend 12 EX samples per 3B lane of a `NovaSeq X 25B` flow cell
- The bioinformatics pipeline assumes that the EX samples **are not demultiplexed before** running the pipeline.
- A pair of FASTQ files (R1/R2) containing reads from multiple undemultiplexed EX samples are refered to as an `ex_lane` 
- The individual EX samples that will be demultiplexed by the pipeline are refered to as an `ex_sample`

### MS samples

- For library prep and sequencing, follow `Basic Protocol 2` from [Phie et al. 2026](doi)
- By default we reccomend 6 MS samples per 3B lane of a `NovaSeq X 25B` flow cell
- The bioinformatics pipeline assumes that the MS samples **are demultiplexed before** running the pipline.
- A pair of FASTQ files (R1/R2) containing reads from a single MS sample are refered to as an `ms_sample`


