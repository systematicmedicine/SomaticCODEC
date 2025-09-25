# codec-opensource
A bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

* Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
* Tailored for calling somatic mutations in normal tissue
* Uses independent matched samples (from same individual) to differentiate true somatic variants from germline variants
* Extensive range of QC metrics generated (e.g. `fastqc`)
* Fully containerized docker workflow

## Library prep and sequencing
Prepare and sequence libraries as per: 

* `SOP0017 CODECseq library preparation`
* `SOP0029 CODECseq matched sample library preparation`

## Setup instructions
* [Amazon EC2](docs/setup_EC2.md)

## Running the pipeline
* [Running pipeline](docs/run_pipeline.md)
