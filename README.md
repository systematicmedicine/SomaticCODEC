<p align="center">
  <img src="https://leadingtechnology.com/2021/wp-content/uploads/2021/10/sysmed-logo.png" alt="Systematic Medicine" width="200"/>
</p>

# SomaticCODEC
#### A CODEC-based assay and open-source pipeline for quantifying somatic mutation burden in normal human tissue

SomaticCODEC is a rigorously validated bioinformatics assay optimized for detecting rare somatic mutations in normal human tissues — supporting applications in ageing, mosaicism and preventative cancer research.
The assay leverages the CODEC sequencing protocol (with modifications from [Bae *et al*. 2023](https://doi.org/10.1038/s41588-023-01376-0)) and a new, modular, test-driven bioinformatics pipeline.

### Key features

- **Tailored for somatic mutation detection in normal tissue**
- **Matched-sample design**: Distinguishes somatic from germline variants using independent samples from the same individual
- **Open-source toolchain**: Reproducible, portable, and cloud-ready (Docker + Snakemake)
- **Extensive assay validation**: >80 component-level and >10 system-level metrics
- **Automated QC reports**: Detailed metrics, plots, and validation benchmarks
- **Robust software engineering**: Unit tests, integration tests, config validators, CI support

### User guide

- **Assay Overview**
  
  SomaticCODEC utilises two distinct sample types per individual. Details on the preparation of these samples can be found in `Library preparation` below.

  - **Experimental (ex) samples**: Prepared with CODEC, and used for somatic variant calling.
  - **Matched (ms) samples**: Prepared with a mostly standard PCR-free protocol, and used to create a germline risk mask for somatic variant calling.

  The pipeline workflow is managed by Snakemake. Briefly, the following steps are performed:

  - **Matched (ms) samples**:
    - Trimming and filtering
    - Alignment and annotation
    - Deduplication
    - Germline risk calling
    - Mask creation (germline risk and low depth masks)
    - Mask combination

  - **Experimental (ex) samples**:
    - Demultiplexing
    - Trimming and filtering
    - Initial alignment, filtering, and annotation
    - Duplex consensus calling
    - Realignment, filtering, and annotation
    - Somatic variant calling

- **Library Preparation**
  
  Phie *et al.* 2026 (doi: ) describes the preparation of experimental and matched samples for use with SomaticCODEC.

- **Running Pipeline**

  The below documents detail our `Recommended` approach for running the pipeline, as well as considerations if using a `Custom` approach.

  1. [Set up config.yaml](docs/setup/config_yaml_setup.md)

  2. [Set up metadata files](docs/setup/metadata_file_setup.md)

  3. [Set up compute environment](docs/setup/compute_setup.md)

  4. [Run pipeline](docs/run_pipeline.md)

  [Example methods and data]() (*link to public S3 bucket*)

- **Interpreting Outputs**

  The pipeline produces two metrics reports containing key metric values:

  - ***metrics/component_metrics_report.csv***

    Component-level metrics measure the performance of individual assay components. The description for each metric can be found in *config/component_level_metrics.xlsx*.

  - ***results/system_metrics_report.csv***

    System-level metrics measure the performance of the entire assay. The description for each metric can be found in *config/system_level_metrics.xlsx*.

  The thresholds for each component- and system-level metric have been set based on internal and external data. These thresholds should be used as a guide only.

  Many additional metrics files can be found in *metrics/* and *results/*, and the full records for called somatic variants can be found in *results/{ex_sample}/{ex_sample}_called_snvs.vcf*.

- **Developer Guide**

  - Please report bugs via GitHub Issues (external pull requests are not monitored).

### Maintainers

This repository is developed and maintained by [Systematic Medicine Pty Ltd](https://systematicmedicine.com), an Australian-based biotechnology company and wholly owned subsiduary of [Leading Technology Group](https://leadingtechnology.com).

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![CI: passing](https://img.shields.io/github/actions/workflow/status/systematicmedicine/SomaticCODEC/test.yml)
![Version](https://img.shields.io/github/v/tag/systematicmedicine/SomaticCODEC?label=version)
![Repo Size](https://img.shields.io/github/repo-size/systematicmedicine/SomaticCODEC)
![Last Commit](https://img.shields.io/github/last-commit/systematicmedicine/SomaticCODEC)