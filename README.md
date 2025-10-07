<p align="center">
  <img src="https://leadingtechnology.com/2021/wp-content/uploads/2021/10/sysmed-logo.png" alt="Systematic Medicine" width="200"/>
</p>

# SomaticCODEC
#### A CODEC-based assay and open-source pipeline for quantifying somatic mutation burden in normal human tissue

`SomaticCODEC` is a rigorously validated bioinformatics assay optimized for detecting rare somatic mutations in normal human tissues — supporting applications in ageing, somatic mosaicism, and population genomics.
It leverages the CODEC sequencing protocol (with modifications from [Bae et al., 2023](https://doi.org/10.1038/s41588-023-01376-0)) and a new, modular, and test-driven bioinformatics pipeline.

### Key features

- **Tailored for somatic mutation detection in normal tissue**
- **Matched-sample design**: distinguishes somatic from germline variants using independent samples from the same individual
- **Open-source toolchain**: reproducible, portable, and cloud-ready (Docker + Snakemake)
- **Extensive assay validation**: >80 component-level and >10 system-level metrics
- **Automated QC reports**: detailed metrics, plots, and validation benchmarks
- **Robust software engineering**: unit tests, integration tests, config validators, CI support

### User guide

- **Pipeline Overview**
- **Library Preparation**
  - `SOP0017 CODECseq library preparation`
  - `SOP0029 CODECseq matched sample library preparation`
- **Compute Platform Setup**
  - [Setup EC2 guide](docs/ec2_setup.md)
- **Running the Pipeline**
  - Configuring parameters
  - Creating sample sheets
  - [Pipeline execution guide](docs/run_pipeline.md)
- **Interpreting Outputs**
  - Results and output structure
  - Metrics report
  - Metrics files and plots
- **Pipeline Validation**
  - Unit testing framework
  - Assay validation results

### Developer guide

* Versioning

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![CI: passing](https://img.shields.io/github/actions/workflow/status/systematicmedicine/SomaticCODEC/test.yml)