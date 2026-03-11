<p align="center">
  <img src="https://leadingtechnology.com/2021/wp-content/uploads/2021/10/sysmed-logo.png" alt="Systematic Medicine" width="200"/>
</p>

# SomaticCODEC
#### A CODEC-based assay and open-source pipeline for quantifying somatic mutation burden in normal human tissue

SomaticCODEC is a rigorously validated bioinformatics assay optimized for detecting rare somatic mutations in normal human tissues — supporting applications in ageing, mosaicism and preventative cancer research.
It leverages the CODEC sequencing protocol (with modifications from [Bae et al., 2023](https://doi.org/10.1038/s41588-023-01376-0)) and a new, modular, and test-driven bioinformatics pipeline.

### Key features

- **Tailored for somatic mutation detection in normal tissue**
- **Matched-sample design**: distinguishes somatic from germline variants using independent samples from the same individual
- **Open-source toolchain**: reproducible, portable, and cloud-ready (Docker + Snakemake)
- **Extensive assay validation**: >80 component-level and >10 system-level metrics
- **Automated QC reports**: detailed metrics, plots, and validation benchmarks
- **Robust software engineering**: unit tests, integration tests, config validators, CI support

### User guide

- **Assay Overview**
  
  SomaticCODEC utilises two distinct sample types per individual. Details on the preparation of these samples can be found in `Library preparation` below.

  - **Experimental (ex) samples**: Prepared with CODEC and used for somatic variant calling.
  - **Matched (ms) samples**: Prepared with a mostly standard PCR-free protocol, and used to create a germline variant mask for somatic variant calling.

- **Library Preparation**
  
  Phie *et al.* 2026 (doi: ) describes the preparation of experimental and matched samples for use with SomaticCODEC.

- **Running the Pipeline**

  Overview goes here.

  - [Setting up config.yaml]()

  - [Setting up sample metadata]()

  - [Setting up compute environment]()

  - [Example data]()

- **Interpreting Outputs**

  - System Metrics

  - Component Metrics

  - Other

- **Developer Guide**

  - Please report bugs using GitHub Issues (we do not monitor external pull requests).

### Maintainers

This repository is developed and maintained by [Systematic Medicine Pty Ltd](https://systematicmedicine.com), an Australian-based biotechnology company and wholly owned subsiduary of [Leading Technology Group](https://leadingtechnology.com).

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![CI: passing](https://img.shields.io/github/actions/workflow/status/systematicmedicine/SomaticCODEC/test.yml)
![Version](https://img.shields.io/github/v/tag/systematicmedicine/SomaticCODEC?label=version)
![Repo Size](https://img.shields.io/github/repo-size/systematicmedicine/SomaticCODEC)
![Last Commit](https://img.shields.io/github/last-commit/systematicmedicine/SomaticCODEC)