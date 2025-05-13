# codec-opensource
An bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

- Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
- Tailored for detecting somatic mutations in normal tissue
- Incorporates independent samples to build personalized reference genomes
- Additional QC metrics (e.g. `fastqc`)
- Additional pipeline testing

## Installation



## Usage


## Folder structure
```
.
├── config
│
├── data
│   ├── bed                 # Bed files
│   ├── cand_germ_vcf       # Candidate germline mutations for matched samples
│   ├── cand_som_vcf        # Candidate somatic mutations called from experimental samples
│   ├── demux_fq_ex         # Demultiplexed FASTQ files for experimental samples
│   ├── demux_fq_ms         # Demultiplexed FASTQ files for matched samples
│   ├── dsc_ex              # Double strand consensuses for experimental samples
│   ├── filt_germ_vcf       # Filtered germline mutations for matched samples
│   ├── filt_som_vcf        # Filtered somatic mutations for experimental samples
│   ├── personal_refs       # Personalised reference genomes generated from matched samples
│   ├── pon                 # Pannel of normals
│   ├── proc_fq_ex          # Trimmed and filtered FASTQ files for experimental samples
│   ├── proc_fq_ms          # Trimmed and filtered FASTQ files for matched samples
│   ├── raw_bam_ex          # Raw alignments for experimental samples
│   ├── raw_bam_ms          # Raw alignments for matched samples
│   ├── raw_fq_ex           # Raw FASTQ files for experimental samples
│   └── ssc_ex              # Single strand conensuses for experimental samples
│
├── rules
│               
├── scripts
│
├── README.md
├── Snakefile

```