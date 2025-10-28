# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

Types of changes:
- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.

## [Unreleased]

### Changed

- Variant analyses now output to results/ dir instead of metrics/ dir (#240)
- Dependency made explicit for rules that depended on output lists, by importing definitions/pipeline_outputs.smk (#240)
- New definitions directory. Hard coded definitions (e.g. pipeline outputs) are defined here. Different from config that they are not user facing. (#239)
- Refactoring of rules file structure. Each smk file contains a single rule, and smk files are located in nested directory structure. (#239)
- Abstracted output definitions from top-level snakefile to rules/output_definitions (#238)
- Config check script checks that experiment name is not default value (#237)
- SNVs per diploid genome uses new value for normalisation, derived from T2T-CHM13 (#236)
- Somatic variant rate metrics changed from TXT to JSON format, descriptions added (#236)
- Increased number of rounding digits for gnomAD overlap rate metric (#235)
- Swapped umi_tools dedup for fgbio GroupReadsByUmi, and fgbio SortBam and SetMateInformation for samtools sort and fixmate (#233)
- SNV distance metrics computes additional percentiles (#231)
- bin/package_outputs.py now records checksums of all files it packages (#230)
- germline_contamination metric is now gnomAD_overlap, calculates rate of SNVs overlapping with gnomAD per evaluated base (#229)

### Removed

- Removed rule that checks ex-ms mappings. This is also checked by check_config.py script (#232)

### Fixed

- Uncommented ex_metrics in rule all of Snakefile (#234)

## [1.0.0] - 2025-10-23

### Added

- Initial release